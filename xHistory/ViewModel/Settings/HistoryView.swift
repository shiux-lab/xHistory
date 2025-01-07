//
//  HistoryView.swift
//  xHistory
//
//  Created by Dropout on 2025/1/7.
//

import SwiftUI

struct HistoryView: View {
    @AppStorage("historyFile") var historyFile = "~/.bash_history"
    @AppStorage("isOhmyzsh") var isOhmyzsh = false
    @AppStorage("autoClose") var autoClose = false
    @AppStorage("autoSpace") var autoSpace = false
    @AppStorage("noSameLine") var noSameLine = true
    @AppStorage("highlighting") var highlighting = true
    @AppStorage("autoReturn") var autoReturn = false
    
    @State private var userPath: String = ""
    @State private var disabled: Bool = false
    @State private var styleChanged: Bool = false
    @State private var functionColor: Color = ud.color(forKey: "functionColor") ?? Color(nsColor: .systemOrange)
    @State private var keywordColor: Color = ud.color(forKey: "keywordColor") ?? Color(nsColor: .systemPink)
    @State private var stringColor: Color = ud.color(forKey: "stringColor") ?? Color(nsColor: .systemGreen)
    @State private var propertyColor: Color = ud.color(forKey: "propertyColor") ?? Color(nsColor: .systemBlue)
    @State private var operatorColor: Color = ud.color(forKey: "operatorColor") ?? Color(nsColor: .systemGray)
    @State private var constantColor: Color = ud.color(forKey: "constantColor") ?? Color(nsColor: .systemMint)
    @State private var numberColor: Color = ud.color(forKey: "numberColor") ?? Color(nsColor: .red)
    @State private var embeddedColor: Color = ud.color(forKey: "embeddedColor") ?? Color(nsColor: .systemPurple)
    
    var body: some View {
        SForm {
            SGroupBox(label: "History") {
                SPicker("Read History From", selection: $historyFile.animation(.easeInOut)) {
                    Text("Zsh").tag("~/.zsh_history")
                    Text("Bash").tag("~/.bash_history")
                    if historyFile != "~/.bash_history" && historyFile != "~/.zsh_history" {
                        Text("Custom").tag(historyFile)
                    } else {
                        Text("Custom").tag(historyFile.absolutePath)
                    }
                }.onChange(of: historyFile) { newValue in
                    HistoryCopyer.shared.updateHistory()
                    for cmd in HistoryCopyer.shared.historys {
                        SyntaxHighlighter.shared.getHighlightedTextAsync(for: cmd.command) { _ in }
                    }
                    queue?.removeAllURLs()
                    DispatchQueue.main.async {
                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
                            if queue?.numberOfWatchedURLs() == 0 {
                                timer.invalidate()
                                _ = queue?.addURL(historyFile.absolutePath.url)
                            }
                        }
                    }
                }
                if historyFile == "~/.zsh_history" {
                    SToggle("The one used is ohmyzsh", isOn: $isOhmyzsh, tips: "This will identify the execution timestamp of the command.")
                }
                SDivider()
                if historyFile != "~/.bash_history" && historyFile != "~/.zsh_history" {
                    HStack {
                        SField("Custom History File Path", text: $userPath)
                        Button("Save") { historyFile = userPath }
                    }
                    SDivider()
                }
                SToggle("Merge adjacent duplicates", isOn: $noSameLine)
                SDivider()
                SToggle("Close history panel after filling", isOn: $autoClose)
                SToggle("Auto-press Return after filling", isOn: $autoReturn)
                SToggle("Add trailing space when filling", isOn: $autoSpace)
            }
            SGroupBox(label: "Highlight") {
                SToggle("Syntax Highlighting", isOn: $highlighting)
                SDivider()
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Highlight Color Scheme")
                        Text("Hover over a color to see more information and click to modify it.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        functionColor = Color(nsColor: .systemOrange)
                        keywordColor = Color(nsColor: .systemPink)
                        stringColor = Color(nsColor: .systemGreen)
                        propertyColor = Color(nsColor: .systemBlue)
                        operatorColor = Color(nsColor: .systemGray)
                        constantColor = Color(nsColor: .systemMint)
                        numberColor = Color(nsColor: .red)
                        embeddedColor = Color(nsColor: .systemPurple)
                    }, label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                    })
                    .buttonStyle(.plain)
                    .help("Reset Color Scheme")
                    Button("Save") { HistoryCopyer.shared.reHighlight() }
                }.disabled(!highlighting)
                HStack {
                    CS(tips: "The color of keywords in the code", name: "keywordColor", selection: $keywordColor, styleChanged: $styleChanged)
                    CS(tips: "The color of functions in the code", name: "functionColor", selection: $functionColor, styleChanged: $styleChanged)
                    CS(tips: "The color of constants in the code", name: "constantColor", selection: $constantColor, styleChanged: $styleChanged)
                    CS(tips: "The color of properties in the code", name: "propertyColor", selection: $propertyColor, styleChanged: $styleChanged)
                    CS(tips: "The color of operators in the code", name: "operatorColor", selection: $operatorColor, styleChanged: $styleChanged)
                    CS(tips: "The color of strings in the code", name: "stringColor", selection: $stringColor, styleChanged: $styleChanged)
                    CS(tips: "The color of embedded code in the code", name: "embeddedColor", selection: $embeddedColor, styleChanged: $styleChanged)
                    CS(tips: "The color of numbers in the code", name: "numberColor", selection: $numberColor, styleChanged: $styleChanged)
                }
                .frame(height: 16)
                .padding(.bottom, 3)
                .disabled(disabled)
            }
        }
        .onAppear { userPath = historyFile }
        .onChange(of: historyFile) { newValue in userPath = newValue }
        .onChange(of: highlighting) { newValue in
            disabled = !newValue
            HistoryCopyer.shared.reHighlight()
        }
    }
}

#Preview {
    HistoryView()
}
