# Configuration Guide

After installing EPM Automate, configure the toolkit for your environment.

## Step 1: Create `config.env`

In the repo root, copy the template:

```bash
copy config-templates\config.env.template config.env
```

Open `config.env` in a text editor and update each variable:

| Variable | Example | Notes |
|----------|---------|-------|
| `EPM_URL` | `https://yourpod-yourdomain.epm.dataregion.oraclecloud.com` | Your EPM Cloud pod URL (no trailing slash) |
| `EPM_USER` | `auto.svc@example.com` | Service account email |
| `EPM_DOMAIN` | `yourdomain` | Identity domain (the part after `-` in older URLs, or your IDCS domain) |
| `PASSWORD_FILE` | `C:\epm\secure\password.epw` | Path to encrypted password file (created in Step 2) |
| `LOG_DIR` | `C:\epm\logs` | Where script logs land |
| `BACKUP_DIR` | `C:\epm\backups` | Where daily snapshots are stored |
| `LCM_DIR` | `C:\epm\lcm-exports` | Where LCM exports are stored |
| `DATA_DIR` | `C:\epm\data-files` | Source folder for data load files |
| `METADATA_DIR` | `C:\epm\metadata-files` | Source folder for metadata files |
| `BACKUP_RETENTION_DAYS` | `14` | Older daily backups deleted automatically |
| `SNAPSHOT_NAME` | `Artifact Snapshot` | Default name of the daily snapshot in EPM Cloud |

> `config.env` is in `.gitignore` — it should **never** be committed.

## Step 2: Create the Encrypted Password File

Plain-text passwords in scripts are a security risk. EPM Automate provides an `encrypt` command to produce a `.epw` file.

Run the helper:

```bash
cd config-templates
encrypt-password.bat
```

It will prompt for:
1. Your EPM Cloud password
2. A secret key (any short string — this just salts the encryption)
3. Output path (default: `C:\epm\secure\password.epw`)

The resulting `.epw` file is used by all toolkit scripts. Protect this file with NTFS permissions so only the service account that runs the scripts can read it.

## Step 3: Create Required Folders

Create the folders referenced in `config.env`:

```bash
mkdir C:\epm\logs
mkdir C:\epm\backups
mkdir C:\epm\lcm-exports
mkdir C:\epm\data-files
mkdir C:\epm\metadata-files
mkdir C:\epm\secure
```

## Step 4: Test the First Script

Run a backup manually to confirm everything works:

```bash
cd batch-scripts
01-daily-backup.bat
```

Check `C:\epm\logs\` for the log file. A successful run ends with:

```
[SUCCESS] Backup complete: C:\epm\backups\backup_YYYYMMDD_HHMM.zip
```

If you see an error, open the log file — it has the full EPM Automate output.

## Step 5: Plan Your Schedules

Once you can run each script manually, automate them via Windows Task Scheduler. See [Scheduling Guide](03-scheduling.md).

## Multi-Environment Setup

If you support DEV / TEST / PROD environments, create separate config files:

```
config.dev.env
config.test.env
config.prod.env
```

Modify the script header to source a specific file:

```bat
call "%~dp0..\config.%ENV%.env"
```

Then set `ENV=prod` before running.
