$code = @"
using System;
using System.Runtime.InteropServices;
using System.Net;
using System.Net.NetworkInformation;

public class RouteTesterElevated {
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

    public static void TestRoute(string destIp, uint type, string nextHop, uint proto, uint metric) {
        uint loopbackIndex = GetLoopbackIndex();
        
        MIB_IPFORWARDROW route = new MIB_IPFORWARDROW();
        route.dwForwardDest = IpToUint(destIp);
        route.dwForwardMask = 0xFFFFFFFF; // 255.255.255.255
        route.dwForwardNextHop = IpToUint(nextHop);
        route.dwForwardIfIndex = loopbackIndex;
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
        Console.WriteLine("Type={0}, NextHop={1}, Proto={2}, Metric={3} -> Result={4}", type, nextHop, proto, metric, res);
        
        if (res == 0 || res == 5010) {
            DeleteIpForwardEntry(ref route);
            Console.WriteLine("  Successfully deleted test route.");
        }
    }
}
"@

Add-Type -TypeDefinition $code

$testIp = "10.254.254.254"
Write-Host "Running elevated parameter combinations test..."
Write-Host "------------------------------------------------"
[RouteTesterElevated]::TestRoute($testIp, 3, "127.0.0.1", 3, 99) # Direct, 127.0.0.1, netmgmt
[RouteTesterElevated]::TestRoute($testIp, 4, "127.0.0.1", 3, 99) # Indirect, 127.0.0.1, netmgmt
[RouteTesterElevated]::TestRoute($testIp, 3, "0.0.0.0", 3, 99)   # Direct, 0.0.0.0, netmgmt
[RouteTesterElevated]::TestRoute($testIp, 4, "0.0.0.0", 3, 99)   # Indirect, 0.0.0.0, netmgmt

Write-Host ""
Write-Host "Trying local protocol (2)..."
[RouteTesterElevated]::TestRoute($testIp, 3, "127.0.0.1", 2, 99) # Direct, 127.0.0.1, local
[RouteTesterElevated]::TestRoute($testIp, 4, "127.0.0.1", 2, 99) # Indirect, 127.0.0.1, local
[RouteTesterElevated]::TestRoute($testIp, 3, "0.0.0.0", 2, 99)   # Direct, 0.0.0.0, local
[RouteTesterElevated]::TestRoute($testIp, 4, "0.0.0.0", 2, 99)   # Indirect, 0.0.0.0, local
