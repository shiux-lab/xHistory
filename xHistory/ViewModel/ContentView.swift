//
//  ContentView.swift
//  xHistory
//
//  Created by apple on 2024/11/5.
//

import Carbon
import SwiftUI

struct ContentView: View {
    @AppStorage("historyFile") var historyFile = "~/.bash_history"
    @AppStorage("panelOpacity") var panelOpacity = 100
    @AppStorage("showPinned") var showPinned = false
    @AppStorage("caseSensitivity") var caseSensitivity = false
    @AppStorage("regexSearch") var regexSearch = false

    @StateObject private var data = HistoryCopyer.shared
    
    @State private var scrollToTop = false
    @State private var keyWord: String = ""
    @State private var showPin: Bool = false
    @State private var overSetting: Bool = false
    @State private var overAbout: Bool = false
    @State private var overQuit: Bool = false
    @State private var result: [String] = []
    @State private var resultP: [String] = []
    @State private var pinnedList = (ud.object(forKey: "pinnedList") ?? []) as! [String]
    
    var fromMenubar: Bool = false
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            if !fromMenubar {
                Color.clear
                    .background(.thinMaterial)
                    .environment(\.controlActiveState, .active)
                    .opacity(Double(panelOpacity) / 100)
            }
            VStack {
                HStack(spacing: 5) {
                    if fromMenubar {
                        Button(action: {
                            NSApp.terminate(self)
                        }, label: {
                            Text("Quit")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                                        .fill(overQuit ? .buttonRed.opacity(0.8) : .buttonRed)
                                )
                        })
                        .buttonStyle(.plain)
                        .padding(.leading, 1)
                        .focusable(false)
                        .onHover { hovering in overQuit = hovering }
                    }
                    Picker("", selection: $showPin) {
                        Text(" History ").tag(false)
                        Text(" Pinned ").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                    .padding(.leading, -8)
                    .focusable(false)
                    Spacer().frame(width: 4)
                    Button(action: {
                        regexSearch.toggle()
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(regexSearch ? .blue : .secondary.opacity(0.8), lineWidth: 1.5)
                                .frame(width: 18, height: 18)
                            HStack(alignment: .bottom, spacing: 1) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 2, weight: .medium))
                                Image(systemName: "asterisk")
                                    .font(.system(size: 7, weight: .black))
                                    .padding(.bottom, 1)
                            }
                            .foregroundColor(regexSearch ? .blue : .secondary.opacity(0.8))
                            .offset(x: 0.5, y: -1)
                        }
                        .frame(width: 18, height: 18)
                        .background(Color.white.opacity(0.0001))
                        
                    })
                    .buttonStyle(.plain)
                    .focusable(false)
                    Button(action: {
                        caseSensitivity.toggle()
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(caseSensitivity ? .blue : .secondary.opacity(0.8), lineWidth: 1.5)
                                .frame(width: 18, height: 18)
                            Image("textformat")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14)
                                .offset(y: -0.5)
                                .foregroundColor(caseSensitivity ? .blue : .secondary.opacity(0.8))
                        }
                        .frame(width: 18, height: 18)
                        .background(Color.white.opacity(0.001))
                    })
                    .buttonStyle(.plain)
                    .focusable(false)
                    .offset(x: 1)
                    SearchField(search: $keyWord)
                        .frame(height: 21)
                        .onChange(of: keyWord) { newValue in
                            result = searchHistory(data.historys)
                            resultP = searchHistory(pinnedList)
                        }
                        .onChange(of: caseSensitivity) { _ in
                            result = searchHistory(data.historys)
                            resultP = searchHistory(pinnedList)
                        }
                        .onChange(of: regexSearch) { _ in
                            result = searchHistory(data.historys)
                            resultP = searchHistory(pinnedList)
                        }
                        .onChange(of: data.historys) { _ in
                            result = searchHistory(data.historys)
                        }
                        .onChange(of: pinnedList) { _ in
                            resultP = searchHistory(pinnedList)
                        }
                    if fromMenubar {
                        HStack(spacing: 4) {
                            Button(action: {
                                openSettingPanel()
                            }, label: {
                                Image(systemName: "gearshape.fill")
                                    .foregroundStyle(overSetting ? .blue : .secondary.opacity(0.8))
                            })
                            .buttonStyle(.plain)
                            .onHover { hovering in overSetting = hovering }
                        }.focusable(false)
                    }
                }.frame(height: 16)
                if showPin {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators:false) {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(keyWord == "" ? pinnedList.indices : resultP.indices, id: \.self) { index in
                                    CommandView(index: index,
                                                command: keyWord == "" ? pinnedList[index] : resultP[index],
                                                pinnedList: $pinnedList,
                                                //scrollToTop: $scrollToTop,
                                                fromMenubar: fromMenubar)
                                    .id(index)
                                    .padding(.horizontal, 1)
                                    .shadow(color: (panelOpacity != 100 && !fromMenubar) ? .clear :.secondary.opacity(0.8), radius: 0.3, y: 0.5)
                                }
                            }.padding(.bottom, 1)
                        }
                        .focusable(false)
                        .mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .onChange(of: scrollToTop) { _ in proxy.scrollTo(0, anchor: .top) }
                    }
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators:false) {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(keyWord == "" ? data.historys.indices : result.indices, id: \.self) { index in
                                    CommandView(index: index,
                                                command: keyWord == "" ? data.historys[index] : result[index],
                                                pinnedList: $pinnedList,
                                                //scrollToTop: $scrollToTop,
                                                fromMenubar: fromMenubar)
                                    .id(index)
                                    .padding(.horizontal, 1)
                                    .shadow(color: (panelOpacity != 100 && !fromMenubar) ? .clear :.secondary.opacity(0.8), radius: 0.3, y: 0.5)
                                }
                            }.padding(.bottom, 1)
                        }
                        .focusable(false)
                        .mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .onChange(of: scrollToTop) { _ in proxy.scrollTo(0, anchor: .top) }
                    }
                }
            }
            .padding(7)
            .padding(.bottom, 1)
            .padding(.top, fromMenubar ? 3 : 21)
            if !fromMenubar {
                HStack(spacing: 6) {
                    Button(action: {
                        mainPanel.close()
                        openAboutPanel()
                    }, label: {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(overAbout ? .blue : .secondary.opacity(0.8))
                    })
                    .buttonStyle(.plain)
                    .onHover { hovering in overAbout = hovering }
                    Button(action: {
                        openSettingPanel()
                    }, label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(overSetting ? .blue : .secondary.opacity(0.8))
                    })
                    .buttonStyle(.plain)
                    .onHover { hovering in overSetting = hovering }
                }
                .focusable(false)
                .padding(.horizontal, 7.5)
                .padding(.vertical, 6)
            }
        }
        .frame(minWidth: 250, minHeight: 87)
        .onAppear { data.historys = data.readHistory().reversed() }
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.secondary.opacity(0.5), lineWidth: fromMenubar ? 0 : 1)
        )
        .background(
            WindowAccessor(onWindowActive: { _ in
                showPin = showPinned
                showPinned = false
            } , onWindowClose: {
                self.scrollToTop.toggle()
                self.keyWord = ""
            })
        )
        .padding(.top, fromMenubar ? 0 : -28)
    }
    
    func openSettingPanel() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.mainMenu?.items.first?.submenu?.item(at: 2)?.performAction()
        }else if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let w = NSApp.windows.first(where: { $0.title == "xHistory Settings".local }) {
                w.level = .floating
                w.titlebarSeparatorStyle = .none
                guard let nsSplitView = self.findNSSplitVIew(view: w.contentView),
                      let controller = nsSplitView.delegate as? NSSplitViewController else { return }
                controller.splitViewItems.first?.canCollapse = false
                controller.splitViewItems.first?.minimumThickness = 140
                controller.splitViewItems.first?.maximumThickness = 140
                w.makeKeyAndOrderFront(nil)
                w.makeKey()
            }
        }
    }
    
    func findNSSplitVIew(view: NSView?) -> NSSplitView? {
        var queue = [NSView]()
        if let root = view { queue.append(root) }
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if current is NSSplitView { return current as? NSSplitView }
            for subview in current.subviews { queue.append(subview) }
        }
        return nil
    }
    
    func searchHistory(_ data: [String]) -> [String] {
        if !keyWord.isEmpty && !(keyWord == "") {
            if regexSearch {
                do {
                    let options: NSRegularExpression.Options = caseSensitivity ? [] : [.caseInsensitive]
                    let regex = try NSRegularExpression(pattern: keyWord, options: options)
                    
                    let matchingItems = data.filter { item in
                        let range = NSRange(location: 0, length: item.utf16.count)
                        return regex.firstMatch(in: item, options: [], range: range) != nil
                    }
                    return matchingItems
                } catch {
                    //print("Invalid regular expression: \(error)")
                    return []
                }
            } else {
                let options: String.CompareOptions = caseSensitivity ? [] : [.caseInsensitive]
                return data.filter { $0.range(of: keyWord, options: options) != nil }
            }
        }
        return data
    }
}

