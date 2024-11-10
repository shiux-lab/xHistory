//
//  SettingsView.swift
//  xHistory
//
//  Created by apple on 2024/11/6.
//

import SwiftUI
import ServiceManagement
import KeyboardShortcuts
import MatrixColorSelector

struct SettingsView: View {
    @State private var selectedItem: String? = "General"
    
    var body: some View {
        NavigationView {
            List(selection: $selectedItem) {
                NavigationLink(destination: GeneralView(), tag: "General", selection: $selectedItem) {
                    Label("General", image: "gear")
                }
                NavigationLink(destination: HistoryView(), tag: "History", selection: $selectedItem) {
                    Label("History", image: "history")
                }
                NavigationLink(destination: HotkeyView(), tag: "Hotkey", selection: $selectedItem) {
                    Label("Hotkey", image: "hotkey")
                }
                NavigationLink(destination: ShellView(), tag: "Shell", selection: $selectedItem) {
                    Label("Shell", image: "shell")
                }
            }
            .listStyle(.sidebar)
            .padding(.top, 9)
        }
        .frame(width: 600, height: 410)
        .navigationTitle("xHistory Settings")
    }
}

struct GeneralView: View {
    @AppStorage("panelOpacity") var panelOpacity = 100
    @AppStorage("statusBar") var statusBar = true
    @AppStorage("statusIconName") var statusIconName = "menuBar"
    
    @State private var launchAtLogin = false
    
    var body: some View {
        SForm {
            SGroupBox(label: "General") {
                if #available(macOS 13, *) {
                    SToggle("Launch at Login", isOn: $launchAtLogin)
                        .onAppear{ launchAtLogin = (SMAppService.mainApp.status == .enabled) }
                        .onChange(of: launchAtLogin) { newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            }catch{
                                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
                            }
                        }
                    SDivider()
                }
                HStack(spacing: 4) {
                    Text("Show Menu bar Icon")
                    Spacer()
                    Button(action: {
                        if let button = statusBarItem.button {
                            if statusIconName == "menuBar" {
                                statusIconName = "menuBarInvert"
                            } else {
                                statusIconName = "menuBar"
                            }
                            button.image = NSImage(named: statusIconName)
                        }
                    }, label: {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                    })
                    .buttonStyle(.plain)
                    .help("Change icon style")
                    Toggle("", isOn: $statusBar)
                        .toggleStyle(.switch)
                        .scaleEffect(0.7)
                        .frame(width: 32)
                        
                }.frame(height: 16)
                SDivider()
                HStack {
                    SSlider(label: "History Panel Opacity", value: $panelOpacity, range: 10...100, width: 160)
                    Text("\(panelOpacity)%").frame(width: 35)
                }
            }.onChange(of: statusBar) { newValue in statusBarItem.isVisible = newValue }
            SGroupBox(label: "Update") { UpdaterSettingsView(updater: updaterController.updater) }
            VStack(spacing: 8) {
                CheckForUpdatesView(updater: updaterController.updater)
                if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("xHistory v\(appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct HistoryView: View {
    @AppStorage("historyFile") var historyFile = "~/.bash_history"
    @AppStorage("autoClose") var autoClose = false
    @AppStorage("autoSpace") var autoSpace = false
    @AppStorage("noSameLine") var noSameLine = true
    @AppStorage("highlighting") var highlighting = true
    
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
                SPicker("Read History From", selection: $historyFile) {
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
                        SyntaxHighlighter.shared.getHighlightedTextAsync(for: cmd) { _ in }
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
                SDivider()
                if historyFile != "~/.bash_history" && historyFile != "~/.zsh_history" {
                    SField("Custom History File Path", text: $historyFile)
                    SDivider()
                }
                SToggle("Merge adjacent duplicates", isOn: $noSameLine)
                SDivider()
                SToggle("Close the panel after filling", isOn: $autoClose)
                SDivider()
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
                            .foregroundColor(.secondary)
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
                            .foregroundColor(.secondary)
                    })
                    .buttonStyle(.plain)
                    .help("Reset Color Scheme")
                    Button("Save") { reHeight() }
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
                .disabled(!highlighting)
            }.onChange(of: highlighting) { _ in reHeight() }
        }
    }
    
    func reHeight() {
        SyntaxHighlighter.shared.clearCache()
        HistoryCopyer.shared.historys.removeAll()
        HistoryCopyer.shared.updateHistory()
        for cmd in HistoryCopyer.shared.readHistory() {
            SyntaxHighlighter.shared.getHighlightedTextAsync(for: cmd) { _ in }
        }
    }
}

