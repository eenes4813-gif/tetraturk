[Setup]
AppName=TetraTurk
AppVersion=1.0.0
DefaultDirName={localappdata}\TetraTurk
DefaultGroupName=TetraTurk
PrivilegesRequired=lowest
OutputDir=output
OutputBaseFilename=TetraTurk_Kurulum
Compression=lzma2
SolidCompression=yes
[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
[Icons]
Name: "{autoprograms}\TetraTurk"; Filename: "{app}\tetraturk.exe"
Name: "{autodesktop}\TetraTurk"; Filename: "{app}\tetraturk.exe"
[Run]
Filename: "{app}\tetraturk.exe"; Description: "TetraTurk'u başlat"; Flags: postinstall nowait skipifsilent
