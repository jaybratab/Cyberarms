$code = @"
using System;
using System.Runtime.InteropServices;
using System.Net;

public class IndirectRouteTester {
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

    public static void AddRoute(string destIp, uint type, string nextHop, uint ifIndex) {
        MIB_IPFORWARDROW route = new MIB_IPFORWARDROW();
        route.dwForwardDest = IpToUint(destIp);
        route.dwForwardMask = 0xFFFFFFFF; // 255.255.255.255
        route.dwForwardNextHop = IpToUint(nextHop);
        route.dwForwardIfIndex = ifIndex;
        route.dwForwardMetric1 = 99;
        
        route.dwForwardMetric2 = 0xFFFFFFFF;
        route.dwForwardMetric3 = 0xFFFFFFFF;
        route.dwForwardMetric4 = 0xFFFFFFFF;
        route.dwForwardMetric5 = 0xFFFFFFFF;
        
        route.dwForwardProto = 3; // NetMgmt
        route.dwForwardType = type; // 4 = Indirect
        route.dwForwardAge = 0;
        route.dwForwardPolicy = 0;
        
        int res = CreateIpForwardEntry(ref route);
        Console.WriteLine("AddRoute Result: " + res);
    }
}
"@

Add-Type -TypeDefinition $code

[IndirectRouteTester]::AddRoute("192.168.1.18", 4, "192.168.1.11", 5)