struct CommandView: View {
    var index: Int
    var command: String
    
    @Binding var pinnedList: [String]
    //@Binding var scrollToTop: Bool
    var fromMenubar: Bool = false
    
    @AppStorage("panelOpacity") var panelOpacity = 100
    @AppStorage("autoClose") var autoClose = false
    @AppStorage("autoSpace") var autoSpace = false
    @AppStorage("autoReturn") var autoReturn = false
    @AppStorage("swapButtons") var swapButtons = false
    
    @State private var boomList = [String]()
    @State private var isHovered: Bool = false
    @State private var shwoMore: Bool = false
    @State private var boomMode: Bool = false
    @State private var copyText: Bool = false
    @State private var pinHistory: Bool = false
    @State private var copied: Bool = false
    //@State private var highlightedText: AttributedString = AttributedString("")
    
    var body: some View {
        HStack(spacing: 6) {
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(isHovered ? .white : .primary)
                .padding(.horizontal, 2)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .frame(width: 26)
                .frame(maxHeight: .infinity)
                .background(isHovered ? Color.blue : Color.background.opacity(fromMenubar ? 1 : Double(panelOpacity) / 100))
                .mask(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isHovered = hovering
                    }
                }
            HStack(spacing: 0) {
                if swapButtons {
                    HStack(spacing: 5) {
                        Button(action: {
                            copyToPasetboard(text: command)
                            copied = true
                            withAnimation(.easeInOut(duration: 1)) { copied = false }
                        }, label: {
                            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.clipboard")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(copyText ? .blue : .secondary)
                                .frame(width: 12)
                                .frame(maxHeight: .infinity)
                        })
                        .buttonStyle(.plain)
                        .onHover { hovering in copyText = hovering }
                        Button(action: {
                            if pinnedList.contains(command) {
                                pinnedList.removeAll(where: { $0 == command })
                            } else {
                                pinnedList.append(command)
                            }
                            ud.set(pinnedList, forKey: "pinnedList")
                        }, label: {
                            Image(systemName: pinnedList.contains(command) ? "pin.fill" : "pin")
                                .font(.system(size: 13, weight: .medium))
                                .rotationEffect(.degrees(45))
                                .foregroundColor(pinHistory ? .blue : .secondary)
                                .frame(width: 14)
                                .frame(maxHeight: .infinity)
                        })
                        .buttonStyle(.plain)
                        .onHover { hovering in pinHistory = hovering }
                        ZStack {
                            if shwoMore {
                                Button(action: {
                                    if let regex = try? NSRegularExpression(pattern: #"(?:"[^"]*"|'[^']*'|`[^`]*`|[^;\s&|]+)"#) {
                                        let matches = regex.matches(in: command, range: NSRange(command.startIndex..., in: command))
                                        boomList = matches.map { match in String(command[Range(match.range, in: command)!]) }
                                        boomMode = true
                                    }
                                }, label: {
                                    Image(systemName: "character.cursor.ibeam")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.blue)
                                        .frame(width: 13)
                                        .frame(maxHeight: .infinity)
                                }).buttonStyle(.plain)
                            } else {
                                Image(systemName: "rectangle.expand.vertical")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 13)
                                    .frame(maxHeight: .infinity)
                            }
                        }.onHover { hovering in shwoMore = hovering }
                    }.padding(.leading, 8)
                }
                ZStack {
                    Color.primary.opacity(0.0001)
                    HStack {
                        Text(AttributedString(SyntaxHighlighter.shared.getHighlightedText(for: command)))
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .multilineTextAlignment(.leading)
                            .lineLimit(shwoMore ? nil : 1)
                            .padding(6)
                            .padding(.leading, 2)
                        Spacer()
                    }
                }.onTapGesture {
                    copyToPasteboardAndPaste(text: "\(command)\(autoSpace ? " " : "")", enter: autoReturn)
                    if autoClose {
                        mainPanel.close()
                        menuPopover.performClose(self)
                    }
                }
                if !swapButtons {
                    HStack(spacing: 5) {
                        Button(action: {
                            copyToPasetboard(text: command)
                            copied = true
                            withAnimation(.easeInOut(duration: 1)) { copied = false }
                        }, label: {
                            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.clipboard")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(copyText ? .blue : .secondary)
                                .frame(width: 12)
                                .frame(maxHeight: .infinity)
                        })
                        .buttonStyle(.plain)
                        .onHover { hovering in copyText = hovering }
                        Button(action: {
                            if pinnedList.contains(command) {
                                pinnedList.removeAll(where: { $0 == command })
                            } else {
                                pinnedList.append(command)
                            }
                            ud.set(pinnedList, forKey: "pinnedList")
                        }, label: {
                            Image(systemName: pinnedList.contains(command) ? "pin.fill" : "pin")
                                .font(.system(size: 13, weight: .medium))
                                .rotationEffect(.degrees(45))
                                .foregroundColor(pinHistory ? .blue : .secondary)
                                .frame(width: 14)
                                .frame(maxHeight: .infinity)
                        })
                        .buttonStyle(.plain)
                        .onHover { hovering in pinHistory = hovering }
                        ZStack {
                            if shwoMore {
                                Button(action: {
                                    if let regex = try? NSRegularExpression(pattern: #"(?:"[^"]*"|'[^']*'|`[^`]*`|[^;\s&|]+)"#) {
                                        let matches = regex.matches(in: command, range: NSRange(command.startIndex..., in: command))
                                        boomList = matches.map { match in String(command[Range(match.range, in: command)!]) }
                                        boomMode = true
                                    }
                                }, label: {
                                    Image(systemName: "character.cursor.ibeam")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.blue)
                                        .frame(width: 13)
                                        .frame(maxHeight: .infinity)
                                }).buttonStyle(.plain)
                            } else {
                                Image(systemName: "rectangle.expand.vertical")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 13)
                                    .frame(maxHeight: .infinity)
                            }
                        }.onHover { hovering in shwoMore = hovering }
                    }.padding(.trailing, 8)
                }
            }
            .background(Color.background.opacity((isHovered || fromMenubar) ? 1.0 : Double(panelOpacity) / 100))
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(.blue, lineWidth: isHovered ? 2 : 0)
                    .padding(1)
            }
            .mask(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .onHover { hovering in isHovered = hovering }
            .sheet(isPresented: $boomMode) {
                VStack(spacing: 10) {
                    GroupBox(label: Text("Magic Slice").font(.headline)) {
                        FlowLayout(items: boomList, spacing: 6) { item in CommandSliceView(command: item) }
                    }
                    GroupBox(label: Text("Manual Selection").font(.headline)) {
                        Text(AttributedString(SyntaxHighlighter.shared.getHighlightedText(for: command)))
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(2)
                    }
                    HStack {
                        Spacer()
                        Button("Close") { boomMode = false }
                            .keyboardShortcut(.defaultAction)
                    }
                }
                .padding()
                .focusable(false)
            }
            .onChange(of: boomList) { _ in boomMode = true }
        }
        /*.onAppear{
            highlightedText = AttributedString(command)
            //boomList = highlighter.bashHighlighterList(command)
            highlighter.getHighlightedTextAsync(for: command) { result in
                highlightedText = AttributedString(result)
            }
        }*/
    }
    
    struct CommandSliceView: View {
        var command: String
        @State private var copy: Bool = false
        @State private var isHovered: Bool = false
        @State private var copied: Bool = false
        
        var body: some View {
            HStack(spacing: 0) {
                Button(action: {
                    copyToPasteboardAndPaste(text: command)
                }, label: {
                    Text(command)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .lineLimit(nil)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .padding(.trailing, 14)
                }).buttonStyle(.plain)
                Button(action: {
                    copyToPasetboard(text: command)
                    copied = true
                    withAnimation(.easeInOut(duration: 1)) { copied = false }
                }, label: {
                    Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.clipboard")
                        .resizable().scaledToFit()
                        .frame(width: 12)
                        .foregroundColor(copy ? .blue : .secondary)
                })
                .padding(.leading, -18)
                .buttonStyle(.plain)
                .onHover { hovering in copy = hovering }
            }
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.background2)
                    .shadow(color: .secondary.opacity(0.8), radius: 0.3, y: 0.5)
            )
            .focusable(false)
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(.blue, lineWidth: isHovered ? 2 : 0)
                    .padding(1)
            }
            .onHover { hovering in isHovered = hovering }
        }
    }
}

