Add-Type -Path "C:\Program Files\Cyberarms Intrusion Detection\System.Data.SQLite.dll"
$dbPath = "C:\Program Files\Cyberarms Intrusion Detection\cyberarms.idds.dbf"
$connString = "Data Source=$dbPath;Password=hasdvfdfaxNm.DFd3djkn2li9fu24$;File Mode=read write;Pooling=True;"
$connection = New-Object System.Data.SQLite.SQLiteConnection($connString)
$connection.Open()
$cmd = $connection.CreateCommand()
$cmd.CommandText = "select count(*) from IntrusionLog"
$result = $cmd.ExecuteScalar()
Write-Host "Total Log Count: $result"
$connection.Close()
