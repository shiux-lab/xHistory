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
    
    func readHistory(file: String? = nil) -> [String] {
        @AppStorage("historyFile") var historyFile = "~/.bash_history"
        @AppStorage("noSameLine") var noSameLine = true
        @AppStorage("preFormatter") var preFormatter = ""
        let blockedItems = (ud.object(forKey: "blockedCommands") as? [String]) ?? []
        
        let fileURL = historyFile.absolutePath.url
        var lines = fileURL.readHistory?.components(separatedBy: .newlines).map({ $0.trimmingCharacters(in: .whitespaces) }) ?? []
        lines = lines.filter({ !$0.trimmingCharacters(in: .whitespaces).isEmpty })
        lines.removeAll(where: { blockedItems.contains($0) })
        if preFormatter != "" { lines = lines.format(usingRegex: preFormatter) }
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
