; Inno Setup script for the Sayaw Windows installer.
;
; Built by .github/workflows/release-windows.yml on a tag. AppVersion is passed
; in from the workflow so the tag is the single source of truth and nothing
; here has to be kept in step by hand.
;
; Not signed. Windows SmartScreen will warn on first run until it is, and the
; person downloading it has to click through "More info" to proceed — see the
; note in the README.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

#define AppName "Sayaw"
#define AppPublisher "Sayaw"
#define AppExeName "sayaw.exe"

[Setup]
; A stable GUID: Windows uses it to recognise an upgrade rather than treating
; every release as a second copy of the app.
AppId={{7C4A8D9B-3E21-4F6A-9C5D-2B8E1F0A6D34}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppSupportURL=https://github.com/yvesanana-sys/Sayaw
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
OutputBaseFilename=Sayaw-{#AppVersion}-windows-x64-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; Per-user by default, so no administrator prompt for a DJ installing on their
; own laptop. `{autopf}` follows this to the right Program Files.
PrivilegesRequiredOverridesAllowed=dialog
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Refuse to install over a running copy rather than leaving half-replaced DLLs
; behind, which for a media app means a deck that loads and will not play.
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
; The whole Flutter bundle: the exe, the Flutter DLL, and the `data` folder
; holding the assets and the ICU data. libmpv and sqlite3 are in here too —
; the decks are built on them, and neither is present on a stock Windows.
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Start {#AppName}"; Flags: nowait postinstall skipifsilent
