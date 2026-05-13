@echo off
REM ============================================================
REM  02 - LCM Artifact Export
REM ============================================================
REM  Purpose : Exports a named LCM (Lifecycle Management)
REM            snapshot containing selected artifacts such as
REM            forms, business rules, security, and substitution
REM            variables. Used for version control and migration
REM            between DEV / TEST / PROD environments.
REM  Schedule: Weekly (suggested Sunday midnight)
REM
REM  Pre-req : You must have created an LCM snapshot definition
REM            in the EPM Cloud UI (under Migration). The name
REM            of that definition is passed via LCM_SNAPSHOT_NAME
REM            environment variable in config.env, or as a
REM            command-line argument:
REM
REM            02-lcm-export.bat "MySnapshotName"
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM ---- Load configuration ----
IF NOT EXIST "%~dp0..\config.env" (
    echo [ERROR] config.env not found.
    exit /b 1
)
call "%~dp0..\config.env"

REM ---- Determine snapshot name (argument overrides default) ----
IF NOT "%~1"=="" (
    SET LCM_SNAPSHOT_NAME=%~1
) ELSE (
    IF "%LCM_SNAPSHOT_NAME%"=="" SET LCM_SNAPSHOT_NAME=Weekly_LCM_Export
)

REM ---- Build timestamp ----
FOR /F "tokens=2 delims==" %%I IN ('"wmic os get localdatetime /value"') DO SET DT=%%I
SET TIMESTAMP=%DT:~0,8%_%DT:~8,4%

SET LOG_FILE=%LOG_DIR%\02-lcm-export_%TIMESTAMP%.log
SET LOCAL_FILE=%LCM_DIR%\%LCM_SNAPSHOT_NAME%_%TIMESTAMP%.zip

REM ---- Ensure directories exist ----
IF NOT EXIST "%LOG_DIR%" mkdir "%LOG_DIR%"
IF NOT EXIST "%LCM_DIR%" mkdir "%LCM_DIR%"

REM ---- Start logging ----
echo ============================================================ > "%LOG_FILE%"
echo  LCM Export - Started %DATE% %TIME%                          >> "%LOG_FILE%"
echo  Snapshot: %LCM_SNAPSHOT_NAME%                                >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

REM ---- Step 1: Login ----
echo [%TIME%] Logging in                                          >> "%LOG_FILE%"
call epmautomate login %EPM_USER% "%PASSWORD_FILE%" %EPM_URL% %EPM_DOMAIN% >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Login failed. See %LOG_FILE%
    exit /b 2
)

REM ---- Step 2: Export LCM snapshot ----
echo [%TIME%] Exporting LCM snapshot                              >> "%LOG_FILE%"
call epmautomate exportSnapshot "%LCM_SNAPSHOT_NAME%" >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] LCM export failed. See %LOG_FILE%
    call epmautomate logout >> "%LOG_FILE%" 2>&1
    exit /b 3
)

REM ---- Step 3: Download ----
echo [%TIME%] Downloading snapshot                                >> "%LOG_FILE%"
call epmautomate downloadFile "%LCM_SNAPSHOT_NAME%" >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Download failed. See %LOG_FILE%
    call epmautomate logout >> "%LOG_FILE%" 2>&1
    exit /b 4
)

REM ---- Step 4: Move with timestamp ----
move "%LCM_SNAPSHOT_NAME%.zip" "%LOCAL_FILE%" >> "%LOG_FILE%" 2>&1
echo [%TIME%] Saved to: %LOCAL_FILE%                              >> "%LOG_FILE%"

REM ---- Step 5: Logout ----
call epmautomate logout >> "%LOG_FILE%" 2>&1

echo ============================================================ >> "%LOG_FILE%"
echo  LCM Export - Completed %DATE% %TIME%                        >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

echo [SUCCESS] LCM export complete: %LOCAL_FILE%
echo [INFO]    Log: %LOG_FILE%

ENDLOCAL
exit /b 0
