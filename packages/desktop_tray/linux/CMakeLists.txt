cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "desktop_tray")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "desktop_tray_plugin")

find_package(PkgConfig REQUIRED)

add_library(${PLUGIN_NAME} SHARED
  "desktop_tray_plugin.cc"
  "status_notifier_item.cc"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

pkg_check_modules(DBUSMENU REQUIRED IMPORTED_TARGET dbusmenu-gtk3-0.4)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::DBUSMENU)

set(desktop_tray_bundled_libraries
  ""
  PARENT_SCOPE
)
