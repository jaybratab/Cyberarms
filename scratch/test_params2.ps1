$code = @"
using System;
using System.Runtime.InteropServices;
using System.Net;
using System.Net.NetworkInformation;

public class RouteTester2 {
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

    public static uint GetLoopbackIndex() {
        foreach (var ni in NetworkInterface.GetAllNetworkInterfaces()) {
            if (ni.NetworkInterfaceType == NetworkInterfaceType.Loopback) {
                var ipProps = ni.GetIPProperties();
                var ipv4Props = ipProps.GetIPv4Properties();
                if (ipv4Props != null) {
                    return (uint)ipv4Props.Index;
                }
            }
        }
        return 1;
    }

    public static void TestRoute(string ipStr, uint type, string nextHopStr, uint proto, uint metric, bool setUnusedMetrics) {
        uint loopbackIndex = GetLoopbackIndex();
        
        MIB_IPFORWARDROW route = new MIB_IPFORWARDROW();
        route.dwForwardDest = IpToUint(ipStr);
        route.dwForwardMask = 0xFFFFFFFF; // 255.255.255.255
        route.dwForwardNextHop = IpToUint(nextHopStr);
        route.dwForwardIfIndex = loopbackIndex;
        route.dwForwardMetric1 = metric;
        
        if (setUnusedMetrics) {
            route.dwForwardMetric2 = 0xFFFFFFFF;
            route.dwForwardMetric3 = 0xFFFFFFFF;
            route.dwForwardMetric4 = 0xFFFFFFFF;
            route.dwForwardMetric5 = 0xFFFFFFFF;
        } else {
            route.dwForwardMetric2 = 0;
            route.dwForwardMetric3 = 0;
            route.dwForwardMetric4 = 0;
            route.dwForwardMetric5 = 0;
        }
        
        route.dwForwardProto = proto;
        route.dwForwardType = type;
        route.dwForwardAge = 0;
        route.dwForwardPolicy = 0;
        
        int res = CreateIpForwardEntry(ref route);
        Console.WriteLine("Test: Type={0}, NextHop={1}, Proto={2}, Metric={3}, SetUnused={4} -> Result={5}", type, nextHopStr, proto, metric, setUnusedMetrics, res);
        
        if (res == 0 || res == 5010) {
            DeleteIpForwardEntry(ref route);
        }
    }
}
"@

Add-Type -TypeDefinition $code

$testIp = "10.254.254.254"
Write-Host "Running parameter test with unused metrics set/unset..."
[RouteTester2]::TestRoute($testIp, 3, "127.0.0.1", 3, 1, $false)
[RouteTester2]::TestRoute($testIp, 3, "127.0.0.1", 3, 1, $true)
[RouteTester2]::TestRoute($testIp, 4, "127.0.0.1", 3, 1, $true)
[RouteTester2]::TestRoute($testIp, 3, "0.0.0.0", 3, 1, $true)
[RouteTester2]::TestRoute($testIp, 4, "0.0.0.0", 3, 1, $true)
