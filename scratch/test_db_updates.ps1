Add-Type -Path "C:\Program Files\Cyberarms Intrusion Detection\System.Data.SQLite.dll"

$dbPath = "c:\Cyberarms\cyberarms.idds.dbf"
$connString = "Data Source=$dbPath;Password=hasdvfdfaxNm.DFd3djkn2li9fu24$;File Mode=read write;Pooling=True;"

$connection = New-Object System.Data.SQLite.SQLiteConnection($connString)
$connection.Open()

Write-Host "Connection opened to $dbPath"
Write-Host "Press Ctrl+C to stop."

try {
    while ($true) {
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = "select max(Id) from IntrusionLog"
        $result = $cmd.ExecuteScalar()
        $cmd.Dispose()
        
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] Max Log ID: $result"
        
        Start-Sleep -Seconds 1
    }
}
finally {
    $connection.Close()
    Write-Host "Connection closed."
}
