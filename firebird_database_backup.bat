@ECHO OFF
SETLOCAL
SET CurrentDir=%~dp0
set DIR=%CurrentDir%
::
:: First KS-AOW database config
::
set ADIR=AOW
set LOGA=WAPTEKA.LOG
set GBKA=WAPTEKA.GBK
SET AOWFDB=C:\KSBAZA\KS-APW\WAPTEKA.FDB
::
:: Second KS-EDE database config
::
set EDIR=EDE
set LOGE=KSEDE.LOG
set GBKE=KSEDE.GBK
SET EDEFDB=C:\KS\APW\EDE\BAZA\KSEDE.FDB
::
:: Firebird gbak.exe location
:: 
set FBAPP="C:\Program Files\Firebird\Firebird_3_0\gbak.exe"
::
:: 7zip 7z.exe location
::
set ZAPP="C:\Program Files\7-Zip\7z.exe"
set AEXT=7z
::
:: BACKUP config
::
SET "EXTDIR=D:\"
SET BACKUPLOG=%CurrentDir%backup.log
SET DATE =date /t
SET TIME =time /t
SET DATE_TIME=[%DATE% %TIME%]
::
:: Script Database user parameterez as argument ex. sysdba
::
SET DBUSER=%1
SET DBPASSWORD=%2
SET _DBUSERLABEL=dbUSER
SET _DBPASSWORDLABEL=dbPASSWORD

SET "COUNTERFILE=%CurrentDir%counter.txt"
SET "EXTERNAL_COUNTER_FILE=%CurrentDir%counter_external.txt"
SET /A MAX=7
SET /A MAX_EXTERNAL=10
SET FILECONTENT=n
SET EXTERNAL_FILECONTENT=n
SET /A ACT=0
SET /A ACT_EXTERNAL=0
SET NEWFILE=n

SET ERRORNOTIFY=BACKUP SCRIPT FAILED!
SET STATUS=y

set ARCHAOW=%DIR%%ADIR%\AOW%ACT%.%AEXT%
set ARCHEDE=%DIR%%EDIR%\EDE%ACT%.%AEXT%


:: CHECK BACKUP DIR

call :setBackupDir STATUS

call :checkCounterFile %COUNTERFILE% , NEWFILE

call :setCounter ACT , %NEWFILE% , FILECONTENT , %COUNTERFILE%

SET NEWFILE=n

call :checkCounterFile %EXTERNAL_COUNTER_FILE% , NEWFILE

call :setCounter ACT_EXTERNAL , %NEWFILE% , EXTERNAL_FILECONTENT , %EXTERNAL_COUNTER_FILE%

call :updateArchName ARCHAOW,%ADIR%\AOW

call :updateArchName ARCHEDE,%EDIR%\EDE

call :checkFileContent %FILECONTENT% , %COUNTERFILE%

call :checkFileContent %EXTERNAL_FILECONTENT% , %EXTERNAL_COUNTER_FILE%

call :updateCounter %ACT% , %MAX% , counter.txt

call :updateCounter %ACT_EXTERNAL% , %MAX_EXTERNAL% , counter_external.txt

CALL :writeNotify

:: CHECK DATABASE USER AND PASSWORD AS SCRIPT PARAMETER

CALL :checkRunScriptParameter STATUS , %_DBUSERLABEL% , %DBUSER%
CALL :checkRunScriptParameter STATUS , %_DBPASSWORDLABEL% , %DBPASSWORD%

:: CHECK KS-AOW DATABASE FILE EXIST

CALL :exist STATUS , %AOWFDB%

:: CHECK KS-EDE DATABASE FILE EXIST

CALL :exist STATUS , %EDEFDB%

:: REMOVE KS-AOW DATABASE LOG FILE TO PREVENT ERROR GBAK -c

CALL :removeFile STATUS , %DIR%%LOGA%

:: REMOVE KS-EDE DATABASE LOG  LOG FILE TO PREVENT ERROR GBAK -c

CALL :removeFile STATUS , %DIR%%LOGA%

:: 
:: REMOVE OLD KS-AOW DATABASE ARCHIVE FILE

