$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This installer requires Administrator privileges. Please run as Administrator."
    Exit
}

$installDir = "C:\Program Files\Cyberarms Intrusion Detection"
$serviceName = "Cyberarms Intrusion Detection"
$displayName = "Cyberarms Intrusion Detection"
$binPath = "$installDir\CyberarmsIdsService.exe"

# 1. Stop and uninstall existing service if present
$existingService = Get-Service $serviceName -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Host "Stopping existing Cyberarms service..."
    Stop-Service $serviceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "Uninstalling existing Cyberarms service..."
    $installUtil = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe"
    if (Test-Path $installUtil) {
        & $installUtil /u "$installDir\CyberarmsIdsService.exe" | Out-Null
    } else {
        & sc.exe delete $serviceName | Out-Null
    }
    Start-Sleep -Seconds 1
}

# 2. Copy files to Program Files
Write-Host "Deploying files to $installDir..."
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
}
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Copy-Item -Path "$scriptPath\bin\*" -Destination $installDir -Recurse -Force

# 3. Create Windows Event Log source if missing
Write-Host "Registering Event Log source..."
try {
    if (-not [System.Diagnostics.EventLog]::SourceExists("Cyberarms Intrusion Detection")) {
        [System.Diagnostics.EventLog]::CreateEventSource("Cyberarms Intrusion Detection", "Cyberarms")
    }
} catch {
    Write-Warning "Could not register Event Log source. Typically occurs if it is already partially registered: $_"
}

# 4. Register background service
Write-Host "Registering background service..."
$installUtil = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe"
if (Test-Path $installUtil) {
    & $installUtil $binPath | Out-Null
} else {
    New-Service -Name $serviceName -BinaryPathName $binPath -DisplayName $displayName -StartupType Automatic | Out-Null
}

# 5. Start the service
Write-Host "Starting background service..."
Start-Service $serviceName -ErrorAction SilentlyContinue

# 6. Create Desktop and Start Menu Shortcuts
Write-Host "Creating shortcuts..."
try {
    $wshShell = New-Object -ComObject WScript.Shell
    
    # Desktop
    $desktopPath = [System.Environment]::GetFolderPath("Desktop")
    $desktopShortcut = $wshShell.CreateShortcut("$desktopPath\Cyberarms Intrusion Detection.lnk")
    $desktopShortcut.TargetPath = "$installDir\IntrusionDetectionAdmin.exe"
    $desktopShortcut.WorkingDirectory = $installDir
    $desktopShortcut.Description = "Cyberarms Intrusion Detection Admin Panel"
    $desktopShortcut.IconLocation = "$installDir\IntrusionDetectionAdmin.exe, 0"
    $desktopShortcut.Save()

    # Start Menu
    $startMenuPath = [System.Environment]::GetFolderPath("CommonPrograms")
    $cyberarmsProgramsFolder = "$startMenuPath\Cyberarms Intrusion Detection"
    if (-not (Test-Path $cyberarmsProgramsFolder)) {
        New-Item -ItemType Directory -Path $cyberarmsProgramsFolder | Out-Null
    }
    $startShortcut = $wshShell.CreateShortcut("$cyberarmsProgramsFolder\Cyberarms Intrusion Detection.lnk")
    $startShortcut.TargetPath = "$installDir\IntrusionDetectionAdmin.exe"
    $startShortcut.WorkingDirectory = $installDir
    $startShortcut.Description = "Cyberarms Intrusion Detection Admin Panel"
    $startShortcut.IconLocation = "$installDir\IntrusionDetectionAdmin.exe, 0"
    $startShortcut.Save()
} catch {
    Write-Warning "Failed to create shortcuts: $_"
}

Write-Host "`nInstallation Completed Successfully!"
Write-Host "The Cyberarms background service is now running."
