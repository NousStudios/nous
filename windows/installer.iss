; ═════════════════════════════════════════════════════════════════
; NOUS — SCRIPT DE INSTALAÇÃO WINDOWS (INNO SETUP 6)
; Software Universal de Autogestão Comercial e Social
; ═════════════════════════════════════════════════════════════════

#define MyAppName "Nous"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Nous Studios"
#define MyAppURL "https://github.com/NousStudios/nous"
#define MyAppExeName "nous.exe"

[Setup]
; Identificador único da aplicação (GUID gerado para o Nous)
AppId={{5B612C26-8EA0-4FA9-9B90-D09D5EF6F0A2}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
; Permite instalação tanto por usuário comum quanto por administrador
PrivilegesRequiredOverridesAllowed=commandline dialog
OutputDir=..\dist
OutputBaseFilename=Nous_Instalador_v{#MyAppVersion}
SetupIconFile=runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes

; Preservação de dados locais: o desinstalador NUNCA remove a pasta %APPDATA%\Nous
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Todos os binários, assets e bibliotecas gerados pelo flutter build windows --release
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autoprograms}\{#MyAppName}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
