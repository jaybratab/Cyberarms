@echo off
net session >nul 2>&1
if %errorLevel% == 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
    pause
) else (
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~dp0uninstall.bat\"\"' -Verb RunAs"
)