CALL :removeFile STATUS , %ARCHAOW%

:: REMOVE LOG FILE TO PREVENT ERROR GBAK -c

CALL :removeFile STATUS , %DIR%%LOGE%

:: REMOVE OLD KS-EDE DATABASE ARCHIVE FILE

CALL :removeFile STATUS , %ARCHEDE%

:: CREATE AOW DIR

CALL :createDir STATUS , %DIR%%ADIR%

:: CREATE EDE DIR

CALL :createDir STATUS , %DIR%%EDIR%

:: CREATE KS-AOW DATABASE BACKUP (FIREBIRD GBK)

CALL :createBackup STATUS , %AOWFDB% , %DIR%%GBKA% , %DIR%%LOGA%

:: CREATE KS-AOW DATABASE BACKUP ARCHIVE

CALL :createArchive STATUS , %ARCHAOW% , %DIR%%LOGA% , %DIR%%GBKA%

:: CREATE KS-EDE DATABASE BACKUP (FIREBIRD GBK)

CALL :createBackup STATUS , %EDEFDB% , %DIR%%GBKE% , %DIR%%LOGE%

:: CREATE KS-EDE DATABASE BACKUP ARCHIVE

CALL :createArchive STATUS , %ARCHEDE% , %DIR%%LOGE% , %DIR%%GBKE%

CALL :copy STATUS , %ARCHAOW% , %EXTDIR% , AOW%ACT_EXTERNAL%.%AEXT%

CALL :copy STATUS , %ARCHEDE% , %EXTDIR% , EDE%ACT_EXTERNAL%.%AEXT%

:: ADD GOTO TO PREVENT RUN FUNCTION WITHOUT CALL
GOTO MAIN

::
:setBackupDir

IF EXIST %DIR% (
 :: BACKUP DIR EXISTS 
 EXIT /B 0
)
:: TRY CREATE BACKUP DIR
mkdir %DIR%
IF %ERRORLEVEL% NEQ 0 (
 ECHO %DATE_TIME% FAILED CREATE BACKUP DIR - %DIR% >> %BACKUPLOG%
 SET %~1=n
 EXIT /B 1
) ELSE (
 Rem ECHO CREATE BACKUP DIR - %DIR%
 EXIT /B 0
)
EXIT /B 0

:: FUNCTION checkCounterFile
:checkCounterFile
echo %DATE_TIME% %~0 >> %BACKUPLOG%

if exist %~1 (
 echo %DATE_TIME% file counter - %~1 exists >> %BACKUPLOG%
 SET %~2=n
) else (
 echo %DATE_TIME% file counter - %~1 doesn't exist - create new >> %BACKUPLOG%
 SET %~2=y
)
EXIT /B 0
:: FUNCTION setCounter
:setCounter
echo %DATE_TIME% %~0 >> %BACKUPLOG%

if [%STATUS%]==[n] ( 
 echo %DATE_TIME% ERROR EXIST %~0 = EXIT >> %BACKUPLOG%
 EXIT /B 0
)

IF %~2 EQU y (
 echo %DATE_TIME% %~0 NEW FILE >> %BACKUPLOG%
 set /A %~1=1
 echo %DATE_TIME% %~0 ACT - 1 >> %BACKUPLOG%
 EXIT /B 0
)
FOR /F %%i IN (%~4) DO (
 Rem @echo FILE VALUE - %%i
 :: :setCounterLoop %~1 , 
 set /A %~1=%%i
 ECHO %DATE_TIME% %~0 ACT - %%i  >> %BACKUPLOG%
 SET %~3=y
 ECHO %DATE_TIME% %~0 FILECONTENT - y  >> %BACKUPLOG%
 EXIT /B 0
)
EXIT /B 0
:: TO DO
:setCounterLoop

EXIT /B 0

:: FUNTION
:updateArchName
 echo %DATE_TIME% %~0 >> %BACKUPLOG%
if [%STATUS%]==[n] ( 
 echo %DATE_TIME% ERROR EXIST %~0 = EXIT >> %BACKUPLOG%
 EXIT /B 0
)
 SET %~1=%DIR%%~2%ACT%.%AEXT%

