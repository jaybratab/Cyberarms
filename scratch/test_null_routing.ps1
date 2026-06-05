$binDir = "C:\Program Files\Cyberarms Intrusion Detection"
$serviceDll = Join-Path $binDir "CyberarmsIdsService.exe"

try {
    Write-Host "Loading CyberarmsIdsService assembly..."
    $assembly = [System.Reflection.Assembly]::LoadFrom($serviceDll)
    
    # Get FirewallPolicyManager type
    $fpmType = $assembly.GetType("Cyberarms.IntrusionDetection.FirewallPolicyManager")
    if ($fpmType -eq $null) {
        throw "Could not find FirewallPolicyManager type in assembly."
    }
    
    # Get Instance singleton
    $instanceProp = $fpmType.GetProperty("Instance", [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Public)
    $fpmInstance = $instanceProp.GetValue($null, $null)
    if ($fpmInstance -eq $null) {
        throw "Could not retrieve FirewallPolicyManager.Instance."
    }
    
    # Get Block and Remove methods
    $blockMethod = $fpmType.GetMethod("Block", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Public)
    $removeMethod = $fpmType.GetMethod("RemoveIpAddressFromBlockList", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Public)
    
    $testIp = "10.254.254.254"
    
    Write-Host "1. Testing Block($testIp)..."
    $blockMethod.Invoke($fpmInstance, @($testIp))
    
    Start-Sleep -Seconds 1
    
    Write-Host "Checking routing table for $testIp..."
    $route = Get-NetRoute -DestinationPrefix "$testIp/32" -ErrorAction SilentlyContinue
    if ($route) {
        Write-Host "SUCCESS: Route found in routing table:" -ForegroundColor Green
        $route | Format-Table DestinationPrefix, NextHop, InterfaceIndex, RouteMetric
    } else {
        Write-Host "FAILED: Route not found in routing table. (Ensure you are running this script in an elevated PowerShell session)" -ForegroundColor Red
    }
    
    Write-Host "2. Testing RemoveIpAddressFromBlockList($testIp)..."
    $removeMethod.Invoke($fpmInstance, @($testIp))
    
    Start-Sleep -Seconds 1
    
    Write-Host "Re-checking routing table for $testIp..."
    $routeAfter = Get-NetRoute -DestinationPrefix "$testIp/32" -ErrorAction SilentlyContinue
    if (-not $routeAfter) {
        Write-Host "SUCCESS: Route successfully removed from routing table!" -ForegroundColor Green
    } else {
        Write-Host "FAILED: Route still exists in routing table." -ForegroundColor Red
        $routeAfter | Format-Table DestinationPrefix, NextHop, InterfaceIndex, RouteMetric
    }
    
} catch {
    Write-Host "ERROR ENCOUNTERED:" -ForegroundColor Red
    Write-Host $_.Exception.ToString()
    if ($_.Exception.InnerException) {
        Write-Host "INNER EXCEPTION:" -ForegroundColor Red
        Write-Host $_.Exception.InnerException.ToString()
    }
}
