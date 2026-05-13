# Scheduling Guide

Run toolkit scripts automatically using **Windows Task Scheduler**.

## Recommended Schedule

| Script | Frequency | Suggested Time | Notes |
|--------|-----------|----------------|-------|
| `01-daily-backup.bat` | Daily | 02:00 AM | After business hours |
| `02-lcm-export.bat` | Weekly | Sunday 23:00 | For version control |
| `03-data-load.bat` | Daily | 06:00 AM | After source close |
| `04-metadata-import.bat` | Monthly / on-demand | — | Trigger from change request |
| `05-cube-refresh.bat` | On-demand | — | After metadata import |

## Creating a Scheduled Task

### Via Task Scheduler GUI

1. Press `Win + R`, type `taskschd.msc`, hit Enter
2. **Create Task** (not "Create Basic Task" — you need the advanced options)
3. **General** tab:
   - **Name**: `EPM_Daily_Backup`
   - **Run whether user is logged on or not** ✅
   - **Run with highest privileges** ✅
   - **Configure for**: Windows 10 / Server 2016 (or your OS)
4. **Triggers** tab → **New**:
   - **Daily** at `2:00 AM`
   - Set "Stop the task if it runs longer than" to `2 hours` as a safety net
5. **Actions** tab → **New**:
   - **Action**: Start a program
   - **Program/script**: `C:\repos\oracle-epm-automate-toolkit\batch-scripts\01-daily-backup.bat`
   - **Start in**: `C:\repos\oracle-epm-automate-toolkit\batch-scripts`
6. **Conditions** tab:
   - Uncheck "Start the task only if the computer is on AC power" (for servers)
7. **Settings** tab:
   - **If the task fails, restart every**: 15 minutes, up to 3 attempts
8. Click **OK**, enter the service account password when prompted

### Via Command Line (PowerShell)

For consistency across machines, script the task creation:

```powershell
$action = New-ScheduledTaskAction `
    -Execute "C:\repos\oracle-epm-automate-toolkit\batch-scripts\01-daily-backup.bat" `
    -WorkingDirectory "C:\repos\oracle-epm-automate-toolkit\batch-scripts"

$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM

$principal = New-ScheduledTaskPrincipal `
    -UserId "DOMAIN\svc.epm" `
    -LogonType Password `
    -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)

Register-ScheduledTask `
    -TaskName "EPM_Daily_Backup" `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings
```

## Run Account Best Practices

- Use a **dedicated Windows service account** (e.g., `DOMAIN\svc.epm`) — not your personal account
- Grant that account NTFS read access to the `.epw` password file
- Grant it write access to `LOG_DIR`, `BACKUP_DIR`, etc.
- Disable interactive logon for that account
- Document the account in your operations runbook

## Monitoring Scheduled Tasks

### Check last run result

In Task Scheduler, the **Last Run Result** column shows the exit code:
- `0x0` — Success
- Anything else — Check the log file

### Common exit codes from toolkit scripts

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Configuration / argument error |
| `2` | Login failed |
| `3` | Primary operation failed (export/upload/etc.) |
| `4` | Secondary operation failed (download/import) |

### Email notification on failure

Add a second action to the scheduled task that runs only on failure:

```bat
powershell -Command "Send-MailMessage -From 'epm-alerts@example.com' -To 'you@example.com' -Subject 'EPM Daily Backup FAILED' -Body 'Check logs at C:\epm\logs' -SmtpServer 'smtp.example.com'"
```

Task Scheduler doesn't have conditional actions natively, so wrap the main script in a parent batch file:

```bat
@echo off
call 01-daily-backup.bat
IF ERRORLEVEL 1 (
    powershell -Command "Send-MailMessage -From '...' -To '...' -Subject 'EPM FAILED' -Body 'See logs' -SmtpServer '...'"
)
```

## Pitfalls to Avoid

- **Don't run scripts during maintenance windows.** Check Oracle's monthly maintenance schedule for your pod.
- **Don't schedule overlapping operations.** Backup → LCM export → data load should be sequential, not parallel.
- **Don't forget retention.** Disk fills up surprisingly fast with weekly snapshots; trust the cleanup logic in each script.
- **Don't test directly in PROD.** Always validate against DEV/TEST first.
