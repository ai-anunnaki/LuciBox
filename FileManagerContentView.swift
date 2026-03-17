import SwiftUI

struct FileManagerContentView: View {
    @StateObject private var fileManager = FileManager()
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var showingRenameAlert = false
    @State private var renameText = ""
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    
    var filteredFiles: [FileItem] {
        if searchText.isEmpty {
            return fileManager.files
        }
        return fileManager.files.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 路径导航栏
            HStack {
                Button(action: { fileManager.goUp() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(fileManager.currentPath.path == "/")
                
                Text(fileManager.currentPath.path)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                Button(action: { showingNewFolderAlert = true }) {
                    Label("新建文件夹", systemImage: "folder.badge.plus")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜索文件", text: $searchText)
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
            
            // 文件列表
            Table(filteredFiles, selection: $fileManager.selectedFileID) {
                TableColumn("名称") { item in
                    HStack {
                        Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                            .foregroundColor(item.isDirectory ? .blue : .gray)
                        Text(item.name)
                    }
                }
                .width(min: 200)
                
                TableColumn("大小") { item in
                    Text(item.sizeString)
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 80, max: 120)
                
                TableColumn("修改时间") { item in
                    Text(item.modifiedDate, style: .date)
                        .font(.system(.caption))
                }
                .width(min: 100)
                
                TableColumn("操作") { item in
                    HStack(spacing: 4) {
                        Button(action: {
                            if item.isDirectory {
                                fileManager.navigateTo(item.url)
                            } else {
                                NSWorkspace.shared.open(item.url)
                            }
                        }) {
                            Image(systemName: item.isDirectory ? "arrow.right.circle" : "eye")
                        }
                        .buttonStyle(.borderless)
                        
                        Button(action: {
                            fileManager.selectedFileID = item.id
                            renameText = item.name
                            showingRenameAlert = true
                        }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)
                        
                        Button(action: {
                            fileManager.selectedFileID = item.id
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                        
                        Button(action: {
                            fileManager.revealInFinder(item)
                        }) {
                            Image(systemName: "folder")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .width(min: 120, max: 120)
            }
        }
        .alert("新建文件夹", isPresented: $showingNewFolderAlert) {
            TextField("文件夹名称", text: $newFolderName)
            Button("取消", role: .cancel) { newFolderName = "" }
            Button("创建") {
                _ = fileManager.createFolder(name: newFolderName)
                newFolderName = ""
            }
        }
        .alert("重命名", isPresented: $showingRenameAlert, presenting: fileManager.selectedFile) { item in
            TextField("新名称", text: $renameText)
            Button("取消", role: .cancel) { }
            Button("重命名") {
                _ = fileManager.renameFile(item, newName: renameText)
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert, presenting: fileManager.selectedFile) { item in
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                _ = fileManager.deleteFile(item)
            }
        } message: { item in
            Text("确定要删除 \(item.name) 吗？文件将被移到废纸篓。")
        }
    }
}
