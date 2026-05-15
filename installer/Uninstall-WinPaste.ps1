param(
    [string] $InstallDir = (Join-Path $env:LOCALAPPDATA 'Programs\WinPaste'),
    [switch] $RemoveUserData
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string] $Message)
    Write-Host "==> $Message"
}

$installDirFull = [System.IO.Path]::GetFullPath($InstallDir)
$appDataDir = Join-Path $env:LOCALAPPDATA 'WinPaste'
$startMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\WinPaste'
$desktopShortcut = Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'WinPaste.lnk'
$startupRunKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\WinPaste'

Write-Step 'Stopping running WinPaste instances'
Get-Process -Name 'WinPaste.App' -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Step 'Removing shortcuts and registry entries'
Remove-Item -LiteralPath $desktopShortcut -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $startMenuDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $startupRunKey -Name 'WinPaste' -Force -ErrorAction SilentlyContinue
Remove-Item -Path $uninstallKey -Recurse -Force -ErrorAction SilentlyContinue

Write-Step "Removing app files from $installDirFull"
Set-Location $env:TEMP
Remove-Item -LiteralPath $installDirFull -Recurse -Force -ErrorAction SilentlyContinue

if ($RemoveUserData) {
    Write-Step "Removing clipboard history data from $appDataDir"
    Remove-Item -LiteralPath $appDataDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host
Write-Host 'WinPaste uninstalled successfully.'
