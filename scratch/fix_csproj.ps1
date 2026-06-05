$path = "c:\Cyberarms\Cyberarms-master\Cyberarms.IntrusionDetection.Admin\Cyberarms.IntrusionDetection.Admin.csproj"
$enc1252 = [System.Text.Encoding]::GetEncoding(1252)
$content = [System.IO.File]::ReadAllText($path, $enc1252)
[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
Write-Host "Encoding fixed successfully!"
