@echo off
:kill
taskkill /F /IM sh.exe
if %ERRORLEVEL% == 0 (goto kill)
pause