@echo off

setlocal
set KFDIR=d:\Games\kf
set STEAMDIR=c:\Steam\steamapps\common\KillingFloor
set outputdir=D:\KFOut\ScrnBalance

echo Removing previous release files...
del /S /Q %outputdir%\*


del %KFDIR%\System\ScrnBalance*.ucl

echo Compiling project...
call make.cmd
if %ERRORLEVEL% NEQ 0 goto end

echo Exporting .int file...
%KFDIR%\System\ucc dumpint ScrnBalance.u

echo.
echo Copying release files...
mkdir %outputdir%\System
mkdir %outputdir%\Textures


copy /y %KFDIR%\system\ScrnBalance.* %outputdir%\System\
copy /y %STEAMDIR%\textures\ScrnTex.utx %outputdir%\Textures\
copy /y %STEAMDIR%\textures\ScrnAch_T.utx %outputdir%\Textures\
copy /y %KFDIR%\system\ScrnVotingHandlerMut*.* %outputdir%\system\
copy /y readme.txt  %outputdir%
copy /y changes.txt  %outputdir%
rem don't suggest to overwrite existing .ini file
copy /y *.ini  %outputdir%

rem For Workshop
copy /y *.ini  ..\System\
copy /y LICENSE  ..\Help\ScrnBalanceEULA.txt


echo Release is ready!

endlocal

pause

:end
