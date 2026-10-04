#include "flutter_window.h"

#include <optional>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  activation_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "tawaq/single_instance",
          &flutter::StandardMethodCodec::GetInstance());
  activation_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() == "activate") {
          ActivateMainWindow();
          result->Success();
        } else if (call.method_name() == "completeBootstrap") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          const bool* hidden = nullptr;
          if (args != nullptr) {
            auto it = args->find(flutter::EncodableValue("launchHidden"));
            if (it != args->end()) hidden = std::get_if<bool>(&it->second);
          }
          if (hidden == nullptr) {
            result->Error("INVALID_ARGUMENT", "launchHidden must be a bool");
            return;
          }
          if (!bootstrap_complete_) {
            bootstrap_complete_ = true;
            if (*hidden && !pending_activation_) {
              ShowWindow(GetHandle(), SW_HIDE);
            } else {
              ActivateMainWindow();
            }
            pending_activation_ = false;
          }
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  activation_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::ActivateMainWindow() {
  if (!bootstrap_complete_) pending_activation_ = true;
  HWND window = GetHandle();
  if (IsIconic(window)) {
    ShowWindow(window, SW_RESTORE);
  } else {
    ShowWindow(window, SW_SHOW);
  }
  SetWindowPos(window, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
  SetForegroundWindow(window);
  SetFocus(flutter_controller_->view()->GetNativeWindow());
}
