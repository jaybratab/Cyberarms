try {
    $serviceDll = "C:\Program Files\Cyberarms Intrusion Detection\CyberarmsIdsService.exe"
    $assembly = [System.Reflection.Assembly]::LoadFrom($serviceDll)
    $fpmType = $assembly.GetType("Cyberarms.IntrusionDetection.FirewallPolicyManager")
    $method = $fpmType.GetMethod("GetLoopbackInterfaceIndex", [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::NonPublic)
    $res = $method.Invoke($null, $null)
    Write-Host "Service loopback index returned: $res"
} catch {
    Write-Host $_.Exception.ToString()
}
