try {
    [System.Reflection.Assembly]::LoadFrom("C:\Program Files\Cyberarms Intrusion Detection\System.Data.SQLite.dll") | Out-Null
    $conn = New-Object System.Data.SQLite.SQLiteConnection("Data Source=C:\Program Files\Cyberarms Intrusion Detection\cyberarms.idds.dbf;Password=hasdvfdfaxNm.DFd3djkn2li9fu24$")
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "select * from SecurityAgents"
    $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
    $dt = New-Object System.Data.DataTable
    $adapter.Fill($dt) | Out-Null
    $dt | Format-Table -AutoSize | Out-String | Out-File -FilePath "c:\Cyberarms\query_result.txt" -Encoding utf8
    $conn.Close()
} catch {
    $_ | Out-File -FilePath "c:\Cyberarms\query_result.txt" -Encoding utf8
}
