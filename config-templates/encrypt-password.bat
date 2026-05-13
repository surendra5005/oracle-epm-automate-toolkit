@echo off
REM ============================================================
REM  Encrypt Password Helper
REM ============================================================
REM  Generates an encrypted password file (.epw) so your scripts
REM  never store plain-text passwords.
REM
REM  EPM Automate uses this file with the login command:
REM      epmautomate login <user> <password.epw> <url> <domain>
REM ============================================================

SETLOCAL

echo.
echo  EPM Automate - Encrypted Password File Generator
echo  -------------------------------------------------
echo.

SET /P EPM_PASSWORD=Enter your EPM Cloud password:
SET /P SECRET_KEY=Enter a secret key (any short string, e.g. "mykey123"):
SET /P OUTPUT_FILE=Enter output path [C:\epm\secure\password.epw]:

IF "%OUTPUT_FILE%"=="" SET OUTPUT_FILE=C:\epm\secure\password.epw

REM ---- Ensure output directory exists ----
FOR %%F IN ("%OUTPUT_FILE%") DO SET OUTPUT_DIR=%%~dpF
IF NOT EXIST "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM ---- Encrypt ----
call epmautomate encrypt "%EPM_PASSWORD%" "%SECRET_KEY%" "%OUTPUT_FILE%"

IF ERRORLEVEL 1 (
    echo.
    echo [ERROR] Encryption failed. Check that epmautomate is on your PATH.
    exit /b 1
)

echo.
echo [SUCCESS] Encrypted password file created at:
echo    %OUTPUT_FILE%
echo.
echo  Update config.env with:
echo    SET PASSWORD_FILE=%OUTPUT_FILE%
echo.

ENDLOCAL
exit /b 0
