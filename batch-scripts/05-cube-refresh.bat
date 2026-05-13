@echo off
REM ============================================================
REM  05 - Cube Refresh Script
REM ============================================================
REM  Purpose : Refreshes the application database (cube) so that
REM            metadata changes become effective. Should be run
REM            after metadata imports and any structural changes.
REM  Schedule: On-demand, typically after 04-metadata-import.bat
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM ---- Load configuration ----
IF NOT EXIST "%~dp0..\config.env" (
    echo [ERROR] config.env not found.
    exit /b 1
)
call "%~dp0..\config.env"

REM ---- Build timestamp ----
FOR /F "tokens=2 delims==" %%I IN ('"wmic os get localdatetime /value"') DO SET DT=%%I
SET TIMESTAMP=%DT:~0,8%_%DT:~8,4%
SET LOG_FILE=%LOG_DIR%\05-cube-refresh_%TIMESTAMP%.log

IF NOT EXIST "%LOG_DIR%" mkdir "%LOG_DIR%"

REM ---- Start logging ----
echo ============================================================ > "%LOG_FILE%"
echo  Cube Refresh - Started %DATE% %TIME%                        >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

REM ---- Step 1: Login ----
echo [%TIME%] Logging in                                          >> "%LOG_FILE%"
call epmautomate login %EPM_USER% "%PASSWORD_FILE%" %EPM_URL% %EPM_DOMAIN% >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Login failed. See %LOG_FILE%
    exit /b 2
)

REM ---- Step 2: Refresh cube ----
echo [%TIME%] Refreshing cube                                     >> "%LOG_FILE%"
call epmautomate refreshCube >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Cube refresh failed. See %LOG_FILE%
    call epmautomate logout >> "%LOG_FILE%" 2>&1
    exit /b 3
)

REM ---- Step 3: Logout ----
call epmautomate logout >> "%LOG_FILE%" 2>&1

echo ============================================================ >> "%LOG_FILE%"
echo  Cube Refresh - Completed %DATE% %TIME%                      >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

echo [SUCCESS] Cube refresh complete.
echo [INFO]    Log: %LOG_FILE%

ENDLOCAL
exit /b 0