EXIT /B 0
:: FUNCTION checkFileContent
:checkFileContent
echo %DATE_TIME% %~0 >> %BACKUPLOG%
IF %~1 EQU n (
 ECHO %DATE_TIME% CLEAR FILE CONTENT >> %BACKUPLOG%
 Rem ECHO 1> %CurrentDir%counter.txt
 echo|set /p="1" > %~2
 Rem exit
  EXIT /B 0
) ELSE (
 ECHO %DATE_TIME% FILE CONTENT OK >> %BACKUPLOG%
)
EXIT /B 0
:: FUNCTION updateCounter
:updateCounter
echo %DATE_TIME% %~0 >> %BACKUPLOG%
echo %DATE_TIME% ACT - %~1 >> %BACKUPLOG%
echo %DATE_TIME% MAX - %~2 >> %BACKUPLOG%
SET /A NEW=%~1+1
echo %DATE_TIME% NEW - %NEW% >> %BACKUPLOG%
IF %NEW% GTR %~2 (
  echo %DATE_TIME% NEW VALUE GREATER THAN MAX - reset counter >> %BACKUPLOG%
  echo|set /p="1" > %CurrentDir%%~3
) else (
  echo %DATE_TIME% NEW VALUE LESS THAN MAX - update counter >> %BACKUPLOG%
  echo %DATE_TIME% NEW - %NEW% >> %BACKUPLOG%
  echo|set /p="%NEW%" > %CurrentDir%%~3
)
EXIT /B 0
:: ################### FUNCTION writeNotify() ###################
:writeNotify
echo %DATE_TIME% %~0 >> %BACKUPLOG%
:: COMMENT LINE
echo %DATE_TIME% START DATABASE KS-AOW AND KS-EDE BACKUP SCRIPT. >> %BACKUPLOG%
echo %DATE_TIME% Plik bazy danych KS-AOW - %AOWFDB% >> %BACKUPLOG%
echo %DATE_TIME% Plik bazy danych KS-EDE - %EDEFDB% >> %BACKUPLOG%

EXIT /B 0
:: ################### FUNCTION checkRunScriptParameter() ###################

:checkRunScriptParameter
echo %DATE_TIME% RUN FUNCTION - %~0 >> %BACKUPLOG%
:: %~1 - status
:: %~2 - label 
:: %~3 - parameter

if [%~2]==[] ( 
 echo %DATE_TIME% SET function checkRunScript ARG2 - %~2 >> %BACKUPLOG%
 EXIT
) 
::ELSE ( echo LABEL OK )

if [%~3]==[] ( 
 echo %DATE_TIME% SET function checkRunScript ARG3 - %~3 >> %BACKUPLOG% 
 EXIT 
)
::ELSE ( echo PARAMETER OK )

EXIT /B 0
:: ################### FUNCTION exists() ###################
:exist
echo %DATE_TIME% %~0 >> %BACKUPLOG%
:: %~1 = status
:: %~2 = file

::ECHO STATUS = %STATUS%
ECHO %DATE_TIME% FILE = %~2 >> %BACKUPLOG%

if [%STATUS%]==[n] ( 
 echo %DATE_TIME% ERROR EXIST %~0 = EXIT >> %BACKUPLOG%
 EXIT /B 0
) 

if ["%~2"]==[] ( 
 echo %DATE_TIME% SET %~0 ARG1 - FILE %~2 >> %BACKUPLOG%
 SET %~1=n
:: EXIT
EXIT
) 

IF EXIST "%~2" ( 
 echo %DATE_TIME% FILE %~2 EXIST - CONTINUE >> %BACKUPLOG%
) ELSE (
 echo %DATE_TIME% ERROR - FILE %~2 NOT EXIST >> %BACKUPLOG%
 SET %~1=n
:: EXIT
EXIT
)

EXIT /B 0
:: ################### FUNCTION removeFile() ###################
:removeFile
echo %DATE_TIME% %~0 >> %BACKUPLOG%

:: %~1 = status
:: %~2 = directory with file

