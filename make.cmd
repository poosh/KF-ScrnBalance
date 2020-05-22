@echo off

setlocal
color 07

set CURDIR=%~dp0
call ..\ScrnMakeEnv.cmd %CURDIR%

cd /D %KFDIR%\System
del %KFPACKAGE%.u

ucc make
set /A ERR=%ERRORLEVEL%
if %ERR% NEQ 0 goto error

color 0A
del KillingFloor.log 2>nul
del steam_appid.txt 2>nul

del %STEAMDIR%\System\KillingFloor.log 2>nul
del %STEAMDIR%\System\steam_appid.txt 2>nul

xcopy /F /I /Y %KFPACKAGE%.u %STEAMDIR%\System\
xcopy /F /I /Y %KFPACKAGE%.ucl %STEAMDIR%\System\
xcopy /F /I /Y %KFPACKAGE%.int %STEAMDIR%\System\

echo --------------------------------
echo Compile successful.
echo --------------------------------
goto end

:error
color 0C
echo ################################
echo Compile ERROR! Code = %ERR%.
echo ################################

:end
cd /D %CURDIR%
endlocal & SET _EC=%ERR%
exit /b %_EC%
