using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Cyberarms.IntrusionDetection {
    internal class FirewallManager {
        private static FirewallManager _instance;
        private dynamic firewallManager; 
        internal static FirewallManager Instance {
            get {
                if (_instance == null) {
                    _instance = new FirewallManager();
                }
                return _instance;
            }
        }

        private FirewallManager() {
            Type t = Type.GetTypeFromProgID("HNetCfg.FwMgr");
            firewallManager = Activator.CreateInstance(t);
        }

        internal void AddPort(string strName,
                                   int Port,
                                   int Scope,
                                   int Protocol, 
                                   string remoteAddresses) {
            Type t = Type.GetTypeFromProgID("HNetCfg.FWOpenPort");
            dynamic fireWallPort = Activator.CreateInstance(t);
            fireWallPort.RemoteAddresses = remoteAddresses;
            fireWallPort.Enabled = true;
            fireWallPort.Name = strName;
            fireWallPort.Port = Port;
            fireWallPort.Protocol = Protocol;

            firewallManager.LocalPolicy.CurrentProfile
                                       .GloballyOpenPorts.Add(fireWallPort);
        }

        internal void RemovePort(int Port,
                                      int Protocol) {
            firewallManager.LocalPolicy.CurrentProfile
               .GloballyOpenPorts.Remove(Port, Protocol);
        }

        internal void AddAuthorizedApplication(string strName,
                                                string processImageFileName,
                                                int Scope) {
            Type t = Type.GetTypeFromProgID("HNetCfg.FwAuthorizedApplication");
            dynamic authorizedApplication = Activator.CreateInstance(t);
            authorizedApplication.Name = strName;
            authorizedApplication.Scope = Scope;
            authorizedApplication.Enabled = true;
            authorizedApplication.ProcessImageFileName = processImageFileName;
            firewallManager.LocalPolicy.CurrentProfile
                            .AuthorizedApplications.Add(authorizedApplication);
        }

        internal void RemoveAuthorizedApplication(string processFileName) {
            firewallManager.LocalPolicy.CurrentProfile
                            .AuthorizedApplications.Remove(processFileName);
        }

        internal dynamic ReadPort(string name) {
            dynamic ports = firewallManager.LocalPolicy.CurrentProfile.GloballyOpenPorts;
            foreach (dynamic port in ports) {
                System.Diagnostics.Debug.Print(port.Name);
                if (port.Name == name) return port;
            }
            return null;
        }
    }
}
