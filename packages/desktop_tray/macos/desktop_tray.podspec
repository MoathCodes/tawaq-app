#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'desktop_tray'
  s.version          = '1.0.0'
  s.summary          = 'Flutter desktop system-tray plugin.'
  s.description      = <<-DESC
  Cross-platform system-tray icon and context-menu for Flutter desktop apps.
                       DESC
  s.homepage         = 'https://github.com/example/desktop_tray'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Kurban' => 'dev@kurban.im' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end

