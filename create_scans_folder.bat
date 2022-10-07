@echo off

REM ------------------START OF PRIVILEGDE FUNCTION-----------------------
:init
 setlocal DisableDelayedExpansion
 set cmdInvoke=1
 set winSysFolder=System32
 set "batchPath=%~0"
 for %%k in (%0) do set batchName=%%~nk
 set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
 setlocal EnableDelayedExpansion

:checkPrivileges
  NET FILE 1>NUL 2>NUL
  if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )

:getPrivileges
  if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)
  ECHO.
  ECHO **************************************
  ECHO Invoking UAC for Privilege Escalation
  ECHO **************************************

  ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
  ECHO args = "ELEV " >> "%vbsGetPrivileges%"
  ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
  ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
  ECHO Next >> "%vbsGetPrivileges%"

  if '%cmdInvoke%'=='1' goto InvokeCmd 

  ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
  goto ExecElevation

:InvokeCmd
  ECHO args = "/c """ + "!batchPath!" + """ " + args >> "%vbsGetPrivileges%"
  ECHO UAC.ShellExecute "%SystemRoot%\%winSysFolder%\cmd.exe", args, "", "runas", 1 >> "%vbsGetPrivileges%"

:ExecElevation
 "%SystemRoot%\%winSysFolder%\WScript.exe" "%vbsGetPrivileges%" %*
 exit /B

:gotPrivileges
 setlocal & cd /d %~dp0
 if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

REM ------------END OF PRIVILEDGE FUNCTION----------------------

cls
echo WARNING!!!!
echo.
echo This program will make changes to your PC.
echo Please read through this text so that you understand what 
echo this program changes so that you can undo the changes if anything goes wrong.
echo.
echo This program requires powershell to be installed on the PC.
echo.
echo This program comes with no warrenty.
echo.
echo These are the things that this program will do:
echo.
echo 1. A new folder will be created on your pc.
echo.
echo 2. A new user may be created on this pc.
echo    Please don't create a new username that already exists.
echo.
echo 3. A new share will be created with the name "scans".
echo    The specified user will be given full access to this share.
echo.
echo 4. The current connected network profile will be changed to Private.
echo.
echo 5. "Network discovery" and "File and printer sharing" will be enabled for the Private network profile.
echo.
echo To continue, press y
echo To exit, press n
choice /C yn /N
if %ERRORLEVEL% == 1 goto start
goto end

:start
cls
echo Scans folder setup
echo ------------------
echo.
echo Step 1: Create folder
echo.
echo Where would you like the scans folder?
echo 1. %USERPROFILE%\Desktop\Scans
echo 2. %USERPROFILE%\Documents\Scans
echo 3. %SYSTEMDRIVE%\Scans
echo 4. Manual entry
choice /C 1234 /N
if %ERRORLEVEL% == 1 set scandir="%USERPROFILE%\Desktop\Scans"
if %ERRORLEVEL% == 2 set scandir="%USERPROFILE%\Documents\Scans"
if %ERRORLEVEL% == 3 set scandir="%SYSTEMDRIVE%\Scans"
if %ERRORLEVEL% == 4 goto get_folder
goto create_folder

:get_folder
set /p "scandir=Folder path to create/use:"

:create_folder
mkdir %scandir%

:create_user_question
cls
echo Scans folder setup
echo ------------------
echo.
echo Step 2: Create/Specify user to use for shared folder
echo.
echo User and password to use:
echo 1. Create new username: scan  password: scan
echo 2. Create new username: scan  password: Sc@nn3r123
echo 3. Specify new user
echo 4. Specify existing user
choice /C 1234 /N
if %ERRORLEVEL% == 1 goto create_user_1
if %ERRORLEVEL% == 2 goto create_user_2
if %ERRORLEVEL% == 3 goto create_user_3
if %ERRORLEVEL% == 4 goto create_user_4

:create_user_1
set username=scan
set password=scan
goto create_user_command

:create_user_2
set username=scan
set password=Sc@nner
goto create_user_command

:create_user_3
set /p "username=Username:"
set /p "password=Password:"
goto create_user_command

:create_user_4
set /p "username=Username:"
goto share_folder_question

:create_user_command
net user %username% %password% /add
wmic useraccount where "name='%username%'" set passwordexpires=false

:share_folder_question
cls
echo Scans folder setup
echo ------------------
echo.
echo Step 3: Creating share
echo.
net share scans="%scandir%" /grant:%username%,full
echo.
echo Step 4: Changing network profile to Private
echo.
powershell.exe -command Set-NetConnectionProfile -NetworkCategory Private
echo.
echo Step 5: Enabling "Network Discovery" and "File and Printer Sharing"
echo.
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
echo.
echo Done.
echo.
echo Scan folder location: %scandir%
echo Share path: \\%COMPUTERNAME%\scans
echo Username: %username%
echo Password: %password%
echo.
pause
:end