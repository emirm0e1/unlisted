# ==============================================================================
#  YUKSEK FPS - Windows Optimization Tool (Nihai / Final Sürüm)
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($PSCommandPath) {
        Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    } else {
        $url = "https://raw.githubusercontent.com/opcinn/yuksekfps/main/yuksekfps.ps1"
        Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -Command `"irm '$url' | iex`"" -Verb RunAs
    }
    exit
}

$Host.UI.RawUI.WindowTitle = "YUKSEK FPS - Final Version"
$ProgressPreference = 'SilentlyContinue'

Clear-Host
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  __   ___   _  ___ _____ _____ _  __   _____ ___  ____  " -ForegroundColor Green
Write-Host "  \ \ / / | | |/ገል/| ____| ____| |/ /  |  ___| _ \/ ___| " -ForegroundColor Green
Write-Host "   \ V /| | | | ' / |  _| |  _| | ' /   | |_  | |_) \___ \ " -ForegroundColor Green
Write-Host "    | | | |_| | . \ | |___| |___| . \   |  _| |  __/ ___) |" -ForegroundColor Green
Write-Host "    |_|  \___/|_|\_\|_____|_____|_|\_\  |_|   |_|   |____/ " -ForegroundColor Green
Write-Host "                                                           " -ForegroundColor Green
Write-Host "                    Optimizasyon Basliyor...               " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

# Yardımcı Fonksiyon: Registry Ayarları
function Set-Reg {
    param($Path, $Name, $Value, $Type = "DWord")
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    if ($Name -eq "(Default)" -or $Name -eq "(default)") {
        Set-ItemProperty -Path $Path -Name "(default)" -Value $Value -ErrorAction SilentlyContinue
    } else {
        Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -ErrorAction SilentlyContinue
    }
}

# ------------------------------------------------------------------------------
# 1. GÜVENLİK YEDEĞİ & TEMEL TWEAKLER
# ------------------------------------------------------------------------------
Write-Host ">>> [01/46] ADIM: Sistem Geri Yukleme Noktasi Olusturuluyor..." -ForegroundColor Yellow
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Set-Reg -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 0
    Checkpoint-Computer -Description "YuksekFPS_Final_RestorePoint" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
} catch {}

Write-Host ">>> [02/46] ADIM: Etkinlik Gecmisi Kapatiliyor..." -ForegroundColor Yellow
Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0

Write-Host ">>> [03/46] ADIM: BitLocker Kontrol Ediliyor ve Otomatik Sifreleme Engelleniyor..." -ForegroundColor Yellow
try {
    if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
        $bl = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
        if ($bl -and $bl.VolumeStatus -ne "FullyDecrypted") { Disable-BitLocker -MountPoint "C:" -ErrorAction SilentlyContinue }
    }
    Set-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Name "PreventDeviceEncryption" -Value 1
} catch {}

Write-Host ">>> [04/46] ADIM: Tuketici Ozellikleri ve Reklamlar Kapatiliyor..." -ForegroundColor Yellow
Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableConsumerAccountStateContent" -Value 1
Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableCloudOptimizedContent" -Value 1

Write-Host ">>> [10/46] ADIM: Gereksiz Hizmetler Elle Moduna Aliniyor..." -ForegroundColor Yellow
Set-Service -Name "RemoteRegistry" -StartupType Manual -ErrorAction SilentlyContinue
Set-Service -Name "MapsBroker" -StartupType Manual -ErrorAction SilentlyContinue

Write-Host ">>> [14/46] ADIM: Widget'lar Kaldiriliyor..." -ForegroundColor Yellow
Get-AppxPackage *WebExperience* | Remove-AppxPackage -ErrorAction SilentlyContinue

Write-Host ">>> [15/46] ADIM: WPBT (OEM Bloatware Injected BIOS) Kapatiliyor..." -ForegroundColor Yellow
Set-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "DisableWPBT" -Value 1

