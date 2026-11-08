
# PIA -> qBittorrent port synchronization

# Configuration
$piaPath = "C:\Program Files\Private Internet Access\piactl.exe"
$qbtUrl = "http://QBITTORRENT ADDRESS:WEBUI_PORT"
$qbtUsername = "QBITTORRENT WEBUI USERNAME"
$qbtPassword = "QBITTORRENT WEBUI PASSWORD"

try {
    # Get PIA forwarded port
    $piaPort = (& $piaPath get portforward).Trim()

    if ($piaPort -notmatch "^\d{5}$") {
        Write-Output "PIA port forwarding inactive: $piaPort"
        exit
    }

    # Create authenticated session
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    $headers = @{
        Referer = "$qbtUrl/"
    }

    # Login
    $login = Invoke-WebRequest `
        -Uri "$qbtUrl/api/v2/auth/login" `
        -Method POST `
        -Body @{
            username = $qbtUsername
            password = $qbtPassword
        } `
        -Headers $headers `
        -WebSession $session `
        -UseBasicParsing

    if ($login.Content -ne "Ok." -and $login.StatusCode -ne 204) {
        throw "qBittorrent login failed."
    }

    # Update listening port
    $body = @{
        json = (@{ listen_port = [int]$piaPort } | ConvertTo-Json -Compress)
    }

    Invoke-WebRequest `
        -Uri "$qbtUrl/api/v2/app/setPreferences" `
        -Method POST `
        -Body $body `
        -Headers $headers `
        -WebSession $session `
        -UseBasicParsing | Out-Null

    Write-Output "Successfully updated qBittorrent port to $piaPort"

}
catch {
    Write-Error "Port synchronization failed: $($_.Exception.Message)"
}
