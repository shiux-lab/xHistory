//
//  ShellView.swift
//  xHistory
//
//  Created by Dropout on 2025/1/7.
//

import SwiftUI

struct ShellView: View {
    @State private var cltInstalled: Bool = false
    @AppStorage("customShellConfig") var customShellConfig = true
    @AppStorage("historyLimit") var historyLimit = 1000
    @AppStorage("noDuplicates") var noDuplicates = true
    @AppStorage("realtimeSave") var realtimeSave = true
    @AppStorage("preFormatter") var preFormatter = ""
    @State private var disabled: Bool = false
    @State private var userFormatter = ""
    
    var body: some View {
        SForm(spacing: 10) {
            GroupBox(label:
            VStack(alignment: .leading) {
                Text("Shell Configuration").font(.headline)
                Text("These settings will only take effect in newly logged-in shells when you modify them.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ) {
                VStack(spacing: 10) {
                    SToggle("Custom Configuration (for Bash & Zsh)", isOn: $customShellConfig)
                    SDivider()
                    Group {
                        SToggle("Real-time History Saving", isOn: $realtimeSave)
                        SDivider()
                        SToggle("Ignore Consecutive Duplicates", isOn: $noDuplicates)
                        SDivider()
                        SSteper("Maximum Number of History Items", value: $historyLimit, min: 1, max: 10000, width: 60)
                    }.disabled(disabled)
                }.padding(5)
            }
            SGroupBox {
                HStack(spacing: 4) {
                    SField("Preformatter", placeholder: "Enter regular expression here", text: $userFormatter)
                    SInfoButton(tips: "You can use regular expressions to match each line of history.\nxHistory will only show you the content in the matching groups.")
                    Button("Save") { preFormatter = userFormatter }
                }
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
        .onAppear { userFormatter = preFormatter }
        .onChange(of: preFormatter) { _ in HistoryCopyer.shared.reHighlight() }
        .onChange(of: customShellConfig) { newValue in
            disabled = !newValue
            updateShellConfig()
        }
        .onChange(of: realtimeSave) { _ in updateShellConfig() }
        .onChange(of: noDuplicates) { _ in updateShellConfig() }
        .onChange(of: historyLimit) { _ in updateShellConfig() }
    }
    
    func updateCTL() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cltInstalled = CommandLineTool.isInstalled()
        }
    }
}

#Preview {
    ShellView()
}
