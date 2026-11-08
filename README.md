# PIA to qBittorrent Port Sync

Automatically synchronizes qBittorrent's listening port with the port assigned by **Private Internet Access (PIA)** VPN port forwarding.

This PowerShell script retrieves the active forwarded port from PIA using `piactl.exe`, authenticates with the qBittorrent WebUI, and updates qBittorrent's listening port through its Web API.

Designed to run unattended in the background using Windows Task Scheduler.

## Features

- Retrieves the active forwarded port directly from PIA.
- Automatically authenticates with the qBittorrent WebUI.
- Updates qBittorrent's listening port through the Web API.
- Uses session-based authentication and cookie management.
- Handles modern and legacy qBittorrent login responses.
- Checks whether PIA port forwarding is active before making changes.
- Supports unattended execution through Windows Task Scheduler.
- No external PowerShell modules or dependencies required.

## Requirements

| Requirement | Details |
|---|---|
| Operating system | Windows 10 / Windows 11 |
| VPN | Private Internet Access |
| PIA CLI | `piactl.exe` |
| Torrent client | qBittorrent |
| WebUI | Enabled and accessible |
| PowerShell | Windows PowerShell 5.1 or later |

Both PIA and qBittorrent must be running and accessible to the Windows account executing the script.

## Configuration

Open `update_qbittorrent_port.ps1` and configure the following variables:

```powershell
# Path to PIA's command-line tool
$piaPath = "C:\Program Files\Private Internet Access\piactl.exe"

# qBittorrent WebUI configuration
$qbtUrl = "http://{qbittorrent web UI address}:9092"
$qbtUsername = "webUI username"
$qbtPassword = "webUI_password"
```

Update the WebUI address, port, username, and password to match your installation.

**Security note:** The WebUI password is stored in plaintext in the script. Restrict access to the script and avoid committing credentials to a public repository. Consider using an environment-specific configuration or Windows DPAPI-protected credentials for deployments requiring stronger credential protection.

## How It Works

The script performs the following operations:

1. **Retrieve PIA port:** Executes `piactl.exe get portforward` to retrieve the currently assigned forwarded port.
2. **Validate port:** Checks that PIA returned a valid five-digit port number.
3. **Authenticate:** Sends a login request to the qBittorrent WebUI API.
4. **Establish session:** Maintains the authenticated session using PowerShell's `WebRequestSession`.
5. **Update port:** Sends the new listening port to qBittorrent using the `setPreferences` API endpoint.
6. **Report status:** Outputs whether the synchronization succeeded or encountered an error.

If PIA is disconnected or port forwarding is unavailable, the script exits without modifying qBittorrent.

## Manual Execution

Run the script from PowerShell:

```powershell
.\update_qbittorrent_port.ps1
```

Successful execution produces output similar to:

```text
Successfully updated qBittorrent port to 12345
```

The port shown is illustrative.

## Windows Task Scheduler

For automatic synchronization, configure Windows Task Scheduler to execute the script at user logon and every 15 minutes thereafter.

### General

| Setting | Value |
|---|---|
| Name | PIA - qBittorrent Port Sync |
| Run whether user is logged on or not | No |
| Run only when user is logged on | Yes |

Using the interactive user session ensures the task runs under the same Windows account as PIA and qBittorrent.

### Triggers

Create two triggers.

**Trigger 1 — User logon**

| Setting | Value |
|---|---|
| Begin the task | At log on |
| Specific user | Your Windows account |
| Enabled | Yes |

**Trigger 2 — Recurring synchronization**

| Setting | Value |
|---|---|
| Begin the task | On a schedule |
| Schedule | Daily |
| Repeat task every | 15 minutes |
| For a duration of | Indefinitely |
| Enabled | Yes |

This provides an initial synchronization at logon, followed by recurring synchronization every 15 minutes.

### Actions

Create the following action:

| Setting | Value |
|---|---|
| Action | Start a program |
| Program/script | `powershell.exe` |
| Arguments | `-NoProfile -ExecutionPolicy Bypass -File "C:\{path_to_script}\update_qbittorrent_port.ps1"` |
| Start in | `C:\` |

Adjust the script path if it is stored elsewhere.

### Settings

Recommended configuration:

- Allow task to be run on demand: Enabled.
- Run task as soon as possible after a scheduled start is missed: Enabled.
- If the task is already running: Do not start a new instance.

## API Endpoints

The script uses two qBittorrent Web API endpoints:

| Endpoint | Method | Purpose |
|---|---|---|
| `/api/v2/auth/login` | POST | Authenticate with the WebUI |
| `/api/v2/app/setPreferences` | POST | Update qBittorrent preferences |

The listening port is updated using the `listen_port` preference.

## Troubleshooting

**Unable to connect to the WebUI**

- Confirm qBittorrent is running.
- Verify the WebUI address and port.
- Confirm the configured IP address is reachable.
- Ensure the WebUI is listening on the expected network interface.

**Authentication failed**

- Verify the WebUI username and password.
- Confirm WebUI authentication is enabled.
- Check that the WebUI address and Referer header match.

**PIA port forwarding is inactive**

Run the following command:

```powershell
& "C:\Program Files\Private Internet Access\piactl.exe" get portforward
```

Confirm that PIA is connected to a server supporting port forwarding.

**Scheduled task does not execute successfully**

- Confirm the task runs under the Windows account that owns the PIA and qBittorrent sessions.
- Verify that the script path is correct.
- Check the Task Scheduler Last Run Result.
- Test the script manually under the same account.

## Limitations

- Requires an active PIA connection with port forwarding support.
- Requires qBittorrent WebUI access.
- Designed for Windows environments.
- Synchronization occurs at the configured interval rather than continuously.
- The script updates qBittorrent's listening port but does not independently verify external connectivity or incoming peer reachability.
