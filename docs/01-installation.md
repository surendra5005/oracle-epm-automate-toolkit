# Installation Guide

This guide covers installing the EPM Automate CLI on Windows so the toolkit scripts can run.

## Prerequisites

- Windows 10/11 or Windows Server 2016+
- Java 8 or later (the EPM Automate installer includes a bundled JRE on most recent versions; check Oracle's docs)
- Local administrator rights for installation
- Oracle EPM Cloud subscription with a service account

## Step 1: Download EPM Automate

1. Log in to your Oracle EPM Cloud instance as a Service Administrator
2. From the home page, click your user icon (top right) → **Downloads**
3. Under **EPM Automate**, click **Download for Windows**
4. Save the installer (`EPMAutomate.exe`) locally

> **Tip**: Always download EPM Automate from your own pod rather than a generic Oracle link. Oracle releases updates roughly monthly, and using the version that matches your pod ensures compatibility.

## Step 2: Install

1. Right-click `EPMAutomate.exe` → **Run as administrator**
2. Accept the default install path (`C:\Oracle\EPM Automate`) or choose your own
3. Complete the installer

## Step 3: Add EPM Automate to PATH

This lets you run `epmautomate` from any command prompt.

1. Press `Win + R`, type `sysdm.cpl`, hit Enter
2. **Advanced** tab → **Environment Variables**
3. Under **System variables**, find `Path` → **Edit**
4. **New** → add: `C:\Oracle\EPM Automate\bin`
5. Click **OK** on all dialogs

## Step 4: Verify the Installation

Open a new command prompt and run:

```bash
epmautomate -v
```

You should see a version number printed. If you get "command not recognized", the PATH wasn't picked up — close and reopen the command prompt, or restart Windows.

## Step 5: Test Login

```bash
epmautomate login service.account@example.com YourPassword https://your-pod.oraclecloud.com your-identity-domain
```

If successful you'll see `EPM Automate session started`. Run `epmautomate logout` to disconnect.

> Once login works, do **not** keep using plain-text passwords. Move on to the [Configuration Guide](02-configuration.md) to set up encrypted credentials.

## Updating EPM Automate

Oracle releases new versions roughly monthly. To update:

1. Download the latest installer from your pod (Step 1 above)
2. Run the installer — it'll upgrade the existing installation
3. Verify with `epmautomate -v`

Outdated clients can fail unexpectedly when Oracle updates the cloud side, so keep this on a quarterly maintenance schedule.

## Common Installation Issues

| Issue | Fix |
|-------|-----|
| `'epmautomate' is not recognized` | PATH not set — see Step 3, then restart command prompt |
| Java errors at startup | Reinstall using the installer that bundles JRE, or set `JAVA_HOME` |
| SSL/certificate errors | Corporate firewall — work with IT to whitelist `*.oraclecloud.com` |
| Permission denied on install | Re-run installer as administrator |
