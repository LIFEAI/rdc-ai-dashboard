; ============================================================
;  RDC Dashboard — Inno Setup Script
;  Produces: dist\RDC_Dashboard_Setup.exe
;  Requires: Inno Setup 6+ (https://jrsoftware.org/isinfo.php)
; ============================================================

#define AppName      "RDC Dashboard"
#define AppVersion   "1.0.0"
#define AppPublisher "Regenerative Development Corp"
#define AppURL       "https://regendevcorp.com"
#define AppExeName   "RDC_Dashboard.exe"

[Setup]
AppId={{F3A2C8E1-4D9B-4F7A-B3C2-8E5D1A9F0B4C}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
; Output
OutputDir=..\dist
OutputBaseFilename=RDC_Dashboard_Setup_v{#AppVersion}
; Compression
Compression=lzma2/ultra64
SolidCompression=yes
; Appearance
WizardStyle=modern
WizardResizable=yes
DisableWelcomePage=no
; Privileges
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
; Uninstall
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon";   Description: "Create a &desktop shortcut";       GroupDescription: "Additional icons:"; Flags: unchecked
Name: "startuptray";   Description: "Start in &system tray on login";    GroupDescription: "Startup:"; Flags: unchecked

[Files]
; Main executable (built by PyInstaller)
Source: "..\dist\RDC_Dashboard.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Start Menu
Name: "{group}\{#AppName}";          Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
; Desktop (optional task)
Name: "{autodesktop}\{#AppName}";    Filename: "{app}\{#AppExeName}"; Tasks: desktopicon
; Startup tray (optional task)
Name: "{userstartup}\{#AppName} (Tray)"; Filename: "{app}\{#AppExeName}"; Parameters: "--tray"; Tasks: startuptray

[Run]
; Offer to launch after install
Filename: "{app}\{#AppExeName}"; \
  Description: "Launch {#AppName} now"; \
  Flags: nowait postinstall skipifsilent

[UninstallRun]
; Kill the process before uninstalling
Filename: "taskkill.exe"; Parameters: "/f /im {#AppExeName}"; Flags: runhidden skipifdoesntexist

[Code]
// Kill any running instance before upgrade
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
    Exec('taskkill.exe', '/f /im {#AppExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;
