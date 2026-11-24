param(
    [switch]$Revert
)

# ==============================================================================
#  YUKSEK FPS - Windows Optimization Tool (Nihai / Final Sürüm)
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $revertArg = if ($Revert) { " -Revert" } else { "" }
    if ($PSCommandPath) {
        Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"$revertArg" -Verb RunAs
    } else {
        $url = "https://raw.githubusercontent.com/emirm0e1/unlisted/refs/heads/main/fpsmaks.ps1"
        Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -Command `"irm '$url' | iex$revertArg`"" -Verb RunAs
    }
    exit
}

$Host.UI.RawUI.WindowTitle = "YUKSEK FPS - Final Version"
$ProgressPreference = 'SilentlyContinue'

$BackupFile = "$env:ProgramData\YuksekFPS_Backup.json"

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

function Save-RegBackup {
    param([string]$Path, [string]$Name)
    if (-not $script:BackupData.ContainsKey("$Path|$Name")) {
        $exists = Test-Path $Path
        $prop = if ($exists) { Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue } else { $null }
        $script:BackupData["$Path|$Name"] = [PSCustomObject]@{
            Path    = $Path
            Name    = $Name
            Exists  = ($null -ne $prop)
            Value   = if ($null -ne $prop) { $prop.$Name } else { $null }
        }
    }
}

function Save-ServiceBackup {
    param([string]$Name)
    $svcKey = "SVC|$Name"
    if (-not $script:BackupData.ContainsKey($svcKey)) {
        $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if ($svc) {
            $script:BackupData[$svcKey] = [PSCustomObject]@{
                Type        = "Service"
                Name        = $Name
                StartType   = $svc.StartType.ToString()
            }
        }
    }
}

function Set-RegTracked {
    param($Path, $Name, $Value, $Type = "DWord")
    Save-RegBackup -Path $Path -Name $Name
    Set-Reg -Path $Path -Name $Name -Value $Value -Type $Type
}

if ($Revert) {
    Clear-Host
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "              YUKSEK FPS - AYARLARI GERI ALMA                    " -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host ""

    if (Test-Path $BackupFile) {
        $items = Get-Content -Path $BackupFile -Raw | ConvertFrom-Json
        foreach ($item in $items) {
            if ($item.Type -eq "Service") {
                $svc = Get-Service -Name $item.Name -ErrorAction SilentlyContinue
                if ($svc) {
                    Set-Service -Name $item.Name -StartupType $item.StartType -ErrorAction SilentlyContinue
                }
            } else {
                if ($item.Exists) {
                    if (Test-Path $item.Path) {
                        Set-ItemProperty -Path $item.Path -Name $item.Name -Value $item.Value -ErrorAction SilentlyContinue
                    }
                } else {
                    if (Test-Path $item.Path) {
                        Remove-ItemProperty -Path $item.Path -Name $item.Name -ErrorAction SilentlyContinue
                    }
                }
            }
        }
        Write-Host "Yedek dosyasindaki ayarlar geri yuklendi." -ForegroundColor Green
    } else {
        Write-Host "Yedek dosyasi bulunamadi. Varsayilan ayarlar uygulanıyor..." -ForegroundColor Yellow
        Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 1
        Set-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Name "PreventDeviceEncryption" -Value 0
        Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 0
        Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableConsumerAccountStateContent" -Value 0
        Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableCloudOptimizedContent" -Value 0
        foreach ($svcName in @("RemoteRegistry", "MapsBroker")) {
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            if ($svc) { Set-Service -Name $svcName -StartupType Manual -ErrorAction SilentlyContinue }
        }
        Set-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "DisableWPBT" -Value 0
        Set-Reg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" -Name "ShippedWithReserves" -Value 1
        Set-Reg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 0
        Set-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0
        foreach ($edgeSvc in @("MicrosoftEdgeElevationService", "edgeupdate", "edgeupdatem")) {
            $svc = Get-Service -Name $edgeSvc -ErrorAction SilentlyContinue
            if ($svc) { Set-Service -Name $edgeSvc -StartupType Automatic -ErrorAction SilentlyContinue }
        }
        Set-Reg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 1
        Set-Reg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 1
        Set-Reg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 1
        Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 1
        Set-Reg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "SearchOrderConfig" -Value 1
    }

    Write-Host ""
    Write-Host "Degisikliklerin tam etkili olmasi icin bilgisayari yeniden baslatin." -ForegroundColor Cyan
    Write-Host "Pencereyi kapatmak icin Enter tusuna basin..." -ForegroundColor Yellow
    Read-Host
    exit
}

