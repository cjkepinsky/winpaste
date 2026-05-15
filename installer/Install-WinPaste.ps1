param(
    [string] $InstallDir = (Join-Path $env:LOCALAPPDATA 'Programs\WinPaste'),
    [switch] $NoDesktopShortcut,
    [switch] $NoStartMenuShortcut,
    [switch] $StartOnLogin,
    [switch] $NoLaunch
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string] $Message)
    Write-Host "==> $Message"
}

function New-Shortcut {
    param(
        [string] $Path,
        [string] $TargetPath,
        [string] $WorkingDirectory,
        [string] $IconLocation
    )

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    $shortcut.TargetPath = $TargetPath
    $shortcut.WorkingDirectory = $WorkingDirectory
    $shortcut.IconLocation = $IconLocation
    $shortcut.Save()
}

function Get-PackageRoot {
    $appDir = Join-Path $PSScriptRoot 'app'
    if (Test-Path (Join-Path $appDir 'WinPaste.App.exe')) {
        return $PSScriptRoot
    }

    $payloadZip = Join-Path $PSScriptRoot 'payload.zip'
    if (-not (Test-Path $payloadZip)) {
        throw 'Installer payload is missing. Expected app\WinPaste.App.exe or payload.zip next to this script.'
    }

    $extractRoot = Join-Path $env:TEMP ("WinPasteSetup-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null
    Expand-Archive -LiteralPath $payloadZip -DestinationPath $extractRoot -Force

    if (-not (Test-Path (Join-Path $extractRoot 'app\WinPaste.App.exe'))) {
        throw 'Installer payload.zip does not contain app\WinPaste.App.exe.'
    }

    return $extractRoot
}

$packageRoot = Get-PackageRoot
$sourceAppDir = Join-Path $packageRoot 'app'
$installDirFull = [System.IO.Path]::GetFullPath($InstallDir)
$exePath = Join-Path $installDirFull 'WinPaste.App.exe'
$appDataDir = Join-Path $env:LOCALAPPDATA 'WinPaste'
$startMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\WinPaste'
$startMenuShortcut = Join-Path $startMenuDir 'WinPaste.lnk'
$desktopShortcut = Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'WinPaste.lnk'
$startupRunKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\WinPaste'

Write-Step 'Stopping running WinPaste instances'
Get-Process -Name 'WinPaste.App' -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Step "Installing files to $installDirFull"
New-Item -ItemType Directory -Force -Path $installDirFull | Out-Null
Copy-Item -Path (Join-Path $sourceAppDir '*') -Destination $installDirFull -Recurse -Force
Copy-Item -LiteralPath (Join-Path $packageRoot 'Uninstall-WinPaste.ps1') -Destination $installDirFull -Force

if (-not $NoStartMenuShortcut) {
    Write-Step 'Creating Start Menu shortcuts'
    New-Item -ItemType Directory -Force -Path $startMenuDir | Out-Null
    New-Shortcut -Path $startMenuShortcut -TargetPath $exePath -WorkingDirectory $installDirFull -IconLocation $exePath
    New-Shortcut -Path (Join-Path $startMenuDir 'Uninstall WinPaste.lnk') `
        -TargetPath 'powershell.exe' `
        -WorkingDirectory $installDirFull `
        -IconLocation $exePath
    $uninstallShortcut = New-Object -ComObject WScript.Shell
    $shortcut = $uninstallShortcut.CreateShortcut((Join-Path $startMenuDir 'Uninstall WinPaste.lnk'))
    $shortcut.TargetPath = 'powershell.exe'
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$installDirFull\Uninstall-WinPaste.ps1`""
    $shortcut.WorkingDirectory = $installDirFull
    $shortcut.IconLocation = $exePath
    $shortcut.Save()
}

if (-not $NoDesktopShortcut) {
    Write-Step 'Creating Desktop shortcut'
    New-Shortcut -Path $desktopShortcut -TargetPath $exePath -WorkingDirectory $installDirFull -IconLocation $exePath
}

if ($StartOnLogin) {
    Write-Step 'Enabling start on login'
    New-Item -Path $startupRunKey -Force | Out-Null
    New-ItemProperty -Path $startupRunKey -Name 'WinPaste' -Value "`"$exePath`"" -PropertyType String -Force | Out-Null
}

Write-Step 'Registering uninstall entry'
New-Item -Path $uninstallKey -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'DisplayName' -Value 'WinPaste' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'DisplayVersion' -Value '0.1.0' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'Publisher' -Value 'WinPaste' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'InstallLocation' -Value $installDirFull -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'DisplayIcon' -Value $exePath -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'UninstallString' -Value "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$installDirFull\Uninstall-WinPaste.ps1`"" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'NoModify' -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name 'NoRepair' -Value 1 -PropertyType DWord -Force | Out-Null

Write-Host
Write-Host "WinPaste installed successfully."
Write-Host "App files: $installDirFull"
Write-Host "Clipboard history data: $appDataDir"

if (-not $NoLaunch) {
    Write-Step 'Launching WinPaste'
    Start-Process -FilePath $exePath -WorkingDirectory $installDirFull
}