:: TO SET VARIABLE WRITE VAR INDEX WITHOUT CHAR ~

ECHO %DATE_TIME% FILE = %~2 >> %BACKUPLOG%

::ECHO STATUS = %STATUS%

if [%STATUS%]==[n] ( 
 echo %DATE_TIME% ERROR EXIST %~0 = EXIT >> %BACKUPLOG%
 EXIT /B 1
) 

::echo FILE = %~2

if [%~2]==[] ( 
 echo %DATE_TIME% SET %~0 ARG1 - FILE %~2 >> %BACKUPLOG%
 SET %~1=n
 EXIT /B 1
) 

IF EXIST %~2 ( 
 echo %DATE_TIME% OLD FILE %~2 EXIST - REMOVE >> %BACKUPLOG%
 del /F %~2
 echo %DATE_TIME% FILE %~2 REMOVED - CONTINUE >> %BACKUPLOG%
) ELSE (
 echo %DATE_TIME% NO OLD FILE %~2 - CONTINUE >> %BACKUPLOG%
)
::SET %4=n
EXIT /B 0
:: ################### FUNCTION createDir () ###################
:createDir
echo %DATE_TIME% %~0 >> %BACKUPLOG%
:: %~1 = status
:: %~2 = directory
::ECHO STATUS = %STATUS%

ECHO %DATE_TIME% FILE = %~2 >> %BACKUPLOG%

if [%STATUS%]==[n] ( 
 echo %DATE_TIME% ERROR EXIST %~0 = EXIT >> %BACKUPLOG%
 EXIT /B 1
) 

if [%~2]==[] ( 
 echo SETUP DIRECTORY %~2
 SET %~1=n
 EXIT /B 1
) 

IF EXIST %~2 ( 
echo %DATE_TIME% DIR %~2 ALREADY EXIST - CONTINUE >> %BACKUPLOG%
) ELSE (
echo %DATE_TIME% DIR %~2 NOT EXIST - CREATE >> %BACKUPLOG%
mkdir %~2
echo %DATE_TIME% DIR %~2 CREATED - CONTINUE >> %BACKUPLOG%
)
EXIT /B 0
:: ################### FUNCTION createBackup () ###################
:createBackup
echo %DATE_TIME% %~0 >> %BACKUPLOG%

:: %~1 = status
:: %~2 = database file
:: %~3 = database gbk file
:: %~4 = database log file

::ECHO STATUS = %STATUS%
 ECHO %DATE_TIME% DATABASE FILE %~2 >> %BACKUPLOG%
 ECHO %DATE_TIME% DATABASE GBK FILE %~3 >> %BACKUPLOG%
 ECHO %DATE_TIME% DATABASE LOG FILE %~4 >> %BACKUPLOG%

if [%STATUS%]==[n] ( 
 echo %DATE_TIME% ERROR EXIST %~0 = EXIT >> %BACKUPLOG%
 EXIT /B 1
) 

:: CHECK FUNCTION PARAMETER
:: IF statements do not support logical operators. You can implement a logical OR as below:
if [%~2]==[] ( 
 echo %DATE_TIME% SET DATABASE FILE %~2 >> %BACKUPLOG%
 SET %~1=n
 EXIT /B 1
) 
if [%~3]==[] ( 
 echo %DATE_TIME% SET DATABASE GBK FILE %~3 >> %BACKUPLOG%
 SET %~1=n
 EXIT /B 1
) 
if [%~4]==[] ( 
 echo %DATE_TIME% SET DATABASE LOG FILE %~4 >> %BACKUPLOG%
 SET %~1=n
 EXIT /B 1
) 
:: END CHECK FUNCTION PARAMETER

IF EXIST %~2 (
 echo %DATE_TIME% DATABASE FILE %~2 EXIST - RUN >> %BACKUPLOG%
 %FBAPP% -b %~2  %~3 -user %DBUSER% -password %DBPASSWORD% -v -Y %~4
) ELSE (
 ECHO %DATE_TIME% DATABASE FILE %~2 NOT EXIST - EXIT >> %BACKUPLOG%
 SET %~1=n
)
EXIT /B 0
:: ################### FUNCTION createArchive() ###################
:createArchive
echo %DATE_TIME% %~0 >> %BACKUPLOG%
:: %~1 = status
:: %~2 = archive file
:: %~3 = database gbk file
:: %~4 = database log file

