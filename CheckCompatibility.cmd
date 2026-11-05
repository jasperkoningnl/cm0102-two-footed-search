@echo off
if "%~1"=="" (
 echo Drag the game executable you actually use onto this file.
 pause
 exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0CheckCompatibility.ps1" -ExePath "%~1"
pause
