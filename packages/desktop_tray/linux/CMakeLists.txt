cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "desktop_tray")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "desktop_tray_plugin")

find_package(PkgConfig REQUIRED)

add_library(${PLUGIN_NAME} SHARED
  "desktop_tray_plugin.cc"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

pkg_check_modules(APPINDICATOR IMPORTED_TARGET ayatana-appindicator3-0.1)
if(APPINDICATOR_FOUND)
  target_compile_definitions(${PLUGIN_NAME} PRIVATE HAVE_AYATANA)
else()
  pkg_check_modules(APPINDICATOR IMPORTED_TARGET appindicator3-0.1)
endif()
if(APPINDICATOR_FOUND)
  target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::APPINDICATOR)
else()
  message(
    FATAL_ERROR
    "\n"
    "The `desktop_tray` plugin requires ayatana-appindicator3-0.1 or "
    "appindicator3-0.1.\n"
    "  sudo apt install libayatana-appindicator3-dev\n"
  )
endif()

set(desktop_tray_bundled_libraries
  ""
  PARENT_SCOPE
)
