try {
    $binDir = "C:\Cyberarms\Cyberarms-master\ReleasePackage\bin"
    Write-Host "Loading System.Data.SQLite..."
    [System.Reflection.Assembly]::LoadFrom("$binDir\System.Data.SQLite.dll") | Out-Null
    
    Write-Host "Loading Cyberarms.IntrusionDetection.Shared..."
    [System.Reflection.Assembly]::LoadFrom("$binDir\Cyberarms.IntrusionDetection.Shared.dll") | Out-Null
    
    Write-Host "Instantiating Database via reflection..."
    $db = [Activator]::CreateInstance([Cyberarms.IntrusionDetection.Shared.Database], $true)
    Write-Host "Database instantiated successfully!"
} catch {
    Write-Host "EXCEPTION CAUGHT:"
    Write-Host $_.Exception.ToString()
    if ($_.Exception.InnerException) {
        Write-Host "INNER EXCEPTION:"
        Write-Host $_.Exception.InnerException.ToString()
    }
}
