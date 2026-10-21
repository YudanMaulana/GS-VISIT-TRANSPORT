<#
.SYNOPSIS
  Membangun aplikasi Flutter Windows Release dan membungkusnya menjadi Installer Inno Setup.
#>

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " MEMBANGUN GARUDASHIELD TRANSPORTER INSTALLER             " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Cari path compiler Inno Setup (ISCC.exe)
$isccPath = "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $isccPath)) {
    $found = Get-Command iscc -ErrorAction SilentlyContinue
    if ($found) {
        $isccPath = $found.Source
    } else {
        $foundInProgramFiles = Get-ChildItem "C:\Program Files*\Inno Setup*\ISCC.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($foundInProgramFiles) {
            $isccPath = $foundInProgramFiles.FullName
        }
    }
}

if (-not (Test-Path $isccPath)) {
    Write-Error "Inno Setup Compiler (ISCC.exe) tidak ditemukan. Pastikan Inno Setup 6 terpasang."
    exit 1
}

Write-Host "[1/3] Inno Setup Compiler terdeteksi: $isccPath" -ForegroundColor Green

# 2. Build Flutter Windows Release
Write-Host "[2/3] Membangun Flutter Release untuk Windows (x64)..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter build windows gagal dengan kode exit $LASTEXITCODE"
    exit $LASTEXITCODE
}
Write-Host "Build Windows Release selesai dengan sukses!" -ForegroundColor Green

# 3. Kompilasi Inno Setup Installer
Write-Host "[3/3] Mengompilasi Inno Setup Installer..." -ForegroundColor Yellow
$issScript = Join-Path $PSScriptRoot "installer\garudashield_transporter_setup.iss"
& "$isccPath" "$issScript"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Kompilasi Inno Setup gagal dengan kode exit $LASTEXITCODE"
    exit $LASTEXITCODE
}

# 4. Salin ke installer tanpa suffix versi dan refresh icon cache Windows
$outputDir = Join-Path $PSScriptRoot "installer\Output"
$versionedExe = Join-Path $outputDir "Garudashield_Transporter_Setup_v1.0.0.exe"
$plainExe = Join-Path $outputDir "Garudashield_Transporter_Setup.exe"
if (Test-Path $versionedExe) {
    Copy-Item $versionedExe $plainExe -Force
}

# Flush Windows Explorer icon cache
try {
    $code = @'
using System;
using System.Runtime.InteropServices;
public class ShellNotifier {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
}
'@
    Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
    [ShellNotifier]::SHChangeNotify(0x08000000, 0x1000, [IntPtr]::Zero, [IntPtr]::Zero)
} catch {}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " INSTALLER BERHASIL DIBUAT DENGAN SUKSES!                " -ForegroundColor Green
Write-Host " Berkas installer tersimpan di:                           " -ForegroundColor Green
Write-Host " $PSScriptRoot\installer\Output\                          " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
