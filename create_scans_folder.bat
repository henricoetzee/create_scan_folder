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
echo ------------------------------------------------------
echo WARNING!!!! This program will make changes to your PC.
echo ------------------------------------------------------
echo.
echo This program requires powershell to be installed on the PC.
echo.
echo.
echo These are the steps that we will go through:
echo.
echo Step 1. Specify a new or existing folder to be used for scanning.
echo.
echo Step 2. Specify a new or existing user to be used for scanning. 
echo.
echo Step 3. A new share will be created with the name "scans".
echo         The specified user will be given full access to this share.
echo.
echo Step 4. The current connected network profile will be changed to Private.
echo.
echo Step 5. "Network discovery" and "File and printer sharing" will be enabled for the Private network profile.
echo.
echo To continue, press y
echo To exit, press n
choice /C yn /N
if %ERRORLEVEL% == 1 goto start
goto end

:start
cls
echo ------------------
echo Scans folder setup
echo ------------------
echo.
echo Step 1: Create folder:
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
set /p "scandir=Folder path to create/use (eg c:\data\scans): "
set scandir="%scandir%"

:create_folder
if exist %scandir%\ (
        echo Folder exists
	goto create_user_question
    ) else if not exist %scandir% (
        mkdir %scandir%
	if ERRORLEVEL 1 goto create_folder_error
        goto create_user_question
    ) else (
        echo There is a file with the same name as the required folder.
        goto create_folder_error
    )
pause

:create_folder_error
echo Error occurred
echo 1. Try again
echo 2. Quit
choice /C 12 /N
if %ERRORLEVEL% == 1 goto start
goto end

:create_user_question
cls
echo ------------------
echo Scans folder setup
echo ------------------
echo.
echo Step 1: Folder to use: %scandir%
echo.
echo Step 2: Create/Specify user to use for shared folder:
echo.
echo User and password to use:
echo 1. Create new username: scan  password: scan
echo 2. Create new username: scan  password: Sc@nn3r123
echo 3. Specify new user
echo 4. Specify existing user
echo 5. Quit
choice /C 12345 /N
if %ERRORLEVEL% == 1 goto create_user_1
if %ERRORLEVEL% == 2 goto create_user_2
if %ERRORLEVEL% == 3 goto create_user_3
if %ERRORLEVEL% == 4 goto create_user_4
if %ERRORLEVEL% == 5 goto end

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
net user %username%
if ERRORLEVEL 1 goto create_user_error
goto share_folder_question

:create_user_command
net user %username% %password% /add
if ERRORLEVEL 1 goto create_user_error
wmic useraccount where "name='%username%'" set passwordexpires=false
goto share_folder_question

:create_user_error
echo.
echo Error occurred during user creation/specication.
echo 1. exit
echo 2. continue
echo 3. retry
choice /C 123 /N
if %ERRORLEVEL% == 1 goto end
if %ERRORLEVEL% == 3 goto create_user_question

:share_folder_question
cls
echo ------------------
echo Scans folder setup
echo ------------------
echo.
echo Step 3: Creating share
echo.
net share scans /delete >nul
net share scans=%scandir% /grant:%username%,full >nul
icacls %scandir% /grant %username%:(OI)(CI)F /T >nul
echo.
echo Step 4: Changing network profile to Private
echo.
powershell.exe -command Set-NetConnectionProfile -NetworkCategory Private >nul
echo.
echo Step 5: Enabling "Network Discovery" and "File and Printer Sharing"
echo.
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >nul
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >nul
echo.
echo ------------------------------------------
echo Done.
echo ------------------------------------------
echo Scan folder location: %scandir%
echo Share path: \\%COMPUTERNAME%\scans    (copied to clipboard)
echo Username: %username%
echo Password: %password%
echo ------------------------------------------
echo \\%COMPUTERNAME%\scans| clip
pause
:end
