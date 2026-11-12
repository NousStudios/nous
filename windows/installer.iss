; ═════════════════════════════════════════════════════════════════
; NOUS — SCRIPT DE INSTALAÇÃO WINDOWS (INNO SETUP 6)
; Software Universal de Autogestão Comercial e Social
; ═════════════════════════════════════════════════════════════════

#define MyAppName "Nous"
#ifndef MyAppVersion
#define MyAppVersion "1.1.8"
#endif
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
; Exige elevação de administrador para configurar permissões no Firewall do Windows
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=commandline dialog
OutputDir=..\dist
OutputBaseFilename=Nous_Instalador_v{#MyAppVersion}_Versao_Teste
SetupIconFile=runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
CloseApplications=yes

; Preservação de dados locais: o desinstalador NUNCA remove a pasta %APPDATA%\Nous
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Todos os binários, assets e bibliotecas gerados pelo flutter build windows --release
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; APK Android para distribuição soberana e local-first via Wi-Fi pelo Computador Balcão
Source: "..\dist\Nous_Android_v{#MyAppVersion}_Versao_Teste.apk"; DestDir: "{app}\dist"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{autoprograms}\{#MyAppName}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autoprograms}\{#MyAppName}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Regras automáticas no Windows Defender Firewall (libera servidor balcão e descoberta Wi-Fi)
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""Nous Servidor Balcao"" dir=in action=allow program=""{app}\{#MyAppExeName}"" enable=yes profile=any"; Flags: runhidden
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""Nous Porta Balcao 8080"" dir=in action=allow protocol=TCP localport=8080 enable=yes profile=any"; Flags: runhidden
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""Nous Descoberta UDP 45454"" dir=in action=allow protocol=UDP localport=45454 enable=yes profile=any"; Flags: runhidden
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""Nous Servidor Balcao"""; Flags: runhidden
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""Nous Porta Balcao 8080"""; Flags: runhidden
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""Nous Descoberta UDP 45454"""; Flags: runhidden
