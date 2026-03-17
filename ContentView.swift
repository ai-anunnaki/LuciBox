import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var processManager = ProcessManager()
    @State private var searchText = ""
    @State private var selectedProcessID: Process.ID?
    @State private var showingKillAlert = false
    @State private var showingPathAlert = false
    @State private var pathToShow = ""
    @State private var sortOrder: [KeyPathComparator<Process>] = [KeyPathComparator(\.minPort)]

    var selectedProcess: Process? {
        processManager.processes.first { $0.id == selectedProcessID }
    }

    var sortedFilteredProcesses: [Process] {
        let list = searchText.isEmpty ? processManager.processes : processManager.processes.filter { process in
            process.displayName.localizedCaseInsensitiveContains(searchText) ||
            "\(process.pid)".contains(searchText) ||
            process.portInfos.contains { "\($0.port)".contains(searchText) || $0.address.contains(searchText) }
        }
        return list.sorted(using: sortOrder)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                Text("进程管理")
                    .font(.headline)
                Spacer()
                Button(action: { processManager.refreshProcesses() }) {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜索进程名称、PID 或端口号", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding()

            // 进程列表
            Table(sortedFilteredProcesses, selection: $selectedProcessID, sortOrder: $sortOrder) {
                TableColumn("PID", value: \.pid) { process in
                    Text(String(process.pid))
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 60, max: 80)

                TableColumn("进程名称", value: \.displayName) { process in
                    Text(process.displayName)
                }
                .width(min: 200)

                TableColumn("监听端口", value: \.minPort) { process in
                    if process.portInfos.isEmpty {
                        Text("-").foregroundColor(.gray)
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(process.portInfos) { portInfo in
                                Text(portInfo.display)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .width(min: 150)
            }
            .contextMenu(forSelectionType: Process.ID.self) { ids in
                if let id = ids.first,
                   let process = processManager.processes.first(where: { $0.id == id }) {
                    Button {
                        pathToShow = process.fullPath
                        showingPathAlert = true
                    } label: {
                        Label("查看完整路径", systemImage: "doc.text.magnifyingglass")
                    }
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(process.fullPath, forType: .string)
                    } label: {
                        Label("复制完整路径", systemImage: "doc.on.doc")
                    }
                    Divider()
                    Button(role: .destructive) {
                        selectedProcessID = id
                        showingKillAlert = true
                    } label: {
                        Label("结束进程 \(process.displayName) (\(process.pid))", systemImage: "xmark.circle")
                    }
                }
            }
        }
        .onAppear {
            processManager.refreshProcesses()
        }
        .alert("完整路径", isPresented: $showingPathAlert) {
            Button("复制") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(pathToShow, forType: .string)
            }
            Button("关闭", role: .cancel) { }
        } message: {
            Text(pathToShow)
        }
        .alert("确认结束进程", isPresented: $showingKillAlert, presenting: selectedProcess) { process in
            Button("取消", role: .cancel) { }
            Button("结束进程", role: .destructive) {
                if processManager.killProcess(pid: process.pid) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        processManager.refreshProcesses()
                    }
                }
            }
        } message: { process in
            Text("确定要结束进程 \(process.displayName) (PID: \(process.pid)) 吗？")
        }
    }
}

#Preview {
    ContentView()
}
