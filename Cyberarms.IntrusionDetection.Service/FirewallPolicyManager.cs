using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;
using System.Net;
using System.Net.NetworkInformation;
using Cyberarms.IntrusionDetection.Shared;

namespace Cyberarms.IntrusionDetection {
    internal class FirewallPolicyManager {
        private static FirewallPolicyManager _instance;

        internal static FirewallPolicyManager Instance {
            get {
                if (_instance == null) {
                    _instance = new FirewallPolicyManager();
                }
                return _instance;
            }
        }

        private FirewallPolicyManager() {
        }

        // P/Invoke Structures and Methods
        [StructLayout(LayoutKind.Sequential)]
        internal struct MIB_IPFORWARDROW {
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
        internal static extern int CreateIpForwardEntry(ref MIB_IPFORWARDROW pRoute);

        [DllImport("iphlpapi.dll", SetLastError = true)]
        internal static extern int DeleteIpForwardEntry(ref MIB_IPFORWARDROW pRoute);

        [DllImport("iphlpapi.dll", SetLastError = true)]
        internal static extern int GetIpForwardTable(IntPtr pIpForwardTable, ref int pdwSize, bool bOrder);


        private static uint IpToUint(string ipAddress) {
            IPAddress ip = IPAddress.Parse(ipAddress);
            byte[] bytes = ip.GetAddressBytes();
            return BitConverter.ToUInt32(bytes, 0);
        }

        private static uint GetLoopbackInterfaceIndex() {
            foreach (var ni in NetworkInterface.GetAllNetworkInterfaces()) {
                if (ni.NetworkInterfaceType == NetworkInterfaceType.Loopback) {
                    var ipProps = ni.GetIPProperties();
                    var ipv4Props = ipProps.GetIPv4Properties();
                    if (ipv4Props != null) {
                        return (uint)ipv4Props.Index;
                    }
                }
            }
            return 1; // fallback default
        }

        internal void Block(string ipAddress) {
            try {
                IPAddress ip;
                if (!IPAddress.TryParse(ipAddress, out ip)) {
                    throw new ArgumentException("Invalid IP address format: " + ipAddress);
                }

                if (ip.AddressFamily == System.Net.Sockets.AddressFamily.InterNetworkV6) {
                    System.Diagnostics.EventLog.WriteEntry("Cyberarms.IntrusionDetection", 
                        "Cannot block IPv6 address " + ipAddress + " via IPv4 Routing. Skipping.", 
                        System.Diagnostics.EventLogEntryType.Warning);
                    return;
                }

                uint loopbackIndex = GetLoopbackInterfaceIndex();

                MIB_IPFORWARDROW route = new MIB_IPFORWARDROW();
                route.dwForwardDest = IpToUint(ipAddress);
                route.dwForwardMask = 0xFFFFFFFF; // 255.255.255.255
                route.dwForwardNextHop = 0; // 0.0.0.0 (Direct route next-hop)
                route.dwForwardIfIndex = loopbackIndex;
                route.dwForwardMetric1 = 99;
                route.dwForwardProto = 3; // MIB_IPPROTO_NETMGMT
                route.dwForwardType = 3;  // MIB_IPROUTE_TYPE_DIRECT
                route.dwForwardAge = 0;
                route.dwForwardPolicy = 0;

                int result = CreateIpForwardEntry(ref route);
                if (result != 0 && result != 5010) { // 5010 is OBJECT_ALREADY_EXISTS
                    throw new Exception("CreateIpForwardEntry failed with error code: " + result);
                }

                System.Diagnostics.EventLog.WriteEntry("Cyberarms.IntrusionDetection", 
                    "Null route created to block IP " + ipAddress + " (IfIndex: " + loopbackIndex + ").", 
                    System.Diagnostics.EventLogEntryType.Information);

            } catch (Exception ex) {
                System.Diagnostics.EventLog.WriteEntry("Create Null Route", ex.Message, System.Diagnostics.EventLogEntryType.Error);
            }
        }

        internal bool IsLocked(string ipAddress) {
            return IsRouteExists(ipAddress);
        }

