@echo off

setlocal
set KFDIR=d:\Games\kf
set STEAMDIR=c:\Steam\steamapps\common\KillingFloor
set outputdir=D:\KFOut\ScrnBalanceSrv

echo Removing previous release files...
del /S /Q %outputdir%\*


del %KFDIR%\System\ScrnBalance*.ucl

echo Compiling project...
call make.cmd
if %ERRORLEVEL% NEQ 0 goto end

echo Exporting .int file...
%KFDIR%\System\ucc dumpint ScrnBalanceSrv.u
rem move %KFDIR%\System\ScrnBalanceSrv.int %KFDIR%\System\ScrnBalanceSrvOrig.int
rem copy KeyBindingsSrv.int + %KFDIR%\System\ScrnBalanceSrvOrig.int %KFDIR%\System\ScrnBalanceSrv.int
rem del %KFDIR%\System\ScrnBalanceSrvOrig.int


echo.
echo Copying release files...
mkdir %outputdir%\System
mkdir %outputdir%\Textures
mkdir %outputdir%\Sounds
mkdir %outputdir%\uz2


copy /y %KFDIR%\system\ScrnBalanceSrv.* %outputdir%\System\
copy /y %KFDIR%\system\ScrnSP.* %outputdir%\System\
copy /y %KFDIR%\system\ScrnVotingHandlerV4.* %outputdir%\system\
copy /y %STEAMDIR%\textures\ScrnTex.utx %outputdir%\Textures\
copy /y %STEAMDIR%\textures\ScrnAch_T.utx %outputdir%\Textures\
copy /y %STEAMDIR%\sounds\ScrnSnd.uax %outputdir%\Sounds\
copy /y *.txt  %outputdir%
copy /y changes.txt  D:\Dropbox\Public\KFSrc\ScrnBalanceVersionHistory.txt
copy /y *.ini  %outputdir%



echo Compressing to .uz2...
%KFDIR%\system\ucc compress %KFDIR%\system\ScrnBalanceSrv.u
%KFDIR%\system\ucc compress %STEAMDIR%\textures\ScrnTex.utx
%KFDIR%\system\ucc compress %STEAMDIR%\textures\ScrnAch_T.utx
%KFDIR%\system\ucc compress %STEAMDIR%\sounds\ScrnSnd.uax
%KFDIR%\system\ucc compress %KFDIR%\system\ScrnVotingHandlerV4.u

move /y %KFDIR%\system\*ScrnBalance*.uz2 %outputdir%\uz2
move /y %KFDIR%\system\ScrnVotingHandlerV4.u.uz2 %outputdir%\uz2
move /y %STEAMDIR%\textures\Scrn*.uz2 %outputdir%\uz2
move /y %STEAMDIR%\sounds\Scrn*.uz2 %outputdir%\uz2

echo Release is ready!

endlocal

pause

:end