$script:BackupData = @{}

Clear-Host
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "                    Optimizasyon Basliyor...               " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------------------
# 1. GÜVENLİK YEDEĞİ & TEMEL TWEAKLER
# ------------------------------------------------------------------------------
Write-Host ">>> [01/46] ADIM: Sistem Geri Yukleme Noktasi Olusturuluyor..." -ForegroundColor Yellow
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Set-RegTracked -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 0
    Checkpoint-Computer -Description "YuksekFPS_Final_RestorePoint" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
} catch {}

Write-Host ">>> [02/46] ADIM: Etkinlik Gecmisi Kapatiliyor..." -ForegroundColor Yellow
Set-RegTracked -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0

Write-Host ">>> [03/46] ADIM: BitLocker Kontrol Ediliyor ve Otomatik Sifreleme Engelleniyor..." -ForegroundColor Yellow
try {
    if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
        $bl = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
        if ($bl -and $bl.VolumeStatus -ne "FullyDecrypted") { Disable-BitLocker -MountPoint "C:" -ErrorAction SilentlyContinue }
    }
    Set-RegTracked -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Name "PreventDeviceEncryption" -Value 1
} catch {}

Write-Host ">>> [04/46] ADIM: Tuketici Ozellikleri ve Reklamlar Kapatiliyor..." -ForegroundColor Yellow
Set-RegTracked -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
Set-RegTracked -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableConsumerAccountStateContent" -Value 1
Set-RegTracked -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableCloudOptimizedContent" -Value 1

Write-Host ">>> [10/46] ADIM: Gereksiz Hizmetler Elle Moduna Aliniyor..." -ForegroundColor Yellow
foreach ($svcName in @("RemoteRegistry", "MapsBroker")) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc) {
        Save-ServiceBackup -Name $svcName
        Set-Service -Name $svcName -StartupType Manual -ErrorAction SilentlyContinue
    }
}

Write-Host ">>> [14/46] ADIM: Widget'lar Kaldiriliyor..." -ForegroundColor Yellow
$pkgs = Get-AppxPackage *WebExperience* -ErrorAction SilentlyContinue
if ($pkgs) {
    $pkgs | Remove-AppxPackage -ErrorAction SilentlyContinue
}

Write-Host ">>> [15/46] ADIM: WPBT (OEM Bloatware Injected BIOS) Kapatiliyor..." -ForegroundColor Yellow
Set-RegTracked -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "DisableWPBT" -Value 1

Write-Host ">>> [16/46] ADIM: Ayrilmis Depolama (Reserved Storage) Kapatiliyor..." -ForegroundColor Yellow
Set-RegTracked -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" -Name "ShippedWithReserves" -Value 0

# ------------------------------------------------------------------------------
# 2. GELİŞMİŞ SİSTEM VE PERFORMANS TWEAKLERİ
# ------------------------------------------------------------------------------
Write-Host ">>> [17/46] ADIM: Arka Plan Uygulamalari Kapatiliyor..." -ForegroundColor Yellow
Set-RegTracked -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1

Write-Host ">>> [18/46] ADIM: IPv4 Öncelikli Hale Getiriliyor..." -ForegroundColor Yellow
Set-RegTracked -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 32

