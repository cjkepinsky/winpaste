@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall-WinPaste.ps1" %*
if errorlevel 1 (
  echo.
  echo WinPaste uninstall failed.
  pause
  exit /b %errorlevel%
)
exit /b 0
