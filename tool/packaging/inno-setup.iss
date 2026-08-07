; Tawaq Windows Installer (Inno Setup)

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef BuildNumber
  #define BuildNumber "0"
#endif

[Setup]
AppId={{D92953B8-0BD0-483B-8EEC-7B2444FD0BE8}
AppName=Tawaq
AppVersion={#AppVersion}
AppVerName=Tawaq {#AppVersion}
AppPublisher=Moath
DefaultDirName={autopf}\Tawaq
DefaultGroupName=Tawaq
OutputDir=..\..\dist
OutputBaseFilename=tawaq-{#AppVersion}-windows-x64-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\tawaq.exe
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Tawaq"; Filename: "{app}\tawaq.exe"
Name: "{group}\{cm:UninstallProgram,Tawaq}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Tawaq"; Filename: "{app}\tawaq.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\tawaq.exe"; Description: "Launch Tawaq"; Flags: nowait postinstall skipifsilent
