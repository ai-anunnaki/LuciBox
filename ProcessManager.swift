import Foundation

struct PortInfo: Identifiable, Comparable {
    let id = UUID()
    let address: String  // 绑定地址，如 "*", "127.0.0.1"
    let port: Int
    var display: String { "\(address):\(port)" }

    static func < (lhs: PortInfo, rhs: PortInfo) -> Bool {
        lhs.port != rhs.port ? lhs.port < rhs.port : lhs.address < rhs.address
    }
    static func == (lhs: PortInfo, rhs: PortInfo) -> Bool {
        lhs.address == rhs.address && lhs.port == rhs.port
    }
}

struct Process: Identifiable {
    let id = UUID()
    let pid: Int32
    let fullPath: String
    let displayName: String
    let portInfos: [PortInfo]
    var minPort: Int { portInfos.map { $0.port }.min() ?? Int.max }
}

class ProcessManager: ObservableObject {
    @Published var processes: [Process] = []

    func refreshProcesses() {
        DispatchQueue.global(qos: .userInitiated).async {
            let portMap = self.fetchListeningPorts()
            let list = self.fetchAllProcesses(portMap: portMap)
            DispatchQueue.main.async {
                self.processes = list
            }
        }
    }

    // 一次性获取所有进程的监听端口（仅 LISTEN 状态）
    private func fetchListeningPorts() -> [Int32: [PortInfo]] {
        var seen: [Int32: Set<String>] = [:]
        var result: [Int32: [PortInfo]] = [:]

        let task = Foundation.Process()
        task.launchPath = "/bin/bash"
        // 注意：-sTCP:LISTEN 在 Swift 子进程中无效，改用 grep LISTEN 过滤
        task.arguments = ["-c", "lsof -nP -i 2>/dev/null | grep LISTEN"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        guard (try? task.run()) != nil else { return [:] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        guard let output = String(data: data, encoding: .utf8) else { return [:] }

        // 列: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME (LISTEN)
        for line in output.components(separatedBy: "\n") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 9, let pid = Int32(parts[1]) else { continue }
            let namePart = String(parts[8])  // e.g. "*:8080" or "127.0.0.1:3000"
            if let colonIdx = namePart.lastIndex(of: ":") {
                let portStr = String(namePart[namePart.index(after: colonIdx)...])
                if let port = Int(portStr), port > 0 {
                    let address = String(namePart[..<colonIdx])
                    let info = PortInfo(address: address, port: port)
                    if seen[pid] == nil { seen[pid] = [] }
                    if !seen[pid]!.contains(info.display) {
                        seen[pid]!.insert(info.display)
                        result[pid, default: []].append(info)
                    }
                }
            }
        }

        return result.mapValues { $0.sorted() }
    }

    private func fetchAllProcesses(portMap: [Int32: [PortInfo]]) -> [Process] {
        var list: [Process] = []

        let task = Foundation.Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-eo", "pid,comm"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        for line in output.components(separatedBy: "\n").dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.components(separatedBy: .whitespaces)
            guard parts.count >= 2, let pid = Int32(parts[0]) else { continue }
            let fullPath = parts[1...].joined(separator: " ")
            let lastComponent = fullPath.components(separatedBy: "/").last ?? ""
            let displayName = lastComponent.isEmpty ? fullPath : lastComponent
            let portInfos = portMap[pid] ?? []
            list.append(Process(pid: pid, fullPath: fullPath, displayName: displayName, portInfos: portInfos))
        }

        return list
    }

    func killProcess(pid: Int32) -> Bool {
        let task = Foundation.Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-9", "\(pid)"]
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
}
