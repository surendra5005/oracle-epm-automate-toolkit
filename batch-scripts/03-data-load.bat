@echo off
REM ============================================================
REM  03 - Data Load Script
REM ============================================================
REM  Purpose : Uploads a data file to the EPM Cloud inbox and
REM            runs a Data Management (DM) integration job to
REM            load it into the target application.
REM  Schedule: Daily after source system close (suggested 6:00 AM)
REM
REM  Pre-req : 1. A DM rule must be configured in the EPM Cloud
REM               UI with the import format and target POV.
REM            2. The data file must follow the format expected
REM               by that DM rule.
REM
REM  Usage   : 03-data-load.bat <DataFileName> <DM_Rule_Name>
REM  Example : 03-data-load.bat actuals_oct.csv DM_Load_Actuals
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM ---- Load configuration ----
IF NOT EXIST "%~dp0..\config.env" (
    echo [ERROR] config.env not found.
    exit /b 1
)
call "%~dp0..\config.env"

REM ---- Validate arguments ----
IF "%~1"=="" (
    echo [ERROR] Usage: 03-data-load.bat ^<DataFileName^> ^<DM_Rule_Name^>
    echo         Example: 03-data-load.bat actuals_oct.csv DM_Load_Actuals
    exit /b 1
)
IF "%~2"=="" (
    echo [ERROR] DM rule name required as second argument.
    exit /b 1
)

SET DATA_FILE_NAME=%~1
SET DM_RULE_NAME=%~2
SET LOCAL_DATA_FILE=%DATA_DIR%\%DATA_FILE_NAME%

REM ---- Verify the file exists locally ----
IF NOT EXIST "%LOCAL_DATA_FILE%" (
    echo [ERROR] Data file not found: %LOCAL_DATA_FILE%
    exit /b 1
)

REM ---- Build timestamp ----
FOR /F "tokens=2 delims==" %%I IN ('"wmic os get localdatetime /value"') DO SET DT=%%I
SET TIMESTAMP=%DT:~0,8%_%DT:~8,4%
SET LOG_FILE=%LOG_DIR%\03-data-load_%TIMESTAMP%.log

IF NOT EXIST "%LOG_DIR%" mkdir "%LOG_DIR%"

REM ---- Start logging ----
echo ============================================================ > "%LOG_FILE%"
echo  Data Load - Started %DATE% %TIME%                           >> "%LOG_FILE%"
echo  File    : %DATA_FILE_NAME%                                  >> "%LOG_FILE%"
echo  DM Rule : %DM_RULE_NAME%                                    >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

REM ---- Step 1: Login ----
echo [%TIME%] Logging in                                          >> "%LOG_FILE%"
call epmautomate login %EPM_USER% "%PASSWORD_FILE%" %EPM_URL% %EPM_DOMAIN% >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Login failed. See %LOG_FILE%
    exit /b 2
)

REM ---- Step 2: Upload file to inbox ----
echo [%TIME%] Uploading file to EPM Cloud inbox                   >> "%LOG_FILE%"
call epmautomate uploadFile "%LOCAL_DATA_FILE%" inbox >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] File upload failed. See %LOG_FILE%
    call epmautomate logout >> "%LOG_FILE%" 2>&1
    exit /b 3
)

REM ---- Step 3: Run Data Management rule ----
REM  Parameters (replace per your DM rule):
REM    PERIOD_START / PERIOD_END : the period range
REM    IMPORT_MODE               : REPLACE | APPEND | RECALCULATE
REM    EXPORT_MODE               : STORE_DATA | ADD_DATA | SUBTRACT_DATA
REM    FILE_NAME                 : the uploaded file
echo [%TIME%] Running DM rule: %DM_RULE_NAME%                     >> "%LOG_FILE%"
call epmautomate runDataRule %DM_RULE_NAME% Oct-26 Oct-26 REPLACE STORE_DATA "inbox/%DATA_FILE_NAME%" >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Data load failed. See %LOG_FILE%
    call epmautomate logout >> "%LOG_FILE%" 2>&1
    exit /b 4
)

REM ---- Step 4: Logout ----
call epmautomate logout >> "%LOG_FILE%" 2>&1

echo ============================================================ >> "%LOG_FILE%"
echo  Data Load - Completed %DATE% %TIME%                         >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

echo [SUCCESS] Data load complete.
echo [INFO]    Log: %LOG_FILE%

ENDLOCAL
exit /b 0
