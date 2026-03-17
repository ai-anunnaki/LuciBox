import Foundation
import AppKit

struct FileItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modifiedDate: Date
    
    var sizeString: String {
        if isDirectory { return "-" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

class FileManager: ObservableObject {
    @Published var currentPath: URL
    @Published var files: [FileItem] = []
    @Published var selectedFileID: UUID?
    var selectedFile: FileItem? { files.first { $0.id == selectedFileID } }
    
    private let fileManager = Foundation.FileManager.default
    
    init() {
        self.currentPath = URL(fileURLWithPath: NSHomeDirectory())
        loadFiles()
    }
    
    func loadFiles() {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: currentPath,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            var items: [FileItem] = []
            for url in contents {
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                
                let item = FileItem(
                    url: url,
                    name: url.lastPathComponent,
                    isDirectory: resourceValues.isDirectory ?? false,
                    size: Int64(resourceValues.fileSize ?? 0),
                    modifiedDate: resourceValues.contentModificationDate ?? Date()
                )
                items.append(item)
            }
            
            DispatchQueue.main.async {
                self.files = items.sorted { item1, item2 in
                    if item1.isDirectory != item2.isDirectory {
                        return item1.isDirectory
                    }
                    return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
                }
            }
        } catch {
            print("Error loading files: \(error)")
        }
    }
    
    func navigateTo(_ url: URL) {
        currentPath = url
        loadFiles()
    }
    
    func goUp() {
        let parent = currentPath.deletingLastPathComponent()
        if parent.path != currentPath.path {
            navigateTo(parent)
        }
    }
    
    func createFolder(name: String) -> Bool {
        let newURL = currentPath.appendingPathComponent(name)
        do {
            try fileManager.createDirectory(at: newURL, withIntermediateDirectories: false)
            loadFiles()
            return true
        } catch {
            return false
        }
    }
    
    func deleteFile(_ item: FileItem) -> Bool {
        do {
            try fileManager.trashItem(at: item.url, resultingItemURL: nil)
            loadFiles()
            return true
        } catch {
            return false
        }
    }
    
    func renameFile(_ item: FileItem, newName: String) -> Bool {
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try fileManager.moveItem(at: item.url, to: newURL)
            loadFiles()
            return true
        } catch {
            return false
        }
    }
    
    func copyFile(_ item: FileItem, to destination: URL) -> Bool {
        let destURL = destination.appendingPathComponent(item.name)
        do {
            try fileManager.copyItem(at: item.url, to: destURL)
            return true
        } catch {
            return false
        }
    }
    
    func moveFile(_ item: FileItem, to destination: URL) -> Bool {
        let destURL = destination.appendingPathComponent(item.name)
        do {
            try fileManager.moveItem(at: item.url, to: destURL)
            loadFiles()
            return true
        } catch {
            return false
        }
    }
    
    func revealInFinder(_ item: FileItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }
}
