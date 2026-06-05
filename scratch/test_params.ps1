$code = @"
using System;
using System.Runtime.InteropServices;
using System.Net;
using System.Net.NetworkInformation;

public class RouteTester {
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

    public static void TestRoute(string ipStr, uint type, string nextHopStr, uint proto, uint metric) {
        uint loopbackIndex = GetLoopbackIndex();
        
        MIB_IPFORWARDROW route = new MIB_IPFORWARDROW();
        route.dwForwardDest = IpToUint(ipStr);
        route.dwForwardMask = 0xFFFFFFFF; // 255.255.255.255
        route.dwForwardNextHop = IpToUint(nextHopStr);
        route.dwForwardIfIndex = loopbackIndex;
        route.dwForwardMetric1 = metric;
        route.dwForwardProto = proto;
        route.dwForwardType = type;
        route.dwForwardAge = 0;
        route.dwForwardPolicy = 0;
        
        int res = CreateIpForwardEntry(ref route);
        Console.WriteLine("Test: Type={0}, NextHop={1}, Proto={2}, Metric={3} -> Result={4}", type, nextHopStr, proto, metric, res);
        
        if (res == 0 || res == 5010) {
            // Cleanup
            DeleteIpForwardEntry(ref route);
        }
    }
}
"@

Add-Type -TypeDefinition $code

$testIp = "10.254.254.254"
# Try combinations
Write-Host "Running parameter test..."
[RouteTester]::TestRoute($testIp, 3, "127.0.0.1", 3, 1) # Direct, 127.0.0.1, netmgmt
[RouteTester]::TestRoute($testIp, 4, "127.0.0.1", 3, 1) # Indirect, 127.0.0.1, netmgmt
[RouteTester]::TestRoute($testIp, 3, "0.0.0.0", 3, 1)   # Direct, 0.0.0.0, netmgmt
[RouteTester]::TestRoute($testIp, 4, "0.0.0.0", 3, 1)   # Indirect, 0.0.0.0, netmgmt

[RouteTester]::TestRoute($testIp, 3, "127.0.0.1", 2, 1) # Direct, 127.0.0.1, local
[RouteTester]::TestRoute($testIp, 4, "127.0.0.1", 2, 1) # Indirect, 127.0.0.1, local
[RouteTester]::TestRoute($testIp, 3, "127.0.0.1", 3, 99) # Direct, 127.0.0.1, netmgmt, metric 99
[RouteTester]::TestRoute($testIp, 4, "127.0.0.1", 3, 99) # Indirect, 127.0.0.1, netmgmt, metric 99