        private bool IsRouteExists(string ipAddress) {
            try {
                uint destIp = IpToUint(ipAddress);
                int size = 0;
                GetIpForwardTable(IntPtr.Zero, ref size, false);
                if (size == 0) return false;

                IntPtr pTable = Marshal.AllocHGlobal(size);
                try {
                    int result = GetIpForwardTable(pTable, ref size, false);
                    if (result != 0) {
                        return false;
                    }

                    int numEntries = Marshal.ReadInt32(pTable);
                    IntPtr pRow = new IntPtr(pTable.ToInt64() + 4);
                    int rowSize = 56; // 14 uint fields * 4 bytes

                    uint loopbackIndex = GetLoopbackInterfaceIndex();

                    for (int i = 0; i < numEntries; i++) {
                        uint dwForwardDest = (uint)Marshal.ReadInt32(pRow, 0);
                        uint dwForwardMask = (uint)Marshal.ReadInt32(pRow, 4);
                        uint dwForwardIfIndex = (uint)Marshal.ReadInt32(pRow, 16);

                        if (dwForwardDest == destIp && dwForwardMask == 0xFFFFFFFF) {
                            if (dwForwardIfIndex == loopbackIndex) {
                                return true;
                            }
                        }
                        pRow = new IntPtr(pRow.ToInt64() + rowSize);
                    }
                } finally {
                    Marshal.FreeHGlobal(pTable);
                }
            } catch (Exception ex) {
                System.Diagnostics.EventLog.WriteEntry("Create Null Route", "IsRouteExists error: " + ex.Message, System.Diagnostics.EventLogEntryType.Error);
            }
            return false;
        }


        internal void RemoveIpAddressFromBlockList(string ipAddress) {
            try {
                IPAddress ip;
                if (!IPAddress.TryParse(ipAddress, out ip)) {
                    throw new ArgumentException("Invalid IP address format: " + ipAddress);
                }

                if (ip.AddressFamily == System.Net.Sockets.AddressFamily.InterNetworkV6) {
                    return; // V6 is not routed
                }

                uint loopbackIndex = GetLoopbackInterfaceIndex();

                MIB_IPFORWARDROW route = new MIB_IPFORWARDROW();
                route.dwForwardDest = IpToUint(ipAddress);
                route.dwForwardMask = 0xFFFFFFFF; // 255.255.255.255
                route.dwForwardNextHop = 0; // 0.0.0.0
                route.dwForwardIfIndex = loopbackIndex;
                route.dwForwardMetric1 = 99;
                route.dwForwardProto = 3;
                route.dwForwardType = 3;
                route.dwForwardAge = 0;
                route.dwForwardPolicy = 0;

                int result = DeleteIpForwardEntry(ref route);
                if (result != 0 && result != 1168) { // 1168 is ERROR_NOT_FOUND
                    throw new Exception("DeleteIpForwardEntry failed with error code: " + result);
                }

                System.Diagnostics.EventLog.WriteEntry("Cyberarms.IntrusionDetection", 
                    "Null route removed for IP " + ipAddress + ".", 
                    System.Diagnostics.EventLogEntryType.Information);

            } catch (Exception ex) {
                System.Diagnostics.EventLog.WriteEntry("Remove Null Route", ex.Message, System.Diagnostics.EventLogEntryType.Error);
            }
        }

        internal void ConfigureInterfaces() {
            try {
                System.Diagnostics.ProcessStartInfo psi = new System.Diagnostics.ProcessStartInfo();
                psi.FileName = "powershell.exe";
                psi.Arguments = "-NoProfile -WindowStyle Hidden -Command \"Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike 'Loopback*' } | Set-NetIPInterface -WeakHostSend Enabled -WeakHostReceive Enabled -ErrorAction SilentlyContinue\"";
                psi.UseShellExecute = false;
                psi.CreateNoWindow = true;
                using (System.Diagnostics.Process p = System.Diagnostics.Process.Start(psi)) {
                    p.WaitForExit(5000);
                }
            } catch (Exception ex) {
                System.Diagnostics.EventLog.WriteEntry("Cyberarms.IntrusionDetection", 
                    "Failed to configure weak host settings on network interfaces: " + ex.Message, 
                    System.Diagnostics.EventLogEntryType.Warning);
            }
        }

        internal void RestoreActiveBans() {
            try {
                ConfigureInterfaces();
                List<Lock> activeLocks = Locks.GetCurrentLocks();
                if (activeLocks == null || activeLocks.Count == 0) {
                    return;
                }

                System.Diagnostics.EventLog.WriteEntry("Cyberarms.IntrusionDetection", 
                    "Restoring " + activeLocks.Count + " active null route bans from the database.", 
                    System.Diagnostics.EventLogEntryType.Information);

                foreach (Lock l in activeLocks) {
                    Block(l.IpAddress);
                }
            } catch (Exception ex) {
                System.Diagnostics.EventLog.WriteEntry("Restore Active Bans", ex.Message, System.Diagnostics.EventLogEntryType.Error);
            }
        }


        internal void CleanUpRules() {
            try {
                // Delete active null routes for all current database locks
                List<Lock> activeLocks = Locks.GetCurrentLocks();
                if (activeLocks != null) {
                    foreach (Lock l in activeLocks) {
                        RemoveIpAddressFromBlockList(l.IpAddress);
                    }
                }
            } catch (Exception ex) {
                System.Diagnostics.EventLog.WriteEntry("CleanUpRules", ex.Message, System.Diagnostics.EventLogEntryType.Error);
            }
        }
    }
}
