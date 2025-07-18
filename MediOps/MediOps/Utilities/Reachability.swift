import Foundation
import SystemConfiguration

class Reachability {
    enum Connection: CustomStringConvertible {
        case unavailable, wifi, cellular
        var description: String {
            switch self {
                case .cellular: return "cellular"
                case .wifi: return "WiFi"
                case .unavailable: return "No Connection"
            }
        }
    }
    
    var connection: Connection {
        guard let flags = flags else { return .unavailable }
        if flags.contains(.isWWAN) { return .cellular }
        if flags.contains(.reachable) { return .wifi }
        return .unavailable
    }
    
    private var flags: SCNetworkReachabilityFlags? {
        guard let reachability = reachability else { return nil }
        var flags = SCNetworkReachabilityFlags()
        if SCNetworkReachabilityGetFlags(reachability, &flags) {
            return flags
        }
        return nil
    }
    
    private let reachability: SCNetworkReachability?
    
    init() throws {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let reachability = withUnsafePointer(to: &zeroAddress, { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            throw NSError(domain: "Reachability",
                         code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Unable to create reachability object"])
        }
        self.reachability = reachability
    }
} 