func copyToPasetboard(text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

func copyToPasteboardAndPaste(text: String, enter: Bool = false) {
    let pasteboard = NSPasteboard.general
    var backupItems: [NSPasteboardItem] = []

    for item in pasteboard.pasteboardItems ?? [] {
        let newItem = NSPasteboardItem()
        
        for type in item.types {
            if let data = item.data(forType: type) {
                newItem.setData(data, forType: type)
            }
        }
        backupItems.append(newItem)
    }
    
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
    
    let eventSource = CGEventSource(stateID: .hidSystemState)
    let cmdDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Command), keyDown: true)
    let cmdUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Command), keyDown: false)
    let vDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
    let vUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
    let enterDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Return), keyDown: true)
    let enterUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Return), keyDown: false)

    cmdDown?.flags = .maskCommand
    vDown?.flags = .maskCommand
    
    cmdDown?.post(tap: .cgAnnotatedSessionEventTap)
    vDown?.post(tap: .cgAnnotatedSessionEventTap)
    vUp?.post(tap: .cgAnnotatedSessionEventTap)
    cmdUp?.post(tap: .cgAnnotatedSessionEventTap)
    if enter {
        enterDown?.post(tap: .cgAnnotatedSessionEventTap)
        enterUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        pasteboard.clearContents()
        pasteboard.writeObjects(backupItems)
    }
}

struct SearchField: NSViewRepresentable {
    class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: SearchField

        init(_ parent: SearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let searchField = notification.object as? NSSearchField else {
                print("Unexpected control in update notification")
                return
            }
            self.parent.search = searchField.stringValue
        }
    }

    @Binding var search: String
    @Environment(\.colorScheme) var colorScheme  // 使用环境变量监听深浅色模式的变化

    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField(frame: .zero)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.heightAnchor.constraint(equalToConstant: 24).isActive = true
        searchField.focusRingType = .none

        updateAppearance(for: searchField)  // 设置初始 appearance
        return searchField
    }

    func updateNSView(_ searchField: NSSearchField, context: Context) {
        searchField.placeholderString = "Search".local
        searchField.stringValue = search
        searchField.delegate = context.coordinator
        
        // 每次更新时重新检查系统外观
        updateAppearance(for: searchField)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    private func updateAppearance(for searchField: NSSearchField) {
        if colorScheme == .dark {
            searchField.appearance = NSAppearance(named: .vibrantDark)
        } else {
            searchField.appearance = NSAppearance(named: .vibrantLight)
        }
    }
}
