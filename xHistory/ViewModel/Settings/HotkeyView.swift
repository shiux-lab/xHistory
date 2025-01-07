//
//  HotkeyView.swift
//  xHistory
//
//  Created by Dropout on 2025/1/7.
//

import SwiftUI
import KeyboardShortcuts

struct HotkeyView: View {
    @State var hotKey1: String = "⌘←  /  ⌘→"
    @State var hotKey2: String = "⌃1"
    @State var hotKey3: String = "⌃2"
    @State var hotKey4: String = "⌃3"
    
    var body: some View {
        SForm(spacing: 10) {
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
            SGroupBox {
                SItem(label: "Switch to \"History\" page") {
                    TextField("", text: $hotKey2)
                        .disabled(true)
                        .frame(width: 128)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                }
                SDivider()
                SItem(label: "Switch to \"Pinned\" page") {
                    TextField("", text: $hotKey3)
                        .disabled(true)
                        .frame(width: 128)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                }
                SDivider()
                SItem(label: "Switch to \"Archive\" page") {
                    TextField("", text: $hotKey4)
                        .disabled(true)
                        .frame(width: 128)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                }
                SDivider()
                SItem(label: "Swap action button positions") {
                    HStack(spacing: 5) {
                        SInfoButton(tips: "Put \"Copy\", \"Pin\" and \"Expand\" buttons on the other side of history items.\nThis is useful for full screen or very long window.")
                        //KeyboardShortcuts.Recorder("", name: .swapButtons)
                        TextField("", text: $hotKey1)
                            .disabled(true)
                            .frame(width: 128)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
}

#Preview {
    HotkeyView()
}
