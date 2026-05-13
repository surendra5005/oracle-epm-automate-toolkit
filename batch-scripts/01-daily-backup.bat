@echo off
REM ============================================================
REM  01 - Daily Backup Script
REM ============================================================
REM  Purpose : Exports a full Artifact Snapshot of the EPM
REM            application and downloads it locally.
REM  Schedule: Daily via Task Scheduler (suggested 2:00 AM)
REM  Output  : <BACKUP_DIR>\backup_YYYYMMDD_HHMM.zip
REM            <LOG_DIR>\01-daily-backup_YYYYMMDD_HHMM.log
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM ---- Load configuration ----
IF NOT EXIST "%~dp0..\config.env" (
    echo [ERROR] config.env not found. Copy config-templates\config.env.template
    echo         to repo root as config.env and fill in your values.
    exit /b 1
)
call "%~dp0..\config.env"

REM ---- Build timestamp ----
FOR /F "tokens=2 delims==" %%I IN ('"wmic os get localdatetime /value"') DO SET DT=%%I
SET TIMESTAMP=%DT:~0,8%_%DT:~8,4%

SET LOG_FILE=%LOG_DIR%\01-daily-backup_%TIMESTAMP%.log
SET LOCAL_FILE=%BACKUP_DIR%\backup_%TIMESTAMP%.zip

REM ---- Ensure directories exist ----
IF NOT EXIST "%LOG_DIR%" mkdir "%LOG_DIR%"
IF NOT EXIST "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM ---- Start logging ----
echo ============================================================ > "%LOG_FILE%"
echo  Daily Backup - Started %DATE% %TIME%                        >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

REM ---- Step 1: Login ----
echo [%TIME%] Logging in to %EPM_URL%                              >> "%LOG_FILE%"
call epmautomate login %EPM_USER% "%PASSWORD_FILE%" %EPM_URL% %EPM_DOMAIN% >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Login failed. See %LOG_FILE%
    exit /b 2
)

REM ---- Step 2: Export snapshot ----
echo [%TIME%] Exporting snapshot: %SNAPSHOT_NAME%                  >> "%LOG_FILE%"
call epmautomate exportSnapshot "%SNAPSHOT_NAME%" >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Snapshot export failed. See %LOG_FILE%
    call epmautomate logout >> "%LOG_FILE%" 2>&1
    exit /b 3
)

REM ---- Step 3: Download snapshot ----
echo [%TIME%] Downloading snapshot                                 >> "%LOG_FILE%"
call epmautomate downloadFile "%SNAPSHOT_NAME%" >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Download failed. See %LOG_FILE%
    call epmautomate logout >> "%LOG_FILE%" 2>&1
    exit /b 4
)

REM ---- Step 4: Move to timestamped backup folder ----
move "%SNAPSHOT_NAME%.zip" "%LOCAL_FILE%" >> "%LOG_FILE%" 2>&1
echo [%TIME%] Backup saved to: %LOCAL_FILE%                        >> "%LOG_FILE%"

REM ---- Step 5: Cleanup old backups (retention) ----
echo [%TIME%] Removing backups older than %BACKUP_RETENTION_DAYS% days >> "%LOG_FILE%"
forfiles /p "%BACKUP_DIR%" /m backup_*.zip /d -%BACKUP_RETENTION_DAYS% /c "cmd /c del @path" >> "%LOG_FILE%" 2>nul

REM ---- Step 6: Logout ----
call epmautomate logout >> "%LOG_FILE%" 2>&1

echo ============================================================ >> "%LOG_FILE%"
echo  Daily Backup - Completed %DATE% %TIME%                      >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

echo [SUCCESS] Backup complete: %LOCAL_FILE%
echo [INFO]    Log: %LOG_FILE%

ENDLOCAL
exit /b 0
