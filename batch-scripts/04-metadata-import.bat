@echo off
REM ============================================================
REM  04 - Metadata Import Script
REM ============================================================
REM  Purpose : Uploads a metadata CSV/ZIP file and runs a
REM            metadata import job to update dimension members.
REM            Typically used to refresh Entity, Account, or
REM            custom dimensions from a master source.
REM  Schedule: Monthly or on-demand
REM
REM  Pre-req : A metadata import job must exist in EPM Cloud
REM            (Application > Overview > Actions > Import
REM            Metadata > Create). The job name is passed as an
REM            argument.
REM
REM  Usage   : 04-metadata-import.bat <FileName> <JobName>
REM  Example : 04-metadata-import.bat entity_dim.zip Import_Entity_Job
REM
REM  Note    : This script does NOT refresh the cube. Run
REM            05-cube-refresh.bat afterwards to apply changes.
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
    echo [ERROR] Usage: 04-metadata-import.bat ^<FileName^> ^<JobName^>
    echo         Example: 04-metadata-import.bat entity_dim.zip Import_Entity_Job
    exit /b 1
)
IF "%~2"=="" (
    echo [ERROR] Job name required as second argument.
    exit /b 1
)

SET META_FILE_NAME=%~1
SET META_JOB_NAME=%~2
SET LOCAL_META_FILE=%METADATA_DIR%\%META_FILE_NAME%

REM ---- Verify the file exists ----
IF NOT EXIST "%LOCAL_META_FILE%" (
    echo [ERROR] Metadata file not found: %LOCAL_META_FILE%
    exit /b 1
)

REM ---- Build timestamp ----
FOR /F "tokens=2 delims==" %%I IN ('"wmic os get localdatetime /value"') DO SET DT=%%I
SET TIMESTAMP=%DT:~0,8%_%DT:~8,4%
SET LOG_FILE=%LOG_DIR%\04-metadata-import_%TIMESTAMP%.log

IF NOT EXIST "%LOG_DIR%" mkdir "%LOG_DIR%"

REM ---- Start logging ----
echo ============================================================ > "%LOG_FILE%"
echo  Metadata Import - Started %DATE% %TIME%                     >> "%LOG_FILE%"
echo  File : %META_FILE_NAME%                                     >> "%LOG_FILE%"
echo  Job  : %META_JOB_NAME%                                      >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

REM ---- Step 1: Login ----
echo [%TIME%] Logging in                                          >> "%LOG_FILE%"
call epmautomate login %EPM_USER% "%PASSWORD_FILE%" %EPM_URL% %EPM_DOMAIN% >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Login failed. See %LOG_FILE%
    exit /b 2
)

REM ---- Step 2: Upload metadata file ----
echo [%TIME%] Uploading metadata file                             >> "%LOG_FILE%"
call epmautomate uploadFile "%LOCAL_META_FILE%" >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Upload failed. See %LOG_FILE%
    call epmautomate logout >> "%LOG_FILE%" 2>&1
    exit /b 3
)

REM ---- Step 3: Run metadata import job ----
echo [%TIME%] Running metadata import job                         >> "%LOG_FILE%"
call epmautomate importMetadata "%META_JOB_NAME%" "%META_FILE_NAME%" >> "%LOG_FILE%" 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Metadata import failed. See %LOG_FILE%
    call epmautomate logout >> "%LOG_FILE%" 2>&1
    exit /b 4
)

REM ---- Step 4: Logout ----
call epmautomate logout >> "%LOG_FILE%" 2>&1

echo ============================================================ >> "%LOG_FILE%"
echo  Metadata Import - Completed %DATE% %TIME%                   >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

echo [SUCCESS] Metadata import complete.
echo [INFO]    Log: %LOG_FILE%
echo [NEXT]    Run 05-cube-refresh.bat to apply changes to the cube.

ENDLOCAL
exit /b 0
