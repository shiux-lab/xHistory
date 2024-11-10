//
//  SyntaxHighlighter.swift
//  xHistory
//
//  Created by apple on 2024/11/6.
//

import SwiftUI
import Foundation
import SwiftTreeSitter
import TreeSitterBash

/*struct SyntaxHighlighter {
    let commandStyle = AttributeContainer([.foregroundColor: NSColor.systemOrange])
    let parameterStyle = AttributeContainer([.foregroundColor: NSColor.systemGreen])
    let optionStyle = AttributeContainer([.foregroundColor: NSColor.systemMint])
    let symbolStyle = AttributeContainer([.foregroundColor: NSColor.systemGray])
    let stringStyle = AttributeContainer([.foregroundColor: NSColor.textColor])
    
    func highlightBashSyntax(in command: String) -> AttributedString {
        var attributedString = AttributedString(command)
        
        let patterns: [(String, AttributeContainer)] = [
            // 匹配闭合的引号内的内容（包括引号本身）
            (#"(['\"`]).*?\1"#, parameterStyle),
            // 匹配操作符 | 或 ; 或 &
            (#"[\|;&]\s*"#, symbolStyle),
            // 匹配行首的命令和 | 或 ; 后的命令
            (#"(?<=^|[;|]\x{200B}\s?)(\S+)"#, commandStyle),
            // 匹配以 - 或 -- 开头的选项
            (#"(?<=\s\x{200B})-\S+"#, optionStyle),
            // 匹配不被空格分隔的路径或 URL
            //(#"(?<=\s|^)([^\s'\"|;]+(?:\\\s[^\s'\"|;]+)*)"#, stringStyle)
        ]
        
        for (pattern, style) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let nsRange = NSRange(command.startIndex..<command.endIndex, in: command)
                let matches = regex.matches(in: command, options: [], range: nsRange)
                
                for match in matches {
                    if let range = Range(match.range, in: command),
                       let attributedRange = Range(range, in: attributedString) {
                        attributedString[attributedRange].mergeAttributes(style, mergePolicy: .keepCurrent)
                    }
                }
            }
        }
        return attributedString
    }
}*/

class SyntaxHighlighter {
    static let shared = SyntaxHighlighter()
    private var cache = NSCache<NSString, NSAttributedString>()
    @AppStorage("highlighting") var highlighting = true
    
    func getHighlightedText(for source: String) -> NSAttributedString {
        if let cachedResult = cache.object(forKey: source as NSString) {
            return cachedResult
        } else {
            let highlightedText = bashHighlighter(source)
            cache.setObject(highlightedText, forKey: source as NSString)
            return highlightedText
        }
    }
    
    func clearCache() { cache.removeAllObjects() }

