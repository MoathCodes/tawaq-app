//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <desktop_tray/desktop_tray_plugin.h>
#include <flutter_alone/flutter_alone_plugin_c_api.h>
#include <flutter_timezone/flutter_timezone_plugin_c_api.h>
#include <geolocator_windows/geolocator_windows.h>
#include <local_notifier/local_notifier_plugin.h>
#include <mpv_audio_kit/mpv_audio_kit_plugin_c_api.h>
#include <pasteboard/pasteboard_plugin.h>
#include <screen_retriever_windows/screen_retriever_windows_plugin_c_api.h>
#include <window_manager/window_manager_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  DesktopTrayPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DesktopTrayPlugin"));
  FlutterAlonePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterAlonePluginCApi"));
  FlutterTimezonePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterTimezonePluginCApi"));
  GeolocatorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("GeolocatorWindows"));
  LocalNotifierPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("LocalNotifierPlugin"));
  MpvAudioKitPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("MpvAudioKitPluginCApi"));
  PasteboardPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PasteboardPlugin"));
  ScreenRetrieverWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ScreenRetrieverWindowsPluginCApi"));
  WindowManagerPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowManagerPlugin"));
}
