import Foundation
import IOKit.ps

struct SystemInfo {
    let cpuUsage: Double
    let memoryUsage: Double
    let diskUsage: Double
    let networkUpload: Double
    let networkDownload: Double
}

class SystemMonitor: ObservableObject {
    @Published var systemInfo: SystemInfo = SystemInfo(
        cpuUsage: 0,
        memoryUsage: 0,
        diskUsage: 0,
        networkUpload: 0,
        networkDownload: 0
    )
    
    private var timer: Timer?
    private var lastNetworkStats: (upload: UInt64, download: UInt64)?
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateSystemInfo()
        }
        updateSystemInfo()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateSystemInfo() {
        let cpu = getCPUUsage()
        let memory = getMemoryUsage()
        let disk = getDiskUsage()
        let network = getNetworkUsage()
        
        DispatchQueue.main.async {
            self.systemInfo = SystemInfo(
                cpuUsage: cpu,
                memoryUsage: memory,
                diskUsage: disk,
                networkUpload: network.upload,
                networkDownload: network.download
            )
        }
    }
    
    private func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t!
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0
        
        let result = host_processor_info(mach_host_self(),
                                        PROCESSOR_CPU_LOAD_INFO,
                                        &numCPUs,
                                        &cpuInfo,
                                        &numCPUInfo)
        
        guard result == KERN_SUCCESS else { return 0 }
        
        var totalUsage: Double = 0
        
        for i in 0..<Int(numCPUs) {
            let cpuLoadInfo = cpuInfo.advanced(by: Int(i) * Int(CPU_STATE_MAX))
                .withMemoryRebound(to: integer_t.self, capacity: Int(CPU_STATE_MAX)) { $0 }
            
            let user = Double(cpuLoadInfo[Int(CPU_STATE_USER)])
            let system = Double(cpuLoadInfo[Int(CPU_STATE_SYSTEM)])
            let nice = Double(cpuLoadInfo[Int(CPU_STATE_NICE)])
            let idle = Double(cpuLoadInfo[Int(CPU_STATE_IDLE)])
            
            let total = user + system + nice + idle
            if total > 0 {
                totalUsage += (user + system + nice) / total
            }
        }
        
        return (totalUsage / Double(numCPUs)) * 100
    }
    
    private func getMemoryUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0 }
        
        let pageSize = vm_kernel_page_size
        let used = (UInt64(stats.active_count) +
                   UInt64(stats.inactive_count) +
                   UInt64(stats.wire_count)) * UInt64(pageSize)
        let total = ProcessInfo.processInfo.physicalMemory
        
        return Double(used) / Double(total) * 100
    }
    
    private func getDiskUsage() -> Double {
        let fileManager = Foundation.FileManager.default
        guard let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return 0
        }
        
        do {
            let values = try path.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            if let total = values.volumeTotalCapacity,
               let available = values.volumeAvailableCapacity {
                let used = total - available
                return Double(used) / Double(total) * 100
            }
        } catch {
            print("Error getting disk usage: \(error)")
        }
        
        return 0
    }
    
    private func getNetworkUsage() -> (upload: Double, download: Double) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }
        
        var totalUpload: UInt64 = 0
        var totalDownload: UInt64 = 0
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            let name = String(cString: interface.ifa_name)
            
            if name.hasPrefix("en") || name.hasPrefix("pdp_ip") {
                if let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self).pointee {
                    totalUpload += UInt64(data.ifi_obytes)
                    totalDownload += UInt64(data.ifi_ibytes)
                }
            }
        }
        
        var uploadSpeed: Double = 0
        var downloadSpeed: Double = 0
        
        if let last = lastNetworkStats {
            let uploadDiff = totalUpload > last.upload ? totalUpload - last.upload : 0
            let downloadDiff = totalDownload > last.download ? totalDownload - last.download : 0
            
            uploadSpeed = Double(uploadDiff) / 2.0 / 1024 / 1024 // MB/s
            downloadSpeed = Double(downloadDiff) / 2.0 / 1024 / 1024 // MB/s
        }
        
        lastNetworkStats = (totalUpload, totalDownload)
        
        return (uploadSpeed, downloadSpeed)
    }
    
    deinit {
        stopMonitoring()
    }
}
