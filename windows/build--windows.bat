@echo off

cls
powershell .\build-windows.ps1 -NoPause
echo.
echo **** Installers and portable archive created
echo.
dir ..\installers


echo.
echo.
echo    #### Press any key to exit #####
pause >NUL
echo.
echo.