Write-Host ">>> [16/46] ADIM: Ayrilmis Depolama (Reserved Storage) Kapatiliyor..." -ForegroundColor Yellow
Set-Reg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" -Name "ShippedWithReserves" -Value 0

# ------------------------------------------------------------------------------
# 2. GELİŞMİŞ SİSTEM VE PERFORMANS TWEAKLERİ
# ------------------------------------------------------------------------------
Write-Host ">>> [17/46] ADIM: Arka Plan Uygulamalari Kapatiliyor..." -ForegroundColor Yellow
Set-Reg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1

Write-Host ">>> [18/46] ADIM: IPv4 Öncelikli Hale Getiriliyor..." -ForegroundColor Yellow
Set-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 32

Write-Host ">>> [19/46] ADIM: Edge Arka Plan Hizmetleri Kapatiliyor..." -ForegroundColor Yellow
Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Value 0
Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HardwareAccelerationModeEnabled" -Value 0
Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BackgroundModeEnabled" -Value 0
Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HubsSidebarEnabled" -Value 0
Set-Service -Name "MicrosoftEdgeElevationService" -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service -Name "edgeupdate" -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service -Name "edgeupdatem" -StartupType Disabled -ErrorAction SilentlyContinue

# ------------------------------------------------------------------------------
# 3. GÖREV ÇUBUĞU, BAŞLAT VE GEZGİN AYARLARI
# ------------------------------------------------------------------------------
Write-Host ">>> [26/46] ADIM: Dosya Gezgini Ayarlari Yapiliyor..." -ForegroundColor Yellow
Set-Reg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1
Set-Reg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
Set-Reg -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type "String" -Value "0"
Set-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1

Write-Host ">>> [27/46] ADIM: Koyu Tema Ayarlaniyor..." -ForegroundColor Yellow
Set-Reg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0
Set-Reg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0
Set-Reg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0

# ------------------------------------------------------------------------------
# 4. GAMING, GRAPHICS, PRIVACY & NETWORK TWEAKS
# ------------------------------------------------------------------------------
Write-Host ">>> [28/46] ADIM: Ses İyilestirmeleri Yapiliyor..." -ForegroundColor Yellow
Set-Reg -Path "HKCU:\Software\Microsoft\Multimedia\Audio" -Name "UserDuckingPreference" -Value 3
Set-Reg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" -Name "DisableStartupSound" -Value 1

Write-Host ">>> [29/46] ADIM: Fare Ivmesi Kapatiliyor..." -ForegroundColor Yellow
Set-Reg -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Type "String" -Value "0"
Set-Reg -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Type "String" -Value "0"
Set-Reg -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Type "String" -Value "0"

Write-Host ">>> [30/46] ADIM: Oyun Optimizasyonlari (GameDVR Off, FSO & HAGS ON)..." -ForegroundColor Yellow
Set-Reg -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0
Set-Reg -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1

# Fullscreen Optimizations (FSO)
Set-Reg -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 0
Set-Reg -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 0
Remove-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehavior" -ErrorAction SilentlyContinue
Set-Reg -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 0

# Windowed Games Optimizations
Set-Reg -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name "DirectXUserGlobalSettings" -Type "String" -Value "VRROptimizeEnable=0;SwapEffectUpgradeEnable=1;"

Set-Reg -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 4294967295
Set-Reg -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0
Set-Reg -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Value 8
Set-Reg -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Value 6
Set-Reg -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Type "String" -Value "High"

# GPU Hardware-Accelerated GPU Scheduling (HAGS) & Timer
Set-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2
Set-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "GlobalTimerResolutionRequests" -Value 1

Write-Host ">>> [31/46] ADIM: Multiplane Overlay (MPO) Etkinlestiriliyor..." -ForegroundColor Yellow
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -ErrorAction SilentlyContinue

Write-Host ">>> [32/46] ADIM: Ağ Gecikmesi Dusuruluyor (Nagle Algoritmasi Kapatiliyor)..." -ForegroundColor Yellow
$netInterfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
foreach ($interface in $netInterfaces) {
    Set-Reg -Path $interface.PSPath -Name "TcpAckFrequency" -Value 1
    Set-Reg -Path $interface.PSPath -Name "TCPNoDelay" -Value 1
}

