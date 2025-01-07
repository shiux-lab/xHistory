//
//  xHistoryApp.swift
//  xHistory
//
//  Created by apple on 2024/11/5.
//

import AppKit
import SwiftUI
import Sparkle
import SFSMonitor
//import UserNotifications
import KeyboardShortcuts
import SystemConfiguration

//let nc = NSWorkspace.shared.notificationCenter
let ud = UserDefaults.standard
let fd = FileManager.default
let cloudFileExtension = "xha"
let queue = SFSMonitor(delegate: HistoryCopyer.shared)
let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
let mainPanel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 550, height: 695), styleMask: [.fullSizeContentView, .resizable, .closable, .miniaturizable, .nonactivatingPanel, .titled], backing: .buffered, defer: false)
let menuPopover = NSPopover()

@main
struct xHistoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
                .background(
                    WindowAccessor(
                        onWindowOpen: { w in
                            if let w = w {
                                //w.level = .floating
                                w.titlebarSeparatorStyle = .none
                                guard let nsSplitView = findNSSplitVIew(view: w.contentView),
                                      let controller = nsSplitView.delegate as? NSSplitViewController else { return }
                                controller.splitViewItems.first?.canCollapse = false
                                controller.splitViewItems.first?.minimumThickness = 140
                                controller.splitViewItems.first?.maximumThickness = 140
                                w.orderFront(nil)
                            }
                        })
                )
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {//, UNUserNotificationCenterDelegate {
    @AppStorage("statusIconName") var statusIconName = "menuBar"
    @AppStorage("historyFile") var historyFile = "~/.bash_history"
    @AppStorage("isOhmyzsh") var isOhmyzsh = false
    @AppStorage("statusBar") var statusBar = true
    //@AppStorage("showPinned") var showPinned = false
    @AppStorage("buttonSide") var buttonSide = "right"
    @AppStorage("cloudSync") var cloudSync = false
    @AppStorage("cloudDirectory") var cloudDirectory = ""
    //@AppStorage("dockIcon") var dockIcon = false
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        //if dockIcon { NSApp.setActivationPolicy(.regular) }
        updateShellConfig()
        ud.register(defaults: ["blockedCommands": ["xhistory"]])
#if RELEASE
        let bashrc = homeDirectory.appendingPathComponent(".bash_profile")
        let zshrc = homeDirectory.appendingPathComponent(".zshrc")
        try? createEmptyFile(at: bashrc)
        try? createEmptyFile(at: zshrc)
        if let resourceURL = Bundle.main.resourceURL {
            let bRC = bashrc.readHistory ?? ""
            let zRC = zshrc.readHistory ?? ""
            let command = resourceURL.appendingPathComponent("xh").path
            let bashC = "eval $(\(command) -c bash 2>/dev/null)"
            if !bRC.contains(bashC) { try? appendLine(to: bashrc, line: "\n\(bashC)") }
            let zshC1 = "eval $(\(command) -c zsh 2>/dev/null)"
            if !zRC.contains(zshC1) { try? appendLine(to: zshrc, line: "\n\(zshC1)") }
            let zshC2 = "$(\(command) -c zsh2 2>/dev/null)"
            let zshC3 = "$(\(command) -c zsh3 2>/dev/null)"
            if !zRC.contains(zshC2) { try? appendLine(to: zshrc, line: "\n\(zshC2)") }
            if !zRC.contains(zshC3) { try? appendLine(to: zshrc, line: "\n\(zshC3)") }
        }
#endif
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleURLEvent(_:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        
        /*UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error { print("⚠️ Notification authorization denied: \(error.localizedDescription)") }
        }
        UNUserNotificationCenter.current().delegate = self*/
        //KeyboardShortcuts.onKeyDown(for: .swapButtons) { self.swapButtons.toggle() }
        KeyboardShortcuts.onKeyDown(for: .showPanel) { self.openMainPanel() }
        KeyboardShortcuts.onKeyDown(for: .showOverlay) { openCustomURLWithActiveWindowGeometry() }
        KeyboardShortcuts.onKeyDown(for: .showPinnedPanel) {
            PageState.shared.pageID = 2
            self.openMainPanel()
        }
        KeyboardShortcuts.onKeyDown(for: .showPinnedOverlay) {
            PageState.shared.pageID = 2
            openCustomURLWithActiveWindowGeometry()
        }
        
        if let button = statusBarItem.button {
            button.target = self
            button.image = NSImage(named: statusIconName)
            button.action = #selector(togglePopover(_ :))
            menuPopover.contentSize = NSSize(width: 500, height: 352)
            menuPopover.setValue(true, forKeyPath: "shouldHideAnchor")
            menuPopover.behavior = .transient
        }
        statusBarItem.isVisible = statusBar
        //swapButtons = false
        if !fd.fileExists(atPath: historyFile.absolutePath) {
            if historyFile == "~/.bash_history" {
                historyFile = "~/.zsh_history"
            } else if historyFile == "~/.zsh_history" {
                historyFile = "~/.bash_history"
            }
        }
        if fd.fileExists(atPath: "~/.oh-my-zsh".absolutePath) {
            isOhmyzsh = true
        }
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if let button = statusBarItem.button, !menuPopover.isShown {
            menuPopover.contentViewController = NSHostingController(rootView: ContentView(fromMenubar: true))
            var bound = button.bounds
            if getMenuBarHeight() == 24.0 { bound.origin.y -= 6 }
            menuPopover.show(relativeTo: bound, of: button, preferredEdge: .minY)
            menuPopover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
            mainPanel.close()
        }
    }
    
    func openMainPanel(file: String? = nil) {
        HistoryCopyer.shared.updateHistory(file: file)
        mainPanel.setFrame(NSRect(x: 0, y: 0, width: 550, height: 695), display: true)
        mainPanel.center()
        mainPanel.makeKeyAndOrderFront(self)
        menuPopover.performClose(self)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        queue?.setMaxMonitored(number: 200)
        _ = queue?.addURL(historyFile.absolutePath.url)
        
        for cmd in HistoryCopyer.shared.readHistory() {
            SyntaxHighlighter.shared.getHighlightedTextAsync(for: cmd.command) { _ in }
        }
        
        mainPanel.title = "xHistory Panel".local
        mainPanel.level = .floating
        mainPanel.isOpaque = false
        //mainPanel.hasShadow = false
        mainPanel.titleVisibility = .hidden
        mainPanel.titlebarAppearsTransparent = true
        mainPanel.isReleasedWhenClosed = false
        mainPanel.isMovableByWindowBackground = true
        mainPanel.becomesKeyOnlyIfNeeded = true
        mainPanel.backgroundColor = .clear
        mainPanel.collectionBehavior = [.canJoinAllSpaces]
        let contentView = NSHostingView(rootView: ContentView())
        contentView.focusRingType = .none
        mainPanel.contentView = contentView
        
        tips("You can click on any command or slice\nto fill it into the lower window\n(accessibility permissions required)".local,
             id: "xh.how-to-use.note")
        tips("If your history has extras (like timestamps)\nyou can preformat it with a custom Regex in\n\"Preferences\" > \"Shell\" > \"Preformatter\"".local,
             id: "xh.pre-formatter.note", width:260)
        if !CommandLineTool.isInstalled() {
            tips("Do you want to install the command line tool?\nAfter installation, you can run \"xhistory\" in yor terminal to quickly open the floating panel.\n\n(You can also install it later in preferences)".local,
                 title: "Command Line Tool".local,
                 id: "xh.install-clt.note", switchButton: true, width: 250) {
                CommandLineTool.install()
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        self.openMainPanel()
        return false
    }
    
    func closeAllWindow(except: String = "") {
        for w in NSApp.windows.filter({
            $0.title != "Item-0" && $0.title != ""
            && !$0.title.contains(except) }) { w.close() }
    }
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
           let url = URL(string: urlString) {
            if url.scheme == "xhistory"{
                switch url.host {
                case "show" :
                    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
                    let queryItems = components.queryItems
                    if queryItems == nil { self.openMainPanel() }
                    if let x = queryItems?.first(where: { $0.name == "x" })?.value,
                       let y = queryItems?.first(where: { $0.name == "y" })?.value,
                       let w = queryItems?.first(where: { $0.name == "w" })?.value,
                       let h = queryItems?.first(where: { $0.name == "h" })?.value {
                        if let xInt = Int(x), let yInt = Int(y), let wInt = Int(w), let hInt = Int(h) {
                            let file = queryItems?.first(where: { $0.name == "file" })?.value
                            openMainPanel(file: file)
                            let bound = CGRectTransform(cgRect: CGRect(x: xInt, y: yInt + 28, width: wInt, height: hInt - 28))
                            mainPanel.setFrame(bound, display: true)
                            if let mode = queryItems?.first(where: { $0.name == "mode" })?.value {
                                switch mode {
                                case "pinned": PageState.shared.pageID = 2
                                case "archive":
                                    if cloudSync && cloudDirectory != "" {
                                        PageState.shared.pageID = 3
                                    }
                                default: PageState.shared.pageID = 1
                                }
                            }
                        }
                    }
                default: print("Unknow command!")
                }
            }
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

func CGRectTransform(cgRect: CGRect) -> NSRect {
    let x = cgRect.origin.x
    let y = cgRect.origin.y
    let w = cgRect.width
    let h = cgRect.height
    if let main = NSScreen.screens.first(where: { $0.isMainScreen }) {
        return NSRect(x: x, y: main.frame.height - y - h, width: w, height: h)
    }
    return cgRect
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
}

func openAboutPanel() {
    NSApp.activate(ignoringOtherApps: true)
    NSApp.orderFrontStandardAboutPanel(nil)
}

func getMenuBarHeight() -> CGFloat {
    let mouseLocation = NSEvent.mouseLocation
    let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
    if let screen = screen {
        return screen.frame.height - screen.visibleFrame.height - (screen.visibleFrame.origin.y - screen.frame.origin.y) - 1
    }
    return 0.0
}

func getMacDeviceName() -> String {
    @AppStorage("machineType") var machineType = "mac"
    var computerName: CFString?
    if let dynamicStore = SCDynamicStoreCreate(nil, "GetComputerName" as CFString, nil, nil) {
        computerName = SCDynamicStoreCopyComputerName(dynamicStore, nil) as CFString?
    }
    if let name = computerName as String? { return name }
    return machineType
}

func getMacDeviceUUID() -> String? {
    let dev = IOServiceMatching("IOPlatformExpertDevice")
    let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMainPortDefault, dev)
    if platformExpert != 0 {
        if let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)?.takeUnretainedValue() {
            IOObjectRelease(platformExpert)
            return serialNumberAsCFString as? String
        }
        IOObjectRelease(platformExpert)
    }
    return nil
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

func appendLine(to fileURL: URL, line: String, encoding: String.Encoding = .utf8) throws {
    let newLine = line + "\n"
    
    if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
        defer { fileHandle.closeFile() }
        fileHandle.seekToEndOfFile()
        if let data = newLine.data(using: .utf8) { fileHandle.write(data) }
    } else {
        try newLine.write(to: fileURL, atomically: true, encoding: encoding)
    }
}

func updateShellConfig() {
    @AppStorage("customShellConfig") var customShellConfig = true
    @AppStorage("historyLimit") var historyLimit = 1000
    @AppStorage("noDuplicates") var noDuplicates = true
    @AppStorage("realtimeSave") var realtimeSave = true
    
    let data: [String: Any] = [
        "customShellConfig": customShellConfig,
        "historyLimit": historyLimit,
        "noDuplicates": noDuplicates,
        "realtimeSave": realtimeSave
    ]
    if let appSupportDir = fd.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
        let appFolder = appSupportDir.appendingPathComponent(Bundle.main.appName)
        let plistURL = appFolder.appendingPathComponent("shellConfig.plist")
        if !fd.fileExists(atPath: appFolder.path) {
            try? fd.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
        }
        let plistData = try? PropertyListSerialization.data(fromPropertyList: data, format: .xml, options: 0)
        try? plistData?.write(to: plistURL)
    }
}

func tips(_ message: String, title: String? = nil, id: String, switchButton: Bool = false, width: Int? = nil, action: (() -> Void)? = nil) {
    let never = (ud.object(forKey: "neverRemindMe") as? [String]) ?? []
    if !never.contains(id) {
        if switchButton {
            let alert = createAlert(title: title ?? "xHistory Tips".local, message: message, button1: "OK", button2: "Don't remind me again", width: width).runModal()
            if alert == .alertSecondButtonReturn { ud.setValue(never + [id], forKey: "neverRemindMe") }
            if alert == .alertFirstButtonReturn { action?() }
        } else {
            let alert = createAlert(title: title ?? "xHistory Tips".local, message: message, button1: "Don't remind me again", button2: "OK", width: width).runModal()
            if alert == .alertFirstButtonReturn { ud.setValue(never + [id], forKey: "neverRemindMe") }
            if alert == .alertSecondButtonReturn { action?() }
        }
    }
}

func createAlert(level: NSAlert.Style = .warning, title: String, message: String, button1: String, button2: String = "", width: Int? = nil) -> NSAlert {
    let alert = NSAlert()
    alert.messageText = title.local
    alert.informativeText = message.local
    alert.addButton(withTitle: button1.local)
    if button2 != "" { alert.addButton(withTitle: button2.local) }
    alert.alertStyle = level
    if let width = width {
        alert.accessoryView = NSView(frame: NSMakeRect(0, 0, Double(width), 0))
    }
    return alert
}

extension Bundle {
    var appName: String {
        let appName = self.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                     ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                     ?? "Unknown App Name"
        return appName
    }
}

extension String {
    var local: String { return NSLocalizedString(self, comment: "") }
    var deletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }
    var url: URL { return URL(fileURLWithPath: self) }
    var forceCharWrapping: Self {
      self.map({ String($0) }).joined(separator: "\u{200B}")
    }
    var absolutePath: String {
        return (self as NSString).expandingTildeInPath
    }
    func startsWith(character: Character) -> Bool {
        guard let firstChar = self.first else {
            return false
        }
        return firstChar == character
    }
}

extension NSMenuItem {
    func performAction() {
        guard let menu else {
            return
        }
        menu.performActionForItem(at: menu.index(of: self))
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        return deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID
    }
    var isMainScreen: Bool {
        guard let id = self.displayID else { return false }
        return (CGDisplayIsMain(id) == 1)
    }
}
