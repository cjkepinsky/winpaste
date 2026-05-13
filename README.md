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
