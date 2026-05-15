# WinPaste

Windows 11 clipboard history prototype inspired by Paste for macOS.

## MVP scope

- Global shortcut: `Ctrl+Shift+V`
- Bottom overlay with local clipboard history
- Text and image clips
- Selecting a clip sets it as the current Windows clipboard
- Local data under `%LocalAppData%\WinPaste`

## Development

```powershell
& "$env:LOCALAPPDATA\Microsoft\dotnet\dotnet.exe" build .\WinPaste.slnx
& "$env:LOCALAPPDATA\Microsoft\dotnet\dotnet.exe" run --project .\WinPaste.App\WinPaste.App.csproj
```

## Installer

Download the latest installer from GitHub Releases, or build it locally.

Build local installer artifacts:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Build-Installer.ps1
```

The script creates:

- `artifacts\WinPaste-Setup.zip` - portable installer package

To install from the zip, extract it and run `Install-WinPaste.cmd`.

You can optionally try building a self-extracting setup EXE with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Build-Installer.ps1 -BuildIExpress
```

The installer copies WinPaste to `%LocalAppData%\Programs\WinPaste`, creates shortcuts, registers an uninstall entry, and keeps clipboard history data under `%LocalAppData%\WinPaste`. Uninstall with `Uninstall-WinPaste.cmd` or from Windows Settings.
