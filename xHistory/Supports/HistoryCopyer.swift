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

let archiveTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

class HistoryCopyer: ObservableObject, SFSMonitorDelegate {
    static var shared: HistoryCopyer = HistoryCopyer()
    
    var needArchive: Bool = false
    var lastUpdate = Date().timeIntervalSince1970
    
    @Published var historys: [String] = []
    @AppStorage("historyFile") var historyFile = "~/.bash_history"
    @AppStorage("cloudSync") var cloudSync = false
    @AppStorage("cloudDirectory") var cloudDirectory = ""
    
    private let monitorDispatchQueue =  DispatchQueue(label: "monitorDispatchQueue", qos: .utility)
    
    
    func receivedNotification(_ notification: SFSMonitorNotification, url: URL, queue: SFSMonitor) {
        monitorDispatchQueue.async(flags: .barrier) {
            let now = Date().timeIntervalSince1970
            let add = notification.toStrings().map({ $0.rawValue }).contains("Write")
            if add && now - self.lastUpdate > 0.1{
                self.lastUpdate = Date().timeIntervalSince1970
                self.updateHistory()
                if self.cloudSync && self.cloudDirectory != "" { self.needArchive = true }
            }
        }
    }
    
    func readHistory(file: String? = nil) -> [String] {
        @AppStorage("historyFile") var historyFile = "~/.bash_history"
        @AppStorage("noSameLine") var noSameLine = true
        @AppStorage("preFormatter") var preFormatter = ""
        let blockedItems = (ud.object(forKey: "blockedCommands") as? [String]) ?? []
        
        var fileURL = historyFile.absolutePath.url
        if let file = file { fileURL = file.absolutePath.url }
        var lines = fileURL.readHistory?.components(separatedBy: .newlines).map({ $0.trimmingCharacters(in: .whitespaces) }) ?? []
        lines = lines.filter({ !$0.isEmpty })
        if preFormatter != "" { lines = lines.format(usingRegex: preFormatter) }
        let normalBlock = blockedItems.filter({ !$0.startsWith(character: "#") })
        let regexBlock = blockedItems.filter({ $0.startsWith(character: "#") }).map({ String($0.dropFirst()) })
        lines.removeAll(where: { normalBlock.contains($0) })
        lines = filterNonMatchingStrings(regexList: regexBlock, stringList: lines)
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
    
    func reHighlight() {
        SyntaxHighlighter.shared.clearCache()
        HistoryCopyer.shared.historys.removeAll()
        HistoryCopyer.shared.updateHistory()
        for cmd in HistoryCopyer.shared.readHistory() {
            SyntaxHighlighter.shared.getHighlightedTextAsync(for: cmd) { _ in }
        }
    }
    
    func filterNonMatchingStrings(regexList: [String], stringList: [String]) -> [String] {
        let regexPatterns = regexList.compactMap { pattern in
            try? NSRegularExpression(pattern: pattern)
        }
        let nonMatchingStrings = stringList.filter { string in
            for regex in regexPatterns {
                let range = NSRange(location: 0, length: string.utf16.count)
                if regex.firstMatch(in: string, options: [], range: range) != nil {
                    return false
                }
            }
            return true
        }
        return nonMatchingStrings
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

extension Array where Element == String {
    func format(usingRegex regexPattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regexPattern)
            return self.compactMap { element in
                // 转换为 NSRange
                let range = NSRange(element.startIndex..<element.endIndex, in: element)
                
                if let match = regex.firstMatch(in: element, options: [], range: range),
                   match.numberOfRanges > 1,  // 确保捕获组范围存在
                   let commandRange = Range(match.range(at: 1), in: element) {
                    return String(element[commandRange])
                }
                
                return nil
            }
        } catch {
            //print("Invalid regular expression: \(error)")
            return []
        }
    }
}

extension URL {
    var lastLine: String? {
        do {
            return try self.readLastLine
        } catch {
            return self.readLastLineZ
        }
    }
    
