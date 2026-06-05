Add-Type -Path "C:\Program Files\Cyberarms Intrusion Detection\System.Data.SQLite.dll"

$dbPath = "c:\Cyberarms\cyberarms.idds.dbf"
$connString = "Data Source=$dbPath;Password=hasdvfdfaxNm.DFd3djkn2li9fu24$;File Mode=read write;Pooling=True;"

$connection = New-Object System.Data.SQLite.SQLiteConnection($connString)
$connection.Open()

try {
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = "insert into IntrusionLog (IncidentTime, AgentId, ClientIP, Action, ActionTriggeredByUser) values (@p0, @p1, @p2, @p3, @p4)"
    
    $p0 = $cmd.CreateParameter()
    $p0.ParameterName = "@p0"
    $p0.Value = [DateTime]::Now
    $cmd.Parameters.Add($p0)
    
    $p1 = $cmd.CreateParameter()
    $p1.ParameterName = "@p1"
    $p1.Value = [Guid]::NewGuid()
    $cmd.Parameters.Add($p1)
    
    $p2 = $cmd.CreateParameter()
    $p2.ParameterName = "@p2"
    $p2.Value = "1.2.3.4"
    $cmd.Parameters.Add($p2)
    
    $p3 = $cmd.CreateParameter()
    $p3.ParameterName = "@p3"
    $p3.Value = 100
    $cmd.Parameters.Add($p3)
    
    $p4 = $cmd.CreateParameter()
    $p4.ParameterName = "@p4"
    $p4.Value = $false
    $cmd.Parameters.Add($p4)
    
    $cmd.ExecuteNonQuery()
    $cmd.Dispose()
    
    # Get the new max ID
    $cmd2 = $connection.CreateCommand()
    $cmd2.CommandText = "select max(Id) from IntrusionLog"
    $newMax = $cmd2.ExecuteScalar()
    $cmd2.Dispose()
    
    Write-Host "Successfully inserted test log! New Max ID: $newMax"
}
finally {
    $connection.Close()
}
