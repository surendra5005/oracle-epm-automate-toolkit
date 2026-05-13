# Troubleshooting Guide

Common errors when running toolkit scripts and how to fix them.

## Login Errors

### `EPMAT-7002: Unable to login`

**Causes**:
- Incorrect username, password, URL, or identity domain
- Service account locked out (too many failed attempts)
- Service account password expired
- Pod URL changed (Oracle occasionally migrates pods)

**Fix**:
1. Verify all four login parameters by attempting an interactive login in the EPM Cloud UI
2. Check that the service account is unlocked and active
3. Re-create the `.epw` file if the password was rotated
4. Confirm the pod URL is current (check the URL when logged into EPM Cloud UI)

### `EPMAT-1002: Invalid password file`

**Cause**: The encrypted password file was created with one version of EPM Automate and is being used with a much older or newer version, OR the file is corrupted.

**Fix**: Re-create the `.epw` file using the current EPM Automate version:

```bash
config-templates\encrypt-password.bat
```

## Snapshot / Backup Errors

### `EPMAT-7016: Snapshot already exists`

**Cause**: A previous `exportSnapshot` produced a file with the same name that wasn't cleaned up.

**Fix**: Delete the existing snapshot from the cloud before re-exporting:

```bash
epmautomate deleteFile "Artifact Snapshot"
```

Then re-run the backup script.

### Download is empty (0 KB)

**Causes**:
- The `exportSnapshot` command exited too quickly and the snapshot wasn't ready
- Pod is in maintenance mode
- Service account lacks Service Administrator role

**Fix**:
1. Run `epmautomate listFiles` to confirm the snapshot exists
2. Check Oracle's maintenance schedule
3. Verify the service account role assignments

## Data Load Errors

### `EPMAT-8002: Rule does not exist`

**Cause**: The DM rule name passed to `runDataRule` doesn't match what's in EPM Cloud.

**Fix**: Names are case-sensitive. Confirm the exact name in **Data Management → Workflow → Data Load Rule**.

### Data loaded but values are zero

**Causes**:
- Import format mismatch (column order in CSV doesn't match the DM import format)
- POV (Point of View) mismatch — period, scenario, or version doesn't match data
- `IMPORT_MODE` set to `RECALCULATE` when no data exists yet

**Fix**:
1. Open Data Management → **Workbench** and review the load
2. Check the **Import Format** against the actual CSV column layout
3. Verify the POV parameters in the script match the data in the file

### `EPMAT-7263: Job is still running`

**Cause**: A previous DM rule run is still executing.

**Fix**: Either wait for it to complete, or cancel it via the UI: **Application → Jobs → cancel**.

## Metadata Import Errors

### `EPMAT-7261: Validation failed`

**Cause**: The metadata file has structural issues — duplicate members, parent references that don't exist, invalid characters in names, or missing required properties.

**Fix**:
1. Download the validation report: `epmautomate downloadFile <jobname>.log`
2. Open it; the report lists each error by row number
3. Fix the CSV/ZIP file and re-upload

### Cube structure didn't update after import

**Cause**: Metadata import alone doesn't make changes effective — you must refresh the cube.

**Fix**: Run `05-cube-refresh.bat`.

## File Upload / Download Errors

### `EPMAT-1009: File already exists`

**Cause**: A file with the same name exists in the cloud inbox.

**Fix**: Delete the existing one first:

```bash
epmautomate deleteFile "inbox/yourfile.csv"
```

Or pass `-f` flag if supported by your EPM Automate version.

### `EPMAT-9001: Connection timed out`

**Causes**:
- Network connectivity issue between the Windows machine and Oracle Cloud
- Corporate proxy blocking the connection
- Large file (>500 MB) on a slow connection

**Fix**:
1. Verify connectivity: `ping your-pod.oraclecloud.com`
2. Configure EPM Automate to use a proxy if needed:
   ```bash
   epmautomate setproxy proxyserver.example.com 8080 proxyuser proxypwd
   ```
3. For very large files, increase the timeout or split into smaller files

## Cube Refresh Errors

### `EPMAT-7263: Another refresh is already running`

**Fix**: Wait for the existing refresh to complete. Check via **Application → Jobs**.

### Cube refresh succeeds but Smart View shows old data

**Cause**: Smart View caches dimension structure locally.

**Fix**: In Excel, click **Smart View → Refresh** with the connection selected, or restart Excel. End users may need to do the same.

## General Debugging Approach

When a script fails:

1. **Open the log file** in `C:\epm\logs\` — the full EPM Automate output is there
2. **Search the error code** — Oracle's documentation lists every `EPMAT-####` code with explanations
3. **Reproduce manually** — run the same commands one at a time in a command prompt to isolate the failing step
4. **Check Oracle status** — visit your pod's URL; sometimes Oracle is in unplanned maintenance
5. **Check the job in EPM Cloud UI** — under **Application → Jobs**, the cloud-side view often has more detail than the CLI output

## Useful EPM Automate Diagnostic Commands

| Command | Purpose |
|---------|---------|
| `epmautomate -v` | Show CLI version |
| `epmautomate help` | List all commands |
| `epmautomate help <command>` | Show usage for a specific command |
| `epmautomate listFiles` | List all files in the cloud inbox/outbox |
| `epmautomate feedback` | Generate diagnostic info for Oracle Support |

## Getting Help

- [Oracle EPM Automate Reference](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/cepma/) — official command reference
- Oracle Support — raise an SR for cloud-side issues
- Oracle EPM community forums on Oracle Cloud Customer Connect
