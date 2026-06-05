Start-Transcript -Path "c:\Cyberarms\test_local_result.txt" -Force

$code = @"
using System;
using System.Runtime.InteropServices;
using System.Net;
using System.Net.NetworkInformation;

public class RouteTesterLocal {
    [StructLayout(LayoutKind.Sequential)]
    public struct MIB_IPFORWARDROW {
        public uint dwForwardDest;
        public uint dwForwardMask;
        public uint dwForwardPolicy;
        public uint dwForwardNextHop;
        public uint dwForwardIfIndex;
        public uint dwForwardType;
        public uint dwForwardProto;
        public uint dwForwardAge;
        public uint dwForwardNextHopAS;
        public uint dwForwardMetric1;
        public uint dwForwardMetric2;
        public uint dwForwardMetric3;
        public uint dwForwardMetric4;
        public uint dwForwardMetric5;
    }

    [DllImport("iphlpapi.dll", SetLastError = true)]
    public static extern int CreateIpForwardEntry(ref MIB_IPFORWARDROW pRoute);

    [DllImport("iphlpapi.dll", SetLastError = true)]
    public static extern int DeleteIpForwardEntry(ref MIB_IPFORWARDROW pRoute);

    private static uint IpToUint(string ipAddress) {
        IPAddress ip = IPAddress.Parse(ipAddress);
        byte[] bytes = ip.GetAddressBytes();
        return BitConverter.ToUInt32(bytes, 0);
    }

    public static void TestRoute(string destIp, uint type, string nextHop, uint ifIndex, uint proto, uint metric) {
        MIB_IPFORWARDROW route = new MIB_IPFORWARDROW();
        route.dwForwardDest = IpToUint(destIp);
        route.dwForwardMask = 0xFFFFFFFF; // 255.255.255.255
        route.dwForwardNextHop = IpToUint(nextHop);
        route.dwForwardIfIndex = ifIndex;
        route.dwForwardMetric1 = metric;
        
        route.dwForwardMetric2 = 0xFFFFFFFF;
        route.dwForwardMetric3 = 0xFFFFFFFF;
        route.dwForwardMetric4 = 0xFFFFFFFF;
        route.dwForwardMetric5 = 0xFFFFFFFF;
        
        route.dwForwardProto = proto;
        route.dwForwardType = type;
        route.dwForwardAge = 0;
        route.dwForwardPolicy = 0;
        
        int res = CreateIpForwardEntry(ref route);
        Console.WriteLine("Dest={0}, If={1}, Type={2}, NextHop={3}, Proto={4}, Metric={5} -> Result={6}", destIp, ifIndex, type, nextHop, proto, metric, res);
        
        if (res == 0 || res == 5010) {
            DeleteIpForwardEntry(ref route);
            Console.WriteLine("  Successfully deleted test route.");
        }
    }
}
"@

Add-Type -TypeDefinition $code

$loopbackIf = 1
$ethernetIf = 5 # from the route print

Write-Host "Running local subnet IP parameter tests for 192.168.1.9..."
Write-Host "--------------------------------------------------------"

# Test 1: On Loopback
Write-Host "Testing on Loopback Interface ($loopbackIf):"
[RouteTesterLocal]::TestRoute("192.168.1.9", 3, "0.0.0.0", $loopbackIf, 3, 99)
[RouteTesterLocal]::TestRoute("192.168.1.9", 4, "0.0.0.0", $loopbackIf, 3, 99)
[RouteTesterLocal]::TestRoute("192.168.1.9", 3, "127.0.0.1", $loopbackIf, 3, 99)
[RouteTesterLocal]::TestRoute("192.168.1.9", 4, "127.0.0.1", $loopbackIf, 3, 99)

# Test 2: On Ethernet
Write-Host "Testing on Ethernet Interface ($ethernetIf):"
[RouteTesterLocal]::TestRoute("192.168.1.9", 3, "0.0.0.0", $ethernetIf, 3, 99)
[RouteTesterLocal]::TestRoute("192.168.1.9", 4, "0.0.0.0", $ethernetIf, 3, 99)
[RouteTesterLocal]::TestRoute("192.168.1.9", 3, "192.168.1.11", $ethernetIf, 3, 99)
[RouteTesterLocal]::TestRoute("192.168.1.9", 4, "192.168.1.11", $ethernetIf, 3, 99)
[RouteTesterLocal]::TestRoute("192.168.1.9", 3, "127.0.0.1", $ethernetIf, 3, 99)
[RouteTesterLocal]::TestRoute("192.168.1.9", 4, "127.0.0.1", $ethernetIf, 3, 99)

Stop-Transcript
