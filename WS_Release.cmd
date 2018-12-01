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
mkdir %outputdir%\Animations
mkdir %outputdir%\System
mkdir %outputdir%\Textures
mkdir %outputdir%\Sounds

copy /y %KFDIR%\system\ScrnBalance.* %outputdir%\System\
copy /y %KFDIR%\system\ScrnSP.* %outputdir%\System\
copy /y %KFDIR%\system\ScrnVotingHandlerV4.* %outputdir%\system\
copy /y %STEAMDIR%\animations\ScrnAnims.ukx %outputdir%\Animations\
copy /y %STEAMDIR%\sounds\ScrnSnd.uax %outputdir%\Sounds\
copy /y %STEAMDIR%\textures\ScrnTex.utx %outputdir%\Textures\
copy /y %STEAMDIR%\textures\ScrnAch_T.utx %outputdir%\Textures\
copy /y %STEAMDIR%\Textures\TSC_T.utx %outputdir%\Textures\
copy /y *.txt  %outputdir%
copy /y readme.md  %outputdir%
rem don't suggest to overwrite existing .ini file
copy /y *.ini  %outputdir%

rem For Workshop
copy /y *.ini  ..\System\
rem copy /y LICENSE  ..\Help\ScrnBalanceEULA.txt


echo Release is ready!

endlocal

pause

:end
