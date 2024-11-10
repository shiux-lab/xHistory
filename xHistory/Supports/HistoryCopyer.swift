//
//  HistoryCopyer.swift
//  xHistory
//
//  Created by apple on 2024/11/5.
//

import SwiftUI
import SFSMonitor
import Foundation
import TreeSitterBash

class HistoryCopyer: ObservableObject, SFSMonitorDelegate {
    static var shared: HistoryCopyer = HistoryCopyer()
    
    @Published var historys: [String] = []
    @AppStorage("historyFile") var historyFile = "~/.bash_history"
    
    let monitorDispatchQueue =  DispatchQueue(label: "monitorDispatchQueue", qos: .utility)
    private var lastUpdate = Date().timeIntervalSince1970
    
    func receivedNotification(_ notification: SFSMonitorNotification, url: URL, queue: SFSMonitor) {
        monitorDispatchQueue.async(flags: .barrier) {
            let now = Date().timeIntervalSince1970
            let add = notification.toStrings().map({ $0.rawValue }).contains("Write")
            if add && now - self.lastUpdate > 0.1{
                self.lastUpdate = Date().timeIntervalSince1970
                self.updateHistory()
            }
        }
    }
    
    func createEmptyFile(at fileURL: URL) throws {
        if !fd.fileExists(atPath: fileURL.path) {
            do {
                try fd.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                fd.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            } catch {
                print("Cannot create data file: \(error)")
            }
        }
    }
    
    func appendLine(to fileURL: URL, line: String) throws {
        let newLine = line + "\n"
        
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            if let data = newLine.data(using: .utf8) { fileHandle.write(data) }
        } else {
            try newLine.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
    
    func readHistory(file: String? = nil) -> [String] {
        @AppStorage("historyFile") var historyFile = "~/.bash_history"
        @AppStorage("noSameLine") var noSameLine = true
        
        let fileURL = historyFile.absolutePath.url
        let lines = fileURL.readHistory?.components(separatedBy: .newlines).filter({ !$0.trimmingCharacters(in: .whitespaces).isEmpty })  ?? []
        if noSameLine { return lines.removingAdjacentDuplicates() }
        return lines
    }
    
    func updateHistory(file: String? = nil) {
        DispatchQueue.main.async {
            if NSApp.windows.first(where: { $0.title == "xHistory Panel".local && $0.isVisible }) != nil || menuPopover.isShown {
                self.historys = self.readHistory(file: file).reversed()
            }
        }
    }
}

extension Array where Element: Equatable {
    func removingAdjacentDuplicates() -> [Element] {
        reduce(into: []) { result, element in
            if result.last != element {
                result.append(element)
            }
        }
    }
}
