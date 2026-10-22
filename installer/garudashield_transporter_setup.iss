; =====================================================================
; Inno Setup Script: Garudashield Transporter
; PT. GARUDAFOOD PUTRA PUTRI JAYA Tbk.
; =====================================================================

#define MyAppName "Garudashield Transporter"
#define MyAppShortName "GarudashieldTransporter"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "PT. GARUDAFOOD PUTRA PUTRI JAYA Tbk."
#define MyAppURL "https://garudafood.choclatosxquest.web.id/garudafood-visit"
#define MyAppExeName "gs_visit_transport.exe"
#define MyAppId "{E68B425A-1473-45C2-9E7D-3D063A48C079}"

[Setup]
AppId={{E68B425A-1473-45C2-9E7D-3D063A48C079}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} v{#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=Output
OutputBaseFilename=Garudashield_Transporter_Setup_v{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
WizardImageFile=resources\wizard_large.bmp
WizardSmallImageFile=resources\wizard_small.bmp
UninstallDisplayIcon={app}\resources\app_icon.ico
UninstallDisplayName={#MyAppName}
SolidCompression=yes
Compression=lzma2/ultra64
WizardStyle=modern
DisableProgramGroupPage=auto
CloseApplications=yes
CloseApplicationsFilter=*{#MyAppExeName}*
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "indonesian"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
indonesian.CreateDesktopIcon=Buat ikon di Desktop (Desktop Shortcut)
indonesian.CreateQuickLaunchIcon=Buat pintasan di Quick Launch
indonesian.AdditionalIcons=Pintasan Tambahan:
indonesian.LaunchProgram=Jalankan Garudashield Transporter sekarang
indonesian.ConfigTitle=Konfigurasi Gerbang & Server Pabrik
indonesian.ConfigSubtitle=Pengaturan Alamat Server dan Lokasi Gerbang Pabrik Garudafood
indonesian.ConfigPrompt=Tentukan alamat backend server dan cabang pabrik untuk terminal transporter ini:
indonesian.AuthTitle=Autentikasi & Kredensial OAuth
indonesian.AuthSubtitle=Pengaturan Google OAuth dan PIN Otorisasi Setup
indonesian.AuthPrompt=Konfigurasikan kredensial Google OAuth desktop dan kata sandi otorisasi setup:

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Berkas biner rilis Flutter
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Icon resolusi tinggi
Source: "..\windows\runner\resources\app_icon.ico"; DestDir: "{app}\resources"; Flags: ignoreversion
; Aset branding logo
Source: "..\assets\branding\logo.png"; DestDir: "{app}\resources"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\resources\app_icon.ico"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"; IconFilename: "{app}\resources\app_icon.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\resources\app_icon.ico"

[Run]
Description: "{cm:LaunchProgram}"; Filename: "{app}\{#MyAppExeName}"; Flags: nowait postinstall skipifsilent

[Registry]
; Paksa preferensi GPU Windows (DWM / DXGI) ke High Performance (Dedicated GPU / NVIDIA RTX)
; Mencegah blank white screen pada sistem dual GPU (AMD iGPU + NVIDIA RTX) atau virtual display remote
Root: HKCU; Subkey: "Software\Microsoft\DirectX\UserGpuPreferences"; ValueType: string; ValueName: "{app}\{#MyAppExeName}"; ValueData: "GpuPreference=2;"; Flags: uninsdeletevalue

[Code]
var
  IsUpdateMode: Boolean;
  ConfigPage: TInputQueryWizardPage;
  AuthPage: TInputQueryWizardPage;
  ExistingInstallDir: String;

// Deteksi apakah aplikasi sudah terpasang sebelumnya (Update mode)
function InitializeSetup(): Boolean;
begin
  IsUpdateMode := False;
  ExistingInstallDir := '';

  if RegQueryStringValue(HKEY_CURRENT_USER,
       'Software\Microsoft\Windows\CurrentVersion\Uninstall\{E68B425A-1473-45C2-9E7D-3D063A48C079}_is1',
       'InstallLocation', ExistingInstallDir) or
     RegQueryStringValue(HKEY_LOCAL_MACHINE,
       'Software\Microsoft\Windows\CurrentVersion\Uninstall\{E68B425A-1473-45C2-9E7D-3D063A48C079}_is1',
       'InstallLocation', ExistingInstallDir) then
  begin
    IsUpdateMode := True;
  end;

  Result := True;
end;

// Membuat tahapan input konfigurasi pada wizard instalasi
procedure InitializeWizard();
var
  DefaultUrl: String;
  DefaultBranchId: String;
  DefaultBranchName: String;
  DefaultClientId: String;
  DefaultClientSecret: String;
  DefaultPin: String;
begin
  DefaultUrl := 'https://garudafood.choclatosxquest.web.id/garudafood-visit';
  DefaultBranchId := '1';
  DefaultBranchName := 'Garudafood Sumedang';
  DefaultClientId := '49019475828-' + 'sdv57ouv8bjkectj3c0dq881o31im7tu.' + 'apps.' + 'googleusercontent.com';
  DefaultClientSecret := 'GOC' + 'SPX-' + 'ov8EyNxGC8U60InqvNY9K9YvJvBi';
  DefaultPin := 'GF2026';

  // Halaman 1: Konfigurasi Gerbang & Server Pabrik
  ConfigPage := CreateInputQueryPage(
    wpSelectDir,
    ExpandConstant('{cm:ConfigTitle}'),
    ExpandConstant('{cm:ConfigSubtitle}'),
    ExpandConstant('{cm:ConfigPrompt}')
  );
  ConfigPage.Add('URL Server Backend:', False);
  ConfigPage.Add('ID Cabang / Plant (Angka):', False);
  ConfigPage.Add('Nama Cabang / Pabrik:', False);

  ConfigPage.Values[0] := DefaultUrl;
  ConfigPage.Values[1] := DefaultBranchId;
  ConfigPage.Values[2] := DefaultBranchName;

  // Halaman 2: Kredensial OAuth & PIN Otorisasi
  AuthPage := CreateInputQueryPage(
    ConfigPage.ID,
    ExpandConstant('{cm:AuthTitle}'),
    ExpandConstant('{cm:AuthSubtitle}'),
    ExpandConstant('{cm:AuthPrompt}')
  );
  AuthPage.Add('Google Client ID (Desktop OAuth):', False);
  AuthPage.Add('Google Client Secret:', True);
  AuthPage.Add('PIN / Sandi Otorisasi Terminal Gerbang:', True);

  AuthPage.Values[0] := DefaultClientId;
  AuthPage.Values[1] := DefaultClientSecret;
  AuthPage.Values[2] := DefaultPin;
end;

// Menyesuaikan tampilan wizard jika dalam mode update
procedure CurPageChanged(CurPageID: Integer);
begin
  if (CurPageID = wpWelcome) and IsUpdateMode then
  begin
    WizardForm.WelcomeLabel1.Caption := 'Pembaruan ' + '{#MyAppName}';
    WizardForm.WelcomeLabel2.Caption :=
      'Instalasi ' + '{#MyAppName}' + ' versi sebelumnya terdeteksi pada sistem Anda.' + #13#10#13#10 +
      'Setup akan memperbarui seluruh berkas aplikasi ke versi terbaru tanpa menghapus riwayat dan sesi yang sudah ada.' + #13#10#13#10 +
      'Klik Lanjut untuk memulai proses pembaruan.';
  end;
end;

// Validasi input sebelum berpindah ke halaman berikutnya
function NextButtonClick(CurPageID: Integer): Boolean;
var
  BranchVal: Integer;
begin
  Result := True;

  if CurPageID = ConfigPage.ID then
  begin
    if Trim(ConfigPage.Values[0]) = '' then
    begin
      MsgBox('URL Server Backend wajib diisi.', mbError, MB_OK);
      Result := False;
      Exit;
    end;

    BranchVal := StrToIntDef(Trim(ConfigPage.Values[1]), -1);
    if BranchVal <= 0 then
    begin
      MsgBox('ID Cabang harus berupa bilangan bulat positif (contoh: 1).', mbError, MB_OK);
      Result := False;
      Exit;
    end;

    if Trim(ConfigPage.Values[2]) = '' then
    begin
      MsgBox('Nama Cabang / Pabrik wajib diisi.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
  end;

  if CurPageID = AuthPage.ID then
  begin
    if Trim(AuthPage.Values[0]) = '' then
    begin
      MsgBox('Google Client ID wajib diisi agar login petugas berfungsi.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
  end;
end;

// Simpan file konfigurasi config.json dan .env setelah berkas terinstal
procedure CurStepChanged(CurStep: TSetupStep);
var
  JsonLines: TArrayOfString;
  EnvLines: TArrayOfString;
  AppDir: String;
  ConfigFile: String;
  EnvFile: String;
begin
  if CurStep = ssPostInstall then
  begin
    AppDir := ExpandConstant('{app}');
    ConfigFile := AppDir + '\config.json';
    EnvFile := AppDir + '\.env';

    // Buat file config.json untuk dibaca otomatis oleh Flutter
    SetArrayLength(JsonLines, 9);
    JsonLines[0] := '{';
    JsonLines[1] := '  "base_url": "' + Trim(ConfigPage.Values[0]) + '",';
    JsonLines[2] := '  "branch_id": ' + Trim(ConfigPage.Values[1]) + ',';
    JsonLines[3] := '  "branch_name": "' + Trim(ConfigPage.Values[2]) + '",';
    JsonLines[4] := '  "google_client_id": "' + Trim(AuthPage.Values[0]) + '",';
    JsonLines[5] := '  "google_client_secret": "' + Trim(AuthPage.Values[1]) + '",';
    JsonLines[6] := '  "setup_pin": "' + Trim(AuthPage.Values[2]) + '",';
    JsonLines[7] := '  "installed_at": "' + GetDateTimeString('yyyy-mm-dd hh:nn:ss', '-', ':') + '"';
    JsonLines[8] := '}';
    SaveStringsToUTF8File(ConfigFile, JsonLines, False);

    // Buat file .env untuk kompatibilitas lintas komponen
    SetArrayLength(EnvLines, 6);
    EnvLines[0] := 'BASE_URL=' + Trim(ConfigPage.Values[0]);
    EnvLines[1] := 'BRANCH_ID=' + Trim(ConfigPage.Values[1]);
    EnvLines[2] := 'BRANCH_NAME=' + Trim(ConfigPage.Values[2]);
    EnvLines[3] := 'GOOGLE_CLIENT_ID=' + Trim(AuthPage.Values[0]);
    EnvLines[4] := 'GOOGLE_CLIENT_SECRET=' + Trim(AuthPage.Values[1]);
    EnvLines[5] := 'SETUP_PIN=' + Trim(AuthPage.Values[2]);
    SaveStringsToUTF8File(EnvFile, EnvLines, False);
  end;
end;

// Dialog konfirmasi pembersihan data saat uninstall
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  AppDir: String;
  AppDataDir: String;
begin
  if CurUninstallStep = usUninstall then
  begin
    if MsgBox('Apakah Anda ingin menghapus seluruh data sesi dan pengaturan lokal aplikasi Garudashield Transporter?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      AppDir := ExpandConstant('{app}');
      DeleteFile(AppDir + '\config.json');
      DeleteFile(AppDir + '\.env');

      AppDataDir := ExpandConstant('{userappdata}\garudashield_transporter');
      if DirExists(AppDataDir) then
        DelTree(AppDataDir, True, True, True);

      AppDataDir := ExpandConstant('{localappdata}\garudashield_transporter');
      if DirExists(AppDataDir) then
        DelTree(AppDataDir, True, True, True);
    end;
  end;
end;

