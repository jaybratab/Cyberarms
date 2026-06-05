Get-EventLog -LogName Security -InstanceId 4625 -Newest 5 -ErrorAction SilentlyContinue | Format-List TimeGenerated, Message | Out-File -FilePath "c:\Cyberarms\security_result.txt" -Encoding utf8