Write-Host ">>> [19/46] ADIM: Edge Arka Plan Hizmetleri Kapatiliyor..." -ForegroundColor Yellow
Set-RegTracked -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Value 0
Set-RegTracked -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HardwareAccelerationModeEnabled" -Value 0
Set-RegTracked -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BackgroundModeEnabled" -Value 0
Set-RegTracked -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HubsSidebarEnabled" -Value 0
foreach ($edgeSvc in @("MicrosoftEdgeElevationService", "edgeupdate", "edgeupdatem")) {
    $svc = Get-Service -Name $edgeSvc -ErrorAction SilentlyContinue
    if ($svc) {
        Save-ServiceBackup -Name $edgeSvc
        Set-Service -Name $edgeSvc -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

# ------------------------------------------------------------------------------
# 3. GÖREV ÇUBUĞU, BAŞLAT VE GEZGİN AYARLARI
# ------------------------------------------------------------------------------
Write-Host ">>> [26/46] ADIM: Dosya Gezgini Ayarlari Yapiliyor..." -ForegroundColor Yellow
Set-RegTracked -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1
Set-RegTracked -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
Set-RegTracked -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type "String" -Value "0"
Set-RegTracked -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1

Write-Host ">>> [27/46] ADIM: Koyu Tema Ayarlaniyor..." -ForegroundColor Yellow
Set-RegTracked -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0
Set-RegTracked -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0
Set-RegTracked -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0

# ------------------------------------------------------------------------------
# 4. GAMING, GRAPHICS, PRIVACY & NETWORK TWEAKS
# ------------------------------------------------------------------------------
Write-Host ">>> [28/46] ADIM: Ses İyilestirmeleri Yapiliyor..." -ForegroundColor Yellow
Set-RegTracked -Path "HKCU:\Software\Microsoft\Multimedia\Audio" -Name "UserDuckingPreference" -Value 3
Set-RegTracked -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" -Name "DisableStartupSound" -Value 1

Write-Host ">>> [29/46] ADIM: Fare Ivmesi Kapatiliyor..." -ForegroundColor Yellow
Set-RegTracked -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Type "String" -Value "0"
Set-RegTracked -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Type "String" -Value "0"
Set-RegTracked -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Type "String" -Value "0"

Write-Host ">>> [30/46] ADIM: Oyun Optimizasyonlari (GameDVR Off, FSO & HAGS ON)..." -ForegroundColor Yellow
Set-RegTracked -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name "DirectXUserGlobalSettings" -Type "String" -Value "VRROptimizeEnable=0;SwapEffectUpgradeEnable=1;"

Set-RegTracked -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 4294967295
Set-RegTracked -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0
Set-RegTracked -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Value 8
Set-RegTracked -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Value 6
Set-RegTracked -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Type "String" -Value "High"

Write-Host ">>> [33/46] ADIM: Gizlilik Sikilastirmalari Yapiliyor..." -ForegroundColor Yellow
$consentPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"
$denyStores = @("userNotificationListener","userAccountInformation","contacts","appointments","phoneCall","phoneCallHistory","email","chat","radios","appDiagnostics")
foreach ($store in $denyStores) { Set-RegTracked -Path "$consentPath\$store" -Name "Value" -Type "String" -Value "Deny" }

Set-RegTracked -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0
Set-RegTracked -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "SearchOrderConfig" -Value 0

try {
    $script:BackupData.Values | ConvertTo-Json -Depth 5 | Set-Content -Path $BackupFile -Encoding UTF8
} catch {}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "    YUKSEK FPS OPTIMIZASYONU BASARIYLA TAMAMLANDI!              " -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "                         Optimizasyon by emir                    " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Degisikliklerin tam etkili olmasi icin bilgisayari yeniden baslatin." -ForegroundColor Cyan
Write-Host "Pencereyi kapatmak icin Enter tusuna basin..." -ForegroundColor Yellow
Read-Host
