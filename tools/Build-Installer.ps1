param(
    [string] $Configuration = 'Release',
    [string] $Runtime = 'win-x64',
    [string] $OutputRoot = (Join-Path $PSScriptRoot '..\artifacts'),
    [switch] $BuildIExpress
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string] $Message)
    Write-Host
    Write-Host "==> $Message"
}

function Get-DotNetCommand {
    $localDotnet = Join-Path $env:LOCALAPPDATA 'Microsoft\dotnet\dotnet.exe'
    if (Test-Path $localDotnet) {
        $sdks = & $localDotnet --list-sdks
        if ($LASTEXITCODE -eq 0 -and $sdks) {
            return $localDotnet
        }
    }

    $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($dotnet) {
        $sdks = & $dotnet.Source --list-sdks
        if ($LASTEXITCODE -eq 0 -and $sdks) {
            return $dotnet.Source
        }
    }

    throw 'dotnet was not found. Install the .NET SDK or add dotnet.exe to PATH.'
}

function Assert-LastExitCode {
    param(
        [string] $ToolName
    )

    if ($LASTEXITCODE -ne 0) {
        throw "$ToolName failed with exit code $LASTEXITCODE."
    }
}

function Remove-DirectoryWithRetry {
    param([string] $Path)

    if (-not (Test-Path $Path)) {
        return
    }

    for ($attempt = 1; $attempt -le 5; $attempt++) {
        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            return
        }
        catch {
            if ($attempt -eq 5) {
                throw
            }

            Start-Sleep -Milliseconds (250 * $attempt)
        }
    }
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$projectPath = Join-Path $repoRoot 'WinPaste.App\WinPaste.App.csproj'
$appIconPath = Join-Path $repoRoot 'WinPaste.App\Assets\AppIcon.ico'
$installerSource = Join-Path $repoRoot 'installer'
$outputRootFull = [System.IO.Path]::GetFullPath($OutputRoot)
$publishDir = Join-Path $outputRootFull "publish\$Runtime"
$packageRoot = Join-Path $outputRootFull 'package\WinPaste'
$packageAppDir = Join-Path $packageRoot 'app'
$zipPath = Join-Path $outputRootFull 'WinPaste-Setup.zip'
$iexpressRoot = Join-Path $outputRootFull 'iexpress'
$payloadZipPath = Join-Path $iexpressRoot 'payload.zip'
$setupExePath = Join-Path $outputRootFull 'WinPaste-Setup.exe'
$dotnetCommand = Get-DotNetCommand

Write-Step 'Cleaning artifacts'
if (Test-Path $outputRootFull) {
    Remove-DirectoryWithRetry $outputRootFull
}

New-Item -ItemType Directory -Force -Path $publishDir, $packageAppDir, $iexpressRoot | Out-Null

Write-Step 'Publishing self-contained WinPaste app'
& $dotnetCommand publish $projectPath `
    -c $Configuration `
    -r $Runtime `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    -p:DebugType=none `
    -p:DebugSymbols=false `
    -o $publishDir
Assert-LastExitCode 'dotnet publish'

$publishAssetsDir = Join-Path $publishDir 'Assets'
New-Item -ItemType Directory -Force -Path $publishAssetsDir | Out-Null
Copy-Item -LiteralPath $appIconPath -Destination $publishAssetsDir -Force

Write-Step 'Staging installer package'
Copy-Item -Path (Join-Path $publishDir '*') -Destination $packageAppDir -Recurse -Force
Copy-Item -LiteralPath (Join-Path $installerSource 'Install-WinPaste.ps1') -Destination $packageRoot -Force
Copy-Item -LiteralPath (Join-Path $installerSource 'Install-WinPaste.cmd') -Destination $packageRoot -Force
Copy-Item -LiteralPath (Join-Path $installerSource 'Uninstall-WinPaste.ps1') -Destination $packageRoot -Force
Copy-Item -LiteralPath (Join-Path $installerSource 'Uninstall-WinPaste.cmd') -Destination $packageRoot -Force

Write-Step 'Creating zip installer'
Compress-Archive -Path (Join-Path $packageRoot '*') -DestinationPath $zipPath -Force

if ($BuildIExpress) {
    $iexpress = Join-Path $env:WINDIR 'System32\iexpress.exe'
    if (Test-Path $iexpress) {
        Write-Step 'Creating self-extracting setup exe with IExpress'
        Compress-Archive -Path (Join-Path $packageRoot '*') -DestinationPath $payloadZipPath -Force
        Copy-Item -LiteralPath (Join-Path $installerSource 'Install-WinPaste.ps1') -Destination $iexpressRoot -Force
        Copy-Item -LiteralPath (Join-Path $installerSource 'Install-WinPaste.cmd') -Destination $iexpressRoot -Force
        Copy-Item -LiteralPath (Join-Path $installerSource 'Uninstall-WinPaste.ps1') -Destination $iexpressRoot -Force

        $sedPath = Join-Path $outputRootFull 'WinPaste-Setup.sed'
        $sed = @"
[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=WinPaste has been installed.
TargetName=$setupExePath
FriendlyName=WinPaste Setup
AppLaunched=Install-WinPaste.cmd
PostInstallCmd=<None>
AdminQuietInstCmd=Install-WinPaste.cmd
UserQuietInstCmd=Install-WinPaste.cmd
SourceFiles=SourceFiles

[Strings]
FILE0="Install-WinPaste.cmd"
FILE1="Install-WinPaste.ps1"
FILE2="Uninstall-WinPaste.ps1"
FILE3="payload.zip"

[SourceFiles]
SourceFiles0=$iexpressRoot

[SourceFiles0]
%FILE0%=
%FILE1%=
%FILE2%=
%FILE3%=
"@
        Set-Content -LiteralPath $sedPath -Value $sed -Encoding ASCII
        & $iexpress /N $sedPath
        Assert-LastExitCode 'IExpress'

        if (-not (Test-Path $setupExePath)) {
            Write-Warning 'IExpress completed but did not create WinPaste-Setup.exe. The zip installer is still available.'
        }
    }
    else {
        Write-Warning 'IExpress was not found. Skipping WinPaste-Setup.exe creation.'
    }
}

Write-Host
Write-Host 'Installer artifacts created:'
Write-Host "  $zipPath"
if (Test-Path $setupExePath) {
    Write-Host "  $setupExePath"
}
