$code = @"
using System;
using System.Runtime.InteropServices;
using System.Net;
using System.Net.NetworkInformation;

public class RouteTester3 {
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

    public static int TestMetric(uint metric) {
        uint loopbackIndex = GetLoopbackIndex();
        
        MIB_IPFORWARDROW route = new MIB_IPFORWARDROW();
        route.dwForwardDest = IpToUint("10.254.254.254");
        route.dwForwardMask = 0xFFFFFFFF;
        route.dwForwardNextHop = IpToUint("127.0.0.1");
        route.dwForwardIfIndex = loopbackIndex;
        route.dwForwardMetric1 = metric;
        route.dwForwardProto = 3;
        route.dwForwardType = 4;
        
        return CreateIpForwardEntry(ref route);
    }
}
"@

Add-Type -TypeDefinition $code

Write-Host "Searching for valid metric range..."
for ($m = 1; $m -le 100; $m++) {
    $res = [RouteTester3]::TestMetric($m)
    if ($res -ne 160) {
        Write-Host "Metric $m -> Result $res"
    }
}
