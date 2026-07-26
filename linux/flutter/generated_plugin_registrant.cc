//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <desktop_tray/desktop_tray_plugin.h>
#include <flutter_alone/flutter_alone_plugin.h>
#include <flutter_timezone/flutter_timezone_plugin.h>
#include <local_notifier/local_notifier_plugin.h>
#include <mpv_audio_kit/mpv_audio_kit_plugin.h>
#include <pasteboard/pasteboard_plugin.h>
#include <screen_retriever_linux/screen_retriever_linux_plugin.h>
#include <window_manager/window_manager_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) desktop_tray_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DesktopTrayPlugin");
  desktop_tray_plugin_register_with_registrar(desktop_tray_registrar);
  g_autoptr(FlPluginRegistrar) flutter_alone_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterAlonePlugin");
  flutter_alone_plugin_register_with_registrar(flutter_alone_registrar);
  g_autoptr(FlPluginRegistrar) flutter_timezone_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterTimezonePlugin");
  flutter_timezone_plugin_register_with_registrar(flutter_timezone_registrar);
  g_autoptr(FlPluginRegistrar) local_notifier_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "LocalNotifierPlugin");
  local_notifier_plugin_register_with_registrar(local_notifier_registrar);
  g_autoptr(FlPluginRegistrar) mpv_audio_kit_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MpvAudioKitPlugin");
  mpv_audio_kit_plugin_register_with_registrar(mpv_audio_kit_registrar);
  g_autoptr(FlPluginRegistrar) pasteboard_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "PasteboardPlugin");
  pasteboard_plugin_register_with_registrar(pasteboard_registrar);
  g_autoptr(FlPluginRegistrar) screen_retriever_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ScreenRetrieverLinuxPlugin");
  screen_retriever_linux_plugin_register_with_registrar(screen_retriever_linux_registrar);
  g_autoptr(FlPluginRegistrar) window_manager_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WindowManagerPlugin");
  window_manager_plugin_register_with_registrar(window_manager_registrar);
}
