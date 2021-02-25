@echo off

setlocal

set CURDIR=%~dp0
if not exist ..\ScrnMakeEnv.cmd (
    set /A ERR=101
    echo ScrnMakeEnv.cmd not found!
    goto end
)
call ..\ScrnMakeEnv.cmd %CURDIR%

set STEAMAPPID=1250
set KFARGS=KF-ScrnTestGrounds.rom?Game=ScrnBalanceSrv.ScrnGameType?GameLength=8
set KFSRVPORT=7707
set KFSRVARGS=%KFARGS%?VACSecured=true?MaxPlayers=6?Port=%KFSRVPORT%
set /A IS_SRV=0

:args
if .%1. == ./?. goto help
if .%1. == ./m. goto arg_make
if .%1. == ./s. goto arg_server
if not .%1. == .. goto help

if %IS_SRV% NEQ 0 goto server
goto localgame

:arg_make
echo Compiling project...
call make.cmd
set /A ERR=%ERRORLEVEL%
if %ERR% NEQ 0 goto end
shift
goto args

:arg_server
set /A IS_SRV=1
shift
goto args

:localgame
echo Local Test
start %STEAMEXE% -applaunch %STEAMAPPID% %KFARGS%
goto end

:server
echo Server Mode
start %STEAMEXE% -applaunch %STEAMAPPID% 127.0.0.1:%KFSRVPORT%

echo Syncing System directory
cd %STEAMDIR%\System2
xcopy /U /D /Y ..\System\*.u .\

echo Waiting for KF to start...
echo You can press a key once you see the game logo
timeout /t 5

echo Starting KF Server
rem ucc server KF-Foundry.rom?Game=ScrnBalanceSrv.ScrnGameType?GameLength=60?VACSecured=true?MaxPlayers=6?Port=7707 log=KFServer.log
ucc server %KFSRVARGS% log=KFServer.log
set /A ERR=%ERRORLEVEL%
echo Server stopped (%ERR%)
goto end

:help
echo Launches Killing Floor game
echo Usage:
echo %0 [/m] [/s]
echo    /m      - calls make, on success launches KF
echo    /s      - Launches KF in dedicated server test mode

:end
endlocal & SET _EC=%ERR%
exit /b %_EC%
