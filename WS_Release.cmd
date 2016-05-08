@echo off

rem DON'T FORGET to Duplicate HumanPawn and PlayerController class code to the SZ_ScrnBalance!

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
mkdir %outputdir%\uz2


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
copy /y Copyright.txt  ..\Help\ScrnBalanceEULA.txt


echo Compressing to .uz2...
%KFDIR%\system\ucc compress %KFDIR%\system\ScrnBalance.u
%KFDIR%\system\ucc compress %STEAMDIR%\textures\ScrnTex.utx
%KFDIR%\system\ucc compress %STEAMDIR%\textures\ScrnAch_T.utx
%KFDIR%\system\ucc compress %KFDIR%\system\ScrnVotingHandlerV4.u

move /y %KFDIR%\system\ScrnBalance.u.uz2 %outputdir%\uz2
move /y %STEAMDIR%\textures\ScrnTex.utx.uz2 %outputdir%\uz2
move /y %STEAMDIR%\textures\ScrnAch_T.utx.uz2 %outputdir%\uz2
move /y %KFDIR%\system\ScrnVotingHandlerV4.u.uz2 %outputdir%\uz2

echo Release is ready!

endlocal

pause

:end
