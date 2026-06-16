// ---------------------------------------------------------------------------
// desktop_tray – Windows native implementation
//
// Uses Shell_NotifyIcon / NOTIFYICONDATA for the tray icon and Win32
// HMENU for the context menu.
// ---------------------------------------------------------------------------

#include "include/desktop_tray/desktop_tray_plugin.h"

#include <windows.h>
#include <shellapi.h>
#include <stdio.h>
#include <strsafe.h>

// GDI+ is used to decode .png / .jpg / .bmp / .gif icons. The Windows
// LoadImage() API only understands raw .ico files, which was the root cause of
// "the tray button is there but no icon is shown" for non-.ico assets.
#include <objidl.h>
#include <gdiplus.h>
#pragma comment(lib, "gdiplus.lib")

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cwctype>
#include <codecvt>
#include <memory>
#include <string>

#define WM_DESKTOP_TRAY (WM_USER + 100)

namespace {

// Process-wide GDI+ token. We start it once in the plugin constructor and
// shut it down in the destructor.
ULONG_PTR g_gdiplus_token = 0;
int g_gdiplus_refcount = 0;

void EnsureGdiplusStarted() {
  if (g_gdiplus_refcount++ == 0) {
    Gdiplus::GdiplusStartupInput input;
    Gdiplus::GdiplusStartup(&g_gdiplus_token, &input, nullptr);
  }
}

void MaybeShutdownGdiplus() {
  if (--g_gdiplus_refcount <= 0 && g_gdiplus_token != 0) {
    Gdiplus::GdiplusShutdown(g_gdiplus_token);
    g_gdiplus_token = 0;
    g_gdiplus_refcount = 0;
  }
}

// Return lowercase extension (without the dot) of a wide path, e.g. L"png".
std::wstring LowerExtension(const std::wstring &path) {
  auto dot = path.find_last_of(L'.');
  if (dot == std::wstring::npos) return L"";
  std::wstring ext = path.substr(dot + 1);
  std::transform(ext.begin(), ext.end(), ext.begin(),
                 [](wchar_t c) { return static_cast<wchar_t>(std::towlower(c)); });
  return ext;
}

// Decode any image format supported by GDI+ and return an HICON sized to the
// system small-icon dimensions. Caller owns the returned HICON (DestroyIcon).
// Returns nullptr on failure.
HICON LoadHIconFromImage(const std::wstring &path, int cx, int cy) {
  Gdiplus::Bitmap src(path.c_str());
  if (src.GetLastStatus() != Gdiplus::Ok) {
    return nullptr;
  }

  // Resize to the requested tray icon size with high-quality scaling.
  Gdiplus::Bitmap dst(cx, cy, PixelFormat32bppARGB);
  {
    Gdiplus::Graphics g(&dst);
    g.SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);
    g.SetSmoothingMode(Gdiplus::SmoothingModeHighQuality);
    g.SetPixelOffsetMode(Gdiplus::PixelOffsetModeHighQuality);
    g.DrawImage(&src, 0, 0, cx, cy);
  }

  HICON hIcon = nullptr;
  if (dst.GetHICON(&hIcon) != Gdiplus::Ok) {
    return nullptr;
  }
  return hIcon;
}

// Unified loader: delegates to LoadImage for .ico, otherwise GDI+.
HICON LoadTrayIcon(const std::wstring &path) {
  const int cx = GetSystemMetrics(SM_CXSMICON);
  const int cy = GetSystemMetrics(SM_CYSMICON);

  if (LowerExtension(path) == L"ico") {
    return static_cast<HICON>(
        LoadImage(nullptr, path.c_str(), IMAGE_ICON, cx, cy, LR_LOADFROMFILE));
  }
  return LoadHIconFromImage(path, cx, cy);
}

const flutter::EncodableValue *ValueOrNull(const flutter::EncodableMap &map,
                                           const char *key) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end())
    return nullptr;
  return &(it->second);
}

// Shared channel (set once during registration).
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_channel;

class DesktopTrayPlugin : public flutter::Plugin {
public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  explicit DesktopTrayPlugin(flutter::PluginRegistrarWindows *registrar);
  ~DesktopTrayPlugin() override;

private:
  flutter::PluginRegistrarWindows *registrar_;
  NOTIFYICONDATA nid_{};
  NOTIFYICONIDENTIFIER niif_{};
  HMENU hMenu_ = CreatePopupMenu();
  bool icon_set_ = false;
  int window_proc_id_ = -1;
  UINT taskbar_created_msg_ = 0;

  std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter_;

  HWND GetMainWindow();
  void ApplyIcon();
  void BuildMenu(HMENU menu, const flutter::EncodableMap &args);

