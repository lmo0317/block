@echo off
set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"

if exist "%GODOT_EXE%" (
    start "" "%GODOT_EXE%" --path "%~dp0."
    exit /b 0
)

start "" godot --path "%~dp0."