::ECHO STATUS = %STATUS%

ECHO %DATE_TIME% ARCHIVE FILE %~2 >> %BACKUPLOG%
ECHO %DATE_TIME% DATABASE GBK FILE %~3 >> %BACKUPLOG%
ECHO %DATE_TIME% DATABASE LOG FILE %~4 >> %BACKUPLOG%

if [%STATUS%]==[n] ( 
echo %DATE_TIME% ERROR EXIST = EXIT >> %BACKUPLOG%
EXIT /B 1
) 
:: CHECK FUNCTION PARAMETER
:: IF statements do not support logical operators. You can implement a logical OR as below:
if [%~2]==[] ( 
 echo %DATE_TIME% SET ARCHIVE FILE %~2 >> %BACKUPLOG%
 SET %~1=n
 EXIT /B 1
) 
if [%~3]==[] ( 
 echo %DATE_TIME% SET DATABASE GBK FILE %~3 >> %BACKUPLOG%
 SET %~1=n
 EXIT /B 1
) 
if [%~4]==[] ( 
 echo %DATE_TIME% SET DATABASE LOG FILE %~4 >> %BACKUPLOG%
 SET %~1=n
 EXIT /B 1
) 
:: END CHECK FUNCTION PARAMETER
echo %DATE_TIME% CREATE %~2 : %~3 , %~4 >> %BACKUPLOG%
%ZAPP% a -t7z -mx9 -mmt4 %~2 %~3 %~4 >nul 2>&1

EXIT /B 0
:: ################### FUNCTION copy() ###################
:copy
echo %DATE_TIME% %~0 >> %BACKUPLOG%
:: %~1 = status
:: %~2 = file
:: %~3 = directory
::ECHO STATUS = %STATUS%

ECHO %DATE_TIME% FILE %~2 >> %BACKUPLOG%
ECHO %DATE_TIME% DIRECTORY %~3 >> %BACKUPLOG%

if [%STATUS%]==[n] ( 
 echo %DATE_TIME% ERROR EXIST %~0 = EXIT >> %BACKUPLOG%
 EXIT /B 1
) 

:: CHECK FUNCTION PARAMETER
:: IF statements do not support logical operators. You can implement a logical OR as below:
if [%~2]==[] ( 
 echo %DATE_TIME% SET %~0 ARG2 - file to copy %~2 >> %BACKUPLOG%
 SET %~1=n
 EXIT /B 1
) 
if ["%~3"]==[] ( 
 echo %DATE_TIME% SET %~0 ARG3 - directory where copy %~3 >> %BACKUPLOG%
 SET %~1=n
 EXIT /B 1
) 

:: END CHECK FUNCTION PARAMETER

CALL :exist STATUS , %~3

if [%STATUS%]==[n] ( 
 echo %DATE_TIME% AFTER CHECK FILE ERROR EXIST = EXIT >> %BACKUPLOG%
 EXIT /B 1
)

echo %DATE_TIME% COPY FILE %~2 TO %~3%~4 >> %BACKUPLOG%
copy /Y %~2 /D %~3%~4
IF %ERRORLEVEL% NEQ 0 ( 
   echo %DATE_TIME% ERROR COPY FILE %~2 TO %~3%~4 >> %BACKUPLOG% 
)
EXIT /B 0
:MAIN

::echo ACTUALL STATUS = %STATUS%

if [%STATUS%]==[n] ( 
 echo %ERRORNOTIFY% CHECK LOG FILE!
 echo %DATE_TIME% %ERRORNOTIFY% >> %BACKUPLOG%
) else (
 echo %DATE_TIME% BACKUP SCRIPT END SUCCESSFUL >> %BACKUPLOG%
)
Rem shutdown operation system
Rem shutdown -s -t 60
Rem cancel shutdown operation system
Rem shutdown /a

ENDLOCAL
EXIT /B 0