struct HotkeyView: View {
    var body: some View {
        SForm {
            SGroupBox(label: "Hotkey") {
                SItem(label: "Open History Panel") { KeyboardShortcuts.Recorder("", name: .showPanel) }
                SDivider()
                SItem(label: "Open panel and show pinned history") { KeyboardShortcuts.Recorder("", name: .showPinnedPanel) }
                SDivider()
                SItem(label: "Open History Panel as Overlay") {
                    HStack(spacing: -5) {
                        SInfoButton(tips: "xHistory will detect the current frontmost window and open a floating panel of the same size on top of it.")
                        KeyboardShortcuts.Recorder("", name: .showOverlay)
                    }
                }
                SDivider()
                SItem(label: "Open overlay and show pinned history") {
                    HStack(spacing: -5) {
                        SInfoButton(tips: "xHistory will detect the current frontmost window and open a floating panel of the same size on top of it.")
                        KeyboardShortcuts.Recorder("", name: .showPinnedOverlay)
                    }
                }
            }
        }
    }
}

struct ShellView: View {
    @State private var cltInstalled: Bool = false
    @AppStorage("customShellConfig") var customShellConfig = true
    @AppStorage("historyLimit") var historyLimit = 1000
    @AppStorage("noDuplicates") var noDuplicates = true
    @AppStorage("realtimeSave") var realtimeSave = true
    
    var body: some View {
        SForm(spacing: 10) {
            SGroupBox(label: "Shell Configuration") {
                SToggle("Custom Configuration (for Bash & Zsh)", isOn: $customShellConfig)
                SDivider()
                Group {
                    SToggle("Real-time History Saving", isOn: $realtimeSave)
                    SDivider()
                    SToggle("Ignore Consecutive Duplicates", isOn: $noDuplicates)
                    SDivider()
                    SSteper("Maximum Number of Histories", value: $historyLimit, min: 1, max: 10000, width: 60)
                }.disabled(!customShellConfig)
            }
            SGroupBox {
                SButton("Command Line Tool", buttonTitle: cltInstalled ? "Uninstall" : "Install",
                        tips: "After installation, you can run \"xhistory\" in yor terminal to quickly open the floating panel.") {
                    if cltInstalled {
                        CommandLineTool.uninstall { updateCTL() }
                    } else {
                        CommandLineTool.install { updateCTL() }
                    }
                }.onAppear { cltInstalled = CommandLineTool.isInstalled() }
            }
        }
    }
    
    func updateCTL() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cltInstalled = CommandLineTool.isInstalled()
        }
    }
}

struct CS: View {
    var tips: LocalizedStringKey
    var name: String
    @Binding var selection: Color
    @Binding var styleChanged: Bool
    
    var body: some View {
        HStack {
            if #unavailable(macOS 13) {
                ColorPicker("", selection: $selection).frame(width: 43)
            } else {
                MatrixColorSelector("", selection: $selection)
            }
        }
        .help(tips)
        .onChange(of: selection) { userColor in ud.setColor(userColor, forKey: name); styleChanged = true }
    }
}

extension KeyboardShortcuts.Name {
    static let showPanel = Self("showPanel")
    static let showPinnedPanel = Self("showPinnedPanel")
    static let showOverlay = Self("showOverlay")
    static let showPinnedOverlay = Self("showPinnedOverlay")
}

struct FlowLayout<Content: View>: View {
    var items: [String]
    var spacing: CGFloat
    var content: (String) -> Content

    @State private var totalHeight = CGFloat.zero // Track total height of the layout

    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight) // Set the total height dynamically
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        var lastHeight = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(items.indices, id: \.self) { index in
                content(items[index])
                    .alignmentGuide(.leading) { dimension in
                        if (abs(width - dimension.width) > geometry.size.width) {
                            width = 0 // Move to the next line'
                            height -= lastHeight + spacing
                        }
                        lastHeight = dimension.height // 记录当前元素的高度
                        let result = width
                        if items[index] == items.last! { // Last item
                            width = 0 // Reset width
                        } else {
                            width -= dimension.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if items[index] == items.last! { // 最后一个元素，重置宽度和高度
                            width = 0
                            height = 0
                        }
                        return result
                    }
            }
        }.background(viewHeightReader($totalHeight)) // Capture total height of the layout
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geometry.size.height
            }
            return Color.clear
        }
    }
}

extension UserDefaults {
    func setColor(_ color: Color?, forKey key: String) {
        guard let color = color else {
            removeObject(forKey: key)
            return
        }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: NSColor(color), requiringSecureCoding: false)
            set(data, forKey: key)
        } catch {
            print("Error archiving color:", error)
        }
    }
    
    func color(forKey key: String) -> Color? {
        guard let data = data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
            return nil
        }
        return Color(nsColor)
    }
    
    func nsColor(forKey key: String) -> NSColor? {
        guard let data = data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
            return nil
        }
        return nsColor
    }
    
    func cgColor(forKey key: String) -> CGColor? { return self.nsColor(forKey: key)?.cgColor }
}
