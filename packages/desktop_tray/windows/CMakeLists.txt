cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "desktop_tray")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "desktop_tray_plugin")

add_library(${PLUGIN_NAME} SHARED
  "desktop_tray_plugin.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
# Suppress C4819 (code-page encoding) so /WX does not promote it to an error.
target_compile_options(${PLUGIN_NAME} PRIVATE /wd"4819")
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_compile_definitions(${PLUGIN_NAME} PRIVATE _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin gdiplus)

set(desktop_tray_bundled_libraries
  ""
  PARENT_SCOPE
)