  std::optional<LRESULT> HandleWindowProc(HWND hwnd, UINT message,
                                          WPARAM wparam, LPARAM lparam);

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void Destroy(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void SetIcon(
      const flutter::EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void SetToolTip(
      const flutter::EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void SetContextMenu(
      const flutter::EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void PopUpContextMenu(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

// Guard against double registration in multi-window scenarios.
static bool g_registered = false;

void DesktopTrayPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  if (g_registered)
    return;
  g_registered = true;

  g_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "desktop_tray",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<DesktopTrayPlugin>(registrar);

  g_channel->SetMethodCallHandler(
      [p = plugin.get()](const auto &call, auto result) {
        p->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

DesktopTrayPlugin::DesktopTrayPlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar) {
  EnsureGdiplusStarted();
  window_proc_id_ = registrar->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
        return HandleWindowProc(hwnd, msg, wp, lp);
      });
  taskbar_created_msg_ = RegisterWindowMessage(L"TaskbarCreated");
}

DesktopTrayPlugin::~DesktopTrayPlugin() {
  registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_id_);
  if (icon_set_) {
    Shell_NotifyIcon(NIM_DELETE, &nid_);
    if (nid_.hIcon)
      DestroyIcon(nid_.hIcon);
  }
  if (hMenu_)
    DestroyMenu(hMenu_);
  MaybeShutdownGdiplus();
}

HWND DesktopTrayPlugin::GetMainWindow() {
  return ::GetAncestor(registrar_->GetView()->GetNativeWindow(), GA_ROOT);
}

void DesktopTrayPlugin::ApplyIcon() {
  // Never register a placeholder tray slot without a real icon — that was the
  // historical root cause of "an invisible clickable area with no graphic".
  if (nid_.hIcon == nullptr) {
    return;
  }

  if (icon_set_) {
    Shell_NotifyIcon(NIM_MODIFY, &nid_);
  } else {
    HICON hIconBackup = nid_.hIcon;
    WCHAR szTipBackup[128];
    StringCchCopy(szTipBackup, _countof(szTipBackup), nid_.szTip);

    ZeroMemory(&nid_, sizeof(NOTIFYICONDATA));
    nid_.cbSize = sizeof(NOTIFYICONDATA);
    nid_.hWnd = GetMainWindow();
    nid_.uID = 1;
    nid_.hIcon = hIconBackup;
    StringCchCopy(nid_.szTip, _countof(nid_.szTip), szTipBackup);
    nid_.uCallbackMessage = WM_DESKTOP_TRAY;
    nid_.uFlags = NIF_MESSAGE | NIF_ICON;
    if (nid_.szTip[0] != L'\0') {
      nid_.uFlags |= NIF_TIP;
    }
    Shell_NotifyIcon(NIM_ADD, &nid_);
  }

  niif_.cbSize = sizeof(NOTIFYICONIDENTIFIER);
  niif_.hWnd = nid_.hWnd;
  niif_.uID = nid_.uID;
  niif_.guidItem = GUID_NULL;

  icon_set_ = true;
}

void DesktopTrayPlugin::BuildMenu(HMENU menu,
                                  const flutter::EncodableMap &args) {
  auto items = std::get<flutter::EncodableList>(
      args.at(flutter::EncodableValue("items")));

  // Clear existing items.
  int count = GetMenuItemCount(menu);
  for (int i = 0; i < count; i++) {
    RemoveMenu(menu, 0, MF_BYPOSITION);
  }

  for (const auto &item_value : items) {
    auto item_map = std::get<flutter::EncodableMap>(item_value);
    int id = std::get<int>(item_map.at(flutter::EncodableValue("id")));
    auto type =
        std::get<std::string>(item_map.at(flutter::EncodableValue("type")));
    auto label =
        std::get<std::string>(item_map.at(flutter::EncodableValue("label")));
    bool disabled =
        std::get<bool>(item_map.at(flutter::EncodableValue("disabled")));
    auto *checked = std::get_if<bool>(ValueOrNull(item_map, "checked"));

    UINT_PTR item_id = id;
    UINT uFlags = MF_STRING;

    if (disabled)
      uFlags |= MF_GRAYED;

    if (type == "separator") {
      AppendMenuW(menu, MF_SEPARATOR, item_id, NULL);
    } else {
      if (type == "checkbox") {
        if (checked != nullptr) {
          uFlags |= (*checked ? MF_CHECKED : MF_UNCHECKED);
        }
      } else if (type == "submenu") {
        uFlags |= MF_POPUP;
        HMENU sub_menu = ::CreatePopupMenu();
        BuildMenu(sub_menu, std::get<flutter::EncodableMap>(item_map.at(
                                flutter::EncodableValue("submenu"))));
        item_id = reinterpret_cast<UINT_PTR>(sub_menu);
      }
      AppendMenuW(menu, uFlags, item_id, converter_.from_bytes(label).c_str());
    }
  }
}

std::optional<LRESULT> DesktopTrayPlugin::HandleWindowProc(HWND hWnd,
                                                           UINT message,
                                                           WPARAM wParam,
                                                           LPARAM lParam) {
  if (message == WM_DESTROY) {
    if (icon_set_) {
      Shell_NotifyIcon(NIM_DELETE, &nid_);
      if (nid_.hIcon)
        DestroyIcon(nid_.hIcon);
      icon_set_ = false;
    }
  } else if (message == WM_COMMAND) {
    flutter::EncodableMap data;
    data[flutter::EncodableValue("id")] =
        flutter::EncodableValue(static_cast<int>(wParam));
    g_channel->InvokeMethod("onTrayMenuItemClick",
                            std::make_unique<flutter::EncodableValue>(data));
  } else if (message == WM_DESKTOP_TRAY) {
    switch (lParam) {
    case WM_LBUTTONDOWN:
      g_channel->InvokeMethod("onTrayIconMouseDown",
                              std::make_unique<flutter::EncodableValue>());
      break;
    case WM_LBUTTONUP:
      g_channel->InvokeMethod("onTrayIconMouseUp",
                              std::make_unique<flutter::EncodableValue>());
      break;
    case WM_RBUTTONDOWN:
      g_channel->InvokeMethod("onTrayIconRightMouseDown",
                              std::make_unique<flutter::EncodableValue>());
      break;
    case WM_RBUTTONUP:
      g_channel->InvokeMethod("onTrayIconRightMouseUp",
                              std::make_unique<flutter::EncodableValue>());
      break;
    default:
      return DefWindowProc(hWnd, message, wParam, lParam);
    }
  } else if (message == taskbar_created_msg_) {
    if (taskbar_created_msg_ != 0 && icon_set_) {
      icon_set_ = false;
      ApplyIcon();
    }
  } else if (message == WM_POWERBROADCAST) {
    if ((wParam == PBT_APMRESUMEAUTOMATIC || wParam == PBT_APMRESUMESUSPEND) &&
        icon_set_) {
      icon_set_ = false;
      ApplyIcon();
    }
  }
  return std::nullopt;
}

// ---- Method handlers -------------------------------------------------------

void DesktopTrayPlugin::Destroy(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (icon_set_) {
    Shell_NotifyIcon(NIM_DELETE, &nid_);
    if (nid_.hIcon) {
      DestroyIcon(nid_.hIcon);
      nid_.hIcon = nullptr;
    }
    icon_set_ = false;
  }
  result->Success(flutter::EncodableValue(true));
}

void DesktopTrayPlugin::SetIcon(
    const flutter::EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  auto iconPath =
      std::get<std::string>(args.at(flutter::EncodableValue("iconPath")));

  std::wstring wpath = converter_.from_bytes(iconPath);
  HICON hNew = LoadTrayIcon(wpath);
  if (hNew == nullptr) {
    result->Error("ICON_LOAD_FAILED",
                  "Failed to load tray icon from: " + iconPath);
    return;
  }

  if (nid_.hIcon != nullptr) {
    DestroyIcon(nid_.hIcon);
  }
  nid_.hIcon = hNew;

  ApplyIcon();
  result->Success(flutter::EncodableValue(true));
}

void DesktopTrayPlugin::SetToolTip(
    const flutter::EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  auto toolTip =
      std::get<std::string>(args.at(flutter::EncodableValue("toolTip")));

  nid_.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
  StringCchCopy(nid_.szTip, _countof(nid_.szTip),
                converter_.from_bytes(toolTip).c_str());
  Shell_NotifyIcon(NIM_MODIFY, &nid_);

  result->Success(flutter::EncodableValue(true));
}

void DesktopTrayPlugin::SetContextMenu(
    const flutter::EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  BuildMenu(hMenu_, std::get<flutter::EncodableMap>(
                        args.at(flutter::EncodableValue("menu"))));
  result->Success(flutter::EncodableValue(true));
}

void DesktopTrayPlugin::PopUpContextMenu(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  HWND hWnd = GetMainWindow();
  POINT cursorPos;
  GetCursorPos(&cursorPos);
  SetForegroundWindow(hWnd);
  TrackPopupMenu(hMenu_, TPM_BOTTOMALIGN | TPM_LEFTALIGN, cursorPos.x,
                 cursorPos.y, 0, hWnd, NULL);
  result->Success(flutter::EncodableValue(true));
}

void DesktopTrayPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto &method = call.method_name();

  if (method == "destroy") {
    Destroy(std::move(result));
  } else if (method == "setIcon") {
    SetIcon(std::get<flutter::EncodableMap>(*call.arguments()),
            std::move(result));
  } else if (method == "setToolTip") {
    SetToolTip(std::get<flutter::EncodableMap>(*call.arguments()),
               std::move(result));
  } else if (method == "setContextMenu") {
    SetContextMenu(std::get<flutter::EncodableMap>(*call.arguments()),
                   std::move(result));
  } else if (method == "popUpContextMenu") {
    PopUpContextMenu(std::move(result));
  } else {
    result->NotImplemented();
  }
}

} // namespace

void DesktopTrayPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  DesktopTrayPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
