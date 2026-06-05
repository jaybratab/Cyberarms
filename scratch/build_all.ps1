$baseDir = "c:\Cyberarms\Cyberarms-master"
$msbuild = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"

$projects = @(
    "Cyberarms.IntrusionDetection.Api\Cyberarms.IntrusionDetection.Api.csproj",
    "Cyberarms.IntrusionDetection.Shared\Cyberarms.IntrusionDetection.Shared.csproj",
    "Cyberarms.WebSecurity\Cyberarms.WebSecurity.csproj",
    "Cyberarms.IntrusionDetection.Base\Cyberarms.IntrusionDetection.Base.Plugins.csproj",
    "Cyberarms.Agents.Bind9\Cyberarms.Agents.Bind9.csproj",
    "Cyberarms.Agents.FileMaker\Cyberarms.Agents.FileMaker.csproj",
    "Cyberarms.Agents.FtpServer\Cyberarms.Agents.FtpServer.csproj",
    "Cyberarms.Agents.MailServer\Cyberarms.Agents.MailServer.csproj",
    "Cyberarms.Agents.MySql\Cyberarms.Agents.MySql.csproj",
    "Cyberarms.Agents.Smtp\Cyberarms.Agents.Smtp.csproj",
    "Cyberarms.Agents.SqlServer\Cyberarms.Agents.SqlServer.csproj",
    "Cyberarms.Agents.TerminalServer\Cyberarms.Agents.TerminalServer.csproj",
    "Cyberarms.Agents.WebSecurity\Cyberarms.Agents.WebSecurity.csproj",
    "Cyberarms.IntrusionDetection.Service\Cyberarms.IntrusionDetection.Service.csproj",
    "Cyberarms.IntrusionDetection.Cmd\Cyberarms.IntrusionDetection.Cmd.csproj",
    "Cyberarms.IDDS.Management\Cyberarms.IDDS.Management.csproj",
    "EventLogCleaner\EventLogCleaner.csproj"
)

foreach ($proj in $projects) {
    $path = Join-Path $baseDir $proj
    $content = Get-Content $path -Raw
    
    $platform = "AnyCPU"
    if ($content -match "Release\|x86") {
        $platform = "x86"
    }
    
    Write-Host "========================================"
    Write-Host "Building $proj (Platform: $platform)"
    Write-Host "========================================"
    
    & $msbuild $path /t:Rebuild /p:Configuration=Release /p:Platform=$platform
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build $proj"
        exit $LASTEXITCODE
    }
}

Write-Host "All builds completed successfully!"