    var isFileUTF8Encoded: Bool {
        do {
            _ = try String(contentsOf: self, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }
    
    var readHistory: String? {
        do {
            return try String(contentsOf: self, encoding: .utf8)
        } catch {
            return self.readZshHistory
        }
    }
    
    private var readZshHistory: String? {
        var zshHistoryContent = ""
        func unmetafy(_ bytes: inout [UInt8]) -> String {
            var index = 0
            let zshMeta: UInt8 = 0x83
            
            while index < bytes.count {
                if bytes[index] == zshMeta {
                    bytes.remove(at: index)
                    if index < bytes.count { bytes[index] ^= 32 }
                } else {
                    index += 1
                }
            }
            return String(decoding: bytes, as: UTF8.self)
        }
        
        if let fileHandle = FileHandle(forReadingAtPath: self.path) {
            defer { fileHandle.closeFile() }
            let data = fileHandle.readDataToEndOfFile()
            let lines = data.split(separator: 0x0A)
            for lineData in lines {
                var lineBytes = [UInt8](lineData)
                let processedLine = unmetafy(&lineBytes)
                zshHistoryContent += "\(processedLine)\n"
            }
            return zshHistoryContent
        }
        return nil
    }
    
    private var readLastLine: String? {
        get throws {
            guard let fileHandle = try? FileHandle(forReadingFrom: self) else {
                return nil
            }
            defer { fileHandle.closeFile() }
            
            var offset = fileHandle.seekToEndOfFile()
            var lineData = Data()
            
            while offset > 0 {
                offset -= 1
                fileHandle.seek(toFileOffset: offset)
                let data = fileHandle.readData(ofLength: 1)
                
                if let character = String(data: data, encoding: .utf8), character == "\n" {
                    if !lineData.isEmpty {
                        break
                    }
                } else {
                    lineData.insert(contentsOf: data, at: 0)
                }
            }
            
            if offset == 0 && lineData.isEmpty {
                fileHandle.seek(toFileOffset: 0)
                lineData = fileHandle.readDataToEndOfFile()
            }
            
            guard let lastLine = String(data: lineData, encoding: .utf8) else {
                throw NSError(domain: "FileReadError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode UTF-8"])
            }
            
            return lastLine
        }
    }
    
    private var readLastLineZ: String? {
        func unmetafy(_ bytes: inout [UInt8]) -> String {
            var index = 0
            let zshMeta: UInt8 = 0x83
            
            while index < bytes.count {
                if bytes[index] == zshMeta {
                    bytes.remove(at: index)
                    if index < bytes.count { bytes[index] ^= 32 }
                } else {
                    index += 1
                }
            }
            return String(decoding: bytes, as: UTF8.self)
        }
        
        guard let fileHandle = FileHandle(forReadingAtPath: self.path) else { return nil }
        defer { fileHandle.closeFile() }
        
        let bufferSize = 1024
        var offset = fileHandle.seekToEndOfFile()
        var lastLineData = Data()
        
        while offset > 0 {
            let bytesToRead = min(offset, UInt64(bufferSize))
            offset -= bytesToRead
            fileHandle.seek(toFileOffset: offset)
            var data = fileHandle.readData(ofLength: Int(bytesToRead))
            if data.last == 0x0A { data = data.dropLast() }
            if let range = data.range(of: Data([0x0A]), options: .backwards) {
                lastLineData = data.suffix(from: range.upperBound) + lastLineData
                break
            } else {
                lastLineData = data + lastLineData
            }
        }
        
        if lastLineData.isEmpty {
            fileHandle.seek(toFileOffset: 0)
            lastLineData = fileHandle.readDataToEndOfFile()
        }
        
        //lastLineData.append(0x0A)
        if lastLineData.isEmpty { return nil }
        
        var lineBytes = [UInt8](lastLineData)
        let processedLine = unmetafy(&lineBytes)
        return "\(processedLine)\n"
    }
}