    func getHighlightedTextAsync(for source: String, completion: @escaping (NSAttributedString) -> Void) {
        if let cachedResult = cache.object(forKey: source as NSString) {
            completion(cachedResult)
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                let highlightedText = self.bashHighlighter(source)
                self.cache.setObject(highlightedText, forKey: source as NSString)
                DispatchQueue.main.async { completion(highlightedText) }
            }
        }
    }
    
    func bashHighlighter(_ source: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: source)
        if !highlighting { return attributedString }
        do {
            let bashConfig = try LanguageConfiguration(tree_sitter_bash(), name: "Bash")
            let parser = Parser()
            try parser.setLanguage(bashConfig.language)
            let tree = parser.parse(source)!
            let query = bashConfig.queries[.highlights]!
            let cursor = query.execute(in: tree)
            let highlights = cursor
                .resolve(with: .init(string: source))
                .highlights()
            
            let colorMap: [String: NSColor] = [
                "function": ud.nsColor(forKey: "functionColor") ?? .systemOrange,
                "keyword": ud.nsColor(forKey: "keywordColor") ?? .systemPink,
                "string": ud.nsColor(forKey: "stringColor") ?? .systemGreen,
                "comment": .gray,
                "property": ud.nsColor(forKey: "propertyColor") ?? .systemBlue,
                "operator": ud.nsColor(forKey: "operatorColor") ?? .systemGray,
                "constant": ud.nsColor(forKey: "constantColor") ?? .systemMint,
                "number": ud.nsColor(forKey: "numberColor") ?? .red,
                "embedded": ud.nsColor(forKey: "embeddedColor") ?? .systemPurple
            ]
            
            for highlight in highlights {
                let type = highlight.name
                let color = colorMap[type] ?? .labelColor
                let range = NSRange(location: highlight.range.location, length: highlight.range.length)
                attributedString.addAttribute(.foregroundColor, value: color, range: range)
            }
        } catch {
            print("Error parsing source code: \(error)")
        }
        
        return attributedString
    }
    
    /*func bashHighlighterList(_ source: String) -> [AttributedString] {
        let attributedString = NSMutableAttributedString(string: source)
        var result: [AttributedString] = []
        var currentSubstring = NSMutableAttributedString()
        var currentColor: NSColor? = nil

        do {
            let bashConfig = try LanguageConfiguration(tree_sitter_bash(), name: "Bash")
            let parser = Parser()
            try parser.setLanguage(bashConfig.language)
            let tree = parser.parse(source)!
            let query = bashConfig.queries[.highlights]!
            let cursor = query.execute(in: tree)
            let highlights = cursor
                .resolve(with: .init(string: source))
                .highlights()

            let colorMap: [String: NSColor] = [
                "function": .systemOrange,
                "keyword": .systemPink,
                "string": .systemGreen,
                "comment": .systemGray,
                "property": .systemBlue,
                "constant": .systemMint,
                "number": .systemRed,
                "embedded": .systemPurple
            ]

            var lastIndex = 0

            for highlight in highlights {
                let type = highlight.name
                //if type == "operator" { continue }
                
                let color = colorMap[type] ?? .labelColor
                let range = NSRange(location: highlight.range.location, length: highlight.range.length)

                // 添加未标记的普通字符串部分
                if range.location > lastIndex {
                    let unhighlightedRange = NSRange(location: lastIndex, length: range.location - lastIndex)
                    let unhighlightedText = attributedString.attributedSubstring(from: unhighlightedRange)
                    appendUnhighlightedText(unhighlightedText, to: &result)
                }

                // 获取高亮内容
                let highlightText = attributedString.attributedSubstring(from: range)
                if color != currentColor {
                    if currentSubstring.length > 0 {
                        result.append(AttributedString(currentSubstring))
                    }
                    currentSubstring = NSMutableAttributedString(attributedString: highlightText)
                    currentSubstring.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: currentSubstring.length))
                    currentColor = color
                } else {
                    currentSubstring.append(highlightText)
                }

                lastIndex = range.location + range.length
            }

            if currentSubstring.length > 0 {
                result.append(AttributedString(currentSubstring))
            }

            // 添加剩余的未标记普通字符串部分
            if lastIndex < attributedString.length {
                let remainingRange = NSRange(location: lastIndex, length: attributedString.length - lastIndex)
                let remainingText = attributedString.attributedSubstring(from: remainingRange)
                appendUnhighlightedText(remainingText, to: &result)
            }

        } catch {
            print("Error parsing source code: \(error)")
        }

        return result.filter { !$0.characters.isEmpty && String($0.characters) != " " }
    }

    // 分离未标记的普通字符串，处理空格分隔
    private func appendUnhighlightedText(_ unhighlightedText: NSAttributedString, to result: inout [AttributedString]) {
        let plainText = unhighlightedText.string
        var lastStartIndex = plainText.startIndex
        var currentIndex = plainText.startIndex

        while currentIndex < plainText.endIndex {
            if plainText[currentIndex] == " " {
                // 检查是否为反斜线转义的空格
                if currentIndex > plainText.startIndex, plainText[plainText.index(before: currentIndex)] != "\\" {
                    let substring = String(plainText[lastStartIndex..<currentIndex])
                    if !substring.isEmpty {
                        result.append(AttributedString(substring.trimmingCharacters(in: .whitespaces)))
                    }
                    lastStartIndex = plainText.index(after: currentIndex)
                }
            }
            currentIndex = plainText.index(after: currentIndex)
        }

        // 处理最后一个片段
        let lastSubstring = String(plainText[lastStartIndex..<plainText.endIndex])
        if !lastSubstring.isEmpty {
            result.append(AttributedString(lastSubstring.trimmingCharacters(in: .whitespaces)))
        }
    }*/
}
