$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This uninstaller requires Administrator privileges. Please run as Administrator."
    Exit
}

$installDir = "C:\Program Files\Cyberarms Intrusion Detection"
$serviceName = "Cyberarms Intrusion Detection"
$binPath = "$installDir\CyberarmsIdsService.exe"

# 1. Stop and uninstall service
$existingService = Get-Service $serviceName -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Host "Stopping Cyberarms service..."
    Stop-Service $serviceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    Write-Host "Uninstalling Cyberarms service..."
    $installUtil = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe"
    if (Test-Path $installUtil -and (Test-Path $binPath)) {
        & $installUtil /u $binPath | Out-Null
    } else {
        & sc.exe delete $serviceName | Out-Null
    }
    Start-Sleep -Seconds 1
}

# 2. Delete Shortcuts
Write-Host "Removing shortcuts..."
$desktopPath = [System.Environment]::GetFolderPath("Desktop")
$desktopLnk = "$desktopPath\Cyberarms Intrusion Detection.lnk"
if (Test-Path $desktopLnk) {
    Remove-Item $desktopLnk -Force
}

$startMenuPath = [System.Environment]::GetFolderPath("CommonPrograms")
$cyberarmsProgramsFolder = "$startMenuPath\Cyberarms Intrusion Detection"
if (Test-Path $cyberarmsProgramsFolder) {
    Remove-Item $cyberarmsProgramsFolder -Recurse -Force
}

# 3. Delete event log source and log
Write-Host "Removing Event Log source..."
try {
    if ([System.Diagnostics.EventLog]::SourceExists("Cyberarms Intrusion Detection")) {
        [System.Diagnostics.EventLog]::DeleteEventSource("Cyberarms Intrusion Detection")
    }
    if ([System.Diagnostics.EventLog]::Exists("Cyberarms")) {
        [System.Diagnostics.EventLog]::Delete("Cyberarms")
    }
} catch {
    Write-Warning "Could not clean up Event Log source/log: $_"
}

# 4. Delete deployed files
Write-Host "Removing application files from $installDir..."
if (Test-Path $installDir) {
    Remove-Item $installDir -Recurse -Force
}

Write-Host "`nUninstallation Completed Successfully!"
