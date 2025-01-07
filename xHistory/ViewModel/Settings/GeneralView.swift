//
//  GeneralView.swift
//  xHistory
//
//  Created by Dropout on 2025/1/7.
//

import SwiftUI
import ServiceManagement

struct GeneralView: View {
    @AppStorage("panelOpacity") var panelOpacity = 100
    @AppStorage("statusBar") var statusBar = true
    //@AppStorage("dockIcon") var dockIcon = false
    @AppStorage("statusIconName") var statusIconName = "menuBar"
    
    @State private var showStatusBar = true
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
                SToggle("Show Menu bar Icon", isOn: $statusBar)
                SDivider()
                if showStatusBar {
                    SItem(label: "Menu Bar Icon") {
                        HStack {
                            Button(action: {
                                if let button = statusBarItem.button {
                                    statusIconName = "menuBarInvert"
                                    button.image = NSImage(named: statusIconName)
                                }
                            }, label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .foregroundStyle(statusIconName == "menuBarInvert" ? .blue : .clear)
                                    Image("menuBarInvert")
                                        .offset(x: 0.5, y: 0.5)
                                        .foregroundStyle(statusIconName == "menuBarInvert" ? .white : .secondary)
                                }.frame(width: 24, height: 24)
                            }).buttonStyle(.plain)
                            Button(action: {
                                if let button = statusBarItem.button {
                                    statusIconName = "menuBar"
                                    button.image = NSImage(named: statusIconName)
                                }
                            }, label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .foregroundStyle(statusIconName == "menuBar" ? .blue : .clear)
                                    Image("menuBar")
                                        .offset(x: 0.5, y: 0.5)
                                        .foregroundStyle(statusIconName == "menuBar" ? .white : .secondary)
                                }.frame(width: 24, height: 24)
                            }).buttonStyle(.plain)
                        }
                    }
                    SDivider()
                }
                //SToggle("Show Dock Icon", isOn: $dockIcon)
                //SDivider()
                HStack {
                    SSlider(label: "History Panel Opacity", value: $panelOpacity, range: 10...100, width: 160)
                    Text("\(panelOpacity)%").frame(width: 35)
                }
            }
            SGroupBox(label: "Update") { UpdaterSettingsView(updater: updaterController.updater) }
            VStack(spacing: 8) {
                HStack {
                    CheckForUpdatesView(updater: updaterController.updater)
                    if !statusBar {
                        Button(action: {
                            NSApp.terminate(self)
                        }, label: {
                            Text("Quit".local + " xHistory").foregroundStyle(.red)
                        })
                    }
                }
                if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("xHistory v\(appVersion)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear { showStatusBar = statusBar }
        .onChange(of: statusBar) { newValue in
            showStatusBar = newValue
            statusBarItem.isVisible = newValue
        }
        /*.onChange(of: dockIcon) { newValue in
            if newValue {
                NSApp.setActivationPolicy(.regular)
            } else {
                NSApp.setActivationPolicy(.accessory)
            }
        }*/
    }
}

#Preview {
    GeneralView()
}
