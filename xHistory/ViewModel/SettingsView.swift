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
                NavigationLink(destination: CloudView(), tag: "Cloud", selection: $selectedItem) {
                    Label("Cloud", image: "cloud")
                }
                NavigationLink(destination: BlacklistView(), tag: "Blacklist", selection: $selectedItem) {
                    Label("Blacklist", image: "block")
                }
            }
            .listStyle(.sidebar)
            .padding(.top, 9)
        }
        .frame(width: 600, height: 442)
        .navigationTitle("xHistory Settings")
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

extension KeyboardShortcuts.Name {
    static let showPanel = Self("showPanel")
    static let showPinnedPanel = Self("showPinnedPanel")
    static let showOverlay = Self("showOverlay")
    static let showPinnedOverlay = Self("showPinnedOverlay")
    //static let swapButtons = Self("switchButtons")
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

#Preview {
    SettingsView()
}
