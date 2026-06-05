$baseDir = "c:\Cyberarms\Cyberarms-master"
$packageDir = "$baseDir\ReleasePackage"
$binDir = "$packageDir\bin"
$pluginsDir = "$binDir\Plugins"

# Create clean packaging directories
if (Test-Path $packageDir) {
    Remove-Item $packageDir -Recurse -Force
}
New-Item -ItemType Directory -Path $packageDir | Out-Null
New-Item -ItemType Directory -Path $binDir | Out-Null
New-Item -ItemType Directory -Path $pluginsDir | Out-Null

function Get-SourcePath($project, $file) {
    $x86Path = "$baseDir\$project\bin\x86\Release\$file"
    if (Test-Path $x86Path) { return $x86Path }
    $anyCpuPath = "$baseDir\$project\bin\Release\$file"
    if (Test-Path $anyCpuPath) { return $anyCpuPath }
    return "$baseDir\$project\bin\Release 64-bit edition\$file"
}

# Copy main service binaries and dependencies
Copy-Item (Get-SourcePath "Cyberarms.IntrusionDetection.Service" "CyberarmsIdsService.exe") -Destination $binDir
$svcConfig = Get-SourcePath "Cyberarms.IntrusionDetection.Service" "CyberarmsIdsService.exe.config"
if (Test-Path $svcConfig) {
    Copy-Item $svcConfig -Destination $binDir
} else {
    Copy-Item "$baseDir\Cyberarms.IntrusionDetection.Service\app.config" -Destination "$binDir\CyberarmsIdsService.exe.config"
}
Copy-Item (Get-SourcePath "Cyberarms.IntrusionDetection.Service" "Cyberarms.IntrusionDetection.Api.dll") -Destination $binDir
Copy-Item (Get-SourcePath "Cyberarms.IntrusionDetection.Service" "Cyberarms.IntrusionDetection.Shared.dll") -Destination $binDir

# Copy Admin console
Copy-Item (Get-SourcePath "Cyberarms.IDDS.Management" "iddsadmin.exe") -Destination $binDir
Copy-Item "$baseDir\Cyberarms.IDDS.Management\app.config" -Destination "$binDir\iddsadmin.exe.config" -ErrorAction SilentlyContinue

# Copy GUI Admin panel
Copy-Item (Get-SourcePath "Cyberarms.IntrusionDetection.Admin" "IntrusionDetectionAdmin.exe") -Destination $binDir
Copy-Item (Get-SourcePath "Cyberarms.IntrusionDetection.Admin" "IntrusionDetectionAdmin.exe.config") -Destination $binDir -ErrorAction SilentlyContinue

# Copy CLI tool
Copy-Item (Get-SourcePath "Cyberarms.IntrusionDetection.Cmd" "CyberarmsIdsCmd.exe") -Destination $binDir
Copy-Item "$baseDir\Cyberarms.IntrusionDetection.Cmd\app.config" -Destination "$binDir\CyberarmsIdsCmd.exe.config" -ErrorAction SilentlyContinue

# Copy SQLite assemblies
Copy-Item "$baseDir\Dependencies\SQLite\System.Data.SQLite.dll" -Destination $binDir
Copy-Item "$baseDir\Dependencies\SQLite\SQLite.Interop.dll" -Destination $binDir

# Copy WebSecurity library
Copy-Item "$baseDir\Cyberarms.WebSecurity\bin\Release\Cyberarms.WebSecurity.dll" -Destination $binDir

# Copy Event Log Cleaner utility
Copy-Item "$baseDir\EventLogCleaner\bin\Release\EventLogCleaner.exe" -Destination $binDir -ErrorAction SilentlyContinue

# Copy Agent Plugins to the Plugins folder
$agents = @(
    "Bind9", "FileMaker", "FtpServer", "MailServer", "MySql", "Smtp", "SqlServer", "TerminalServer", "WebSecurity"
)
foreach ($agent in $agents) {
    $agentProject = "Cyberarms.Agents.$agent"
    $agentFile = "$agentProject.dll"
    $sourcePath = Get-SourcePath $agentProject $agentFile
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath -Destination $pluginsDir
    } else {
        Write-Warning "Could not find built assembly for agent $agent at: $sourcePath"
    }
}
Copy-Item (Get-SourcePath "Cyberarms.IntrusionDetection.Base" "Cyberarms.IntrusionDetection.Base.Plugins.dll") -Destination $pluginsDir


# Copy installer scripts and batch files
Copy-Item "$baseDir\install.ps1" -Destination $packageDir -ErrorAction SilentlyContinue
Copy-Item "$baseDir\uninstall.ps1" -Destination $packageDir -ErrorAction SilentlyContinue
Copy-Item "$baseDir\install.bat" -Destination $packageDir -ErrorAction SilentlyContinue
Copy-Item "$baseDir\uninstall.bat" -Destination $packageDir -ErrorAction SilentlyContinue

# Create a README
$readmeText = @"
============================================================
Cyberarms Intrusion Detection and Prevention - Release 2.2.0
============================================================

This package contains the Cyberarms background service, administration
console, and command line tools configured to use Null Routing based blocking.

Prerequisites:
- Windows Server 2008 R2, 2012, 2016, 2019, 2022, or 2025.
- .NET Framework 4.8 or later installed.
- Administrator privileges on the machine.

Installation:
1. Right-click on "install.bat" and select "Run as administrator".
2. Confirm the UAC prompt.
3. The installer will copy files to C:\Program Files\Cyberarms Intrusion Detection,
   register and start the background service, and create desktop shortcuts.

Uninstallation:
1. Right-click on "uninstall.bat" and select "Run as administrator".
2. Confirm the UAC prompt.
3. The uninstaller will stop and remove the background service and clean up
   all deployed files and shortcuts.
"@
$readmeText | Out-File -FilePath "$packageDir\README.txt" -Encoding utf8

# Archive to zip
$zipPath = "$baseDir\Cyberarms-Release-2.2.0.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($packageDir, $zipPath)

Write-Host "Release package successfully created at: $zipPath"