Write-Host ">>> [33/46] ADIM: Gizlilik Sikilastirmalari Yapiliyor..." -ForegroundColor Yellow
$consentPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"
$denyStores = @("userNotificationListener","userAccountInformation","contacts","appointments","phoneCall","phoneCallHistory","email","chat","radios","appDiagnostics")
foreach ($store in $denyStores) { Set-Reg -Path "$consentPath\$store" -Name "Value" -Type "String" -Value "Deny" }

Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0
Set-Reg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Value 0

# ------------------------------------------------------------------------------
# 5. POWER PLAN & PERFORMANCE ENGINE
# ------------------------------------------------------------------------------
Write-Host ">>> [34/46] ADIM: YuksekFPS Guc Plani Etkinlestiriliyor..." -ForegroundColor Yellow
$pGuid = "99999999-9999-9999-9999-999999999999"
cmd /c "powercfg /SETACTIVE SCHEME_BALANCED >nul 2>&1"
cmd /c "powercfg /delete $pGuid >nul 2>&1"
cmd /c "powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 $pGuid >nul 2>&1"
cmd /c "powercfg /changename $pGuid `"YuksekFPS`" >nul 2>&1"
cmd /c "powercfg /SETACTIVE $pGuid >nul 2>&1"

Write-Host ">>> [35/46] ADIM: Uyku ve Guc Kısıtlamalari Kapatiliyor..." -ForegroundColor Yellow
powercfg /hibernate off
Set-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -Value 0
Set-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Value 1

Write-Host ">>> [36/46] ADIM: USB Guc Tasarrufu Kapatiliyor..." -ForegroundColor Yellow
Set-Reg -Path "HKLM:\System\ControlSet001\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\0853a681-27c8-4100-a2fd-82013e970683" -Name "Attributes" -Value 0
powercfg /setacvalueindex $pGuid 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0x00000000 2>$null

Write-Host ">>> [37/46] ADIM: Islemci Cekirdek Parki Kapatiliyor (%100 Güc)..." -ForegroundColor Yellow
powercfg /setacvalueindex $pGuid 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 0x00000064 2>$null
powercfg /setacvalueindex $pGuid 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 0x00000064 2>$null

Write-Host ">>> [38/46] ADIM: Kesme Yonetimi Modu Islemci 0 Olarak Ayarlaniyor..." -ForegroundColor Yellow
Set-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\48672f38-7a9a-4bb2-8bf8-3d85be19de4e\2bfc24f9-5ea2-4801-8213-3dbae01aa39d" -Name "Attributes" -Value 2
powercfg /setacvalueindex $pGuid 48672f38-7a9a-4bb2-8bf8-3d85be19de4e 2bfc24f9-5ea2-4801-8213-3dbae01aa39d 5 2>$null
powercfg /setdcvalueindex $pGuid 48672f38-7a9a-4bb2-8bf8-3d85be19de4e 2bfc24f9-5ea2-4801-8213-3dbae01aa39d 5 2>$null

Write-Host ">>> [39/46] ADIM: Ekran Kartı Guc Performansi Maksimuma Aliniyor..." -ForegroundColor Yellow
powercfg /setacvalueindex $pGuid 44f3beca-a7c0-460e-9df2-bb8b99e0cba6 3619c3f2-afb2-4afc-b0e9-e7fef372de36 002 2>$null
cmd /c "powercfg /SETACTIVE $pGuid >nul 2>&1"

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "    YUKSEK FPS OPTIMIZASYONU BASARIYLA TAMAMLANDI!              " -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "                         Optimizasyon by opcin                    " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Degisikliklerin tam etkili olmasi icin bilgisayari yeniden baslatin." -ForegroundColor Cyan
Write-Host "Pencereyi kapatmak icin Enter tusuna basin..." -ForegroundColor Yellow
Read-Host
