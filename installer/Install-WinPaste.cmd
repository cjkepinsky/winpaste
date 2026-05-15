@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-WinPaste.ps1" %*
if errorlevel 1 (
  echo.
  echo WinPaste installation failed.
  pause
  exit /b %errorlevel%
)
exit /b 0
