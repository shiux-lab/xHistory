//
//  CommandView.swift
//  xHistory
//
//  Created by Dropout on 2025/1/5.
//

import SwiftUI

struct CommandView: View {
    var index: Int
    var command: CommandItem
    
    @Binding var pinnedList: [CommandItem]
    var fromMenubar: Bool = false
    
    @AppStorage("panelOpacity") var panelOpacity = 100
    @AppStorage("autoClose") var autoClose = false
    @AppStorage("autoSpace") var autoSpace = false
    @AppStorage("isOhmyzsh") var isOhmyzsh = false
    @AppStorage("autoReturn") var autoReturn = false
    @AppStorage("buttonSide") var buttonSide = "right"
    
    @State private var isHovered: Bool = false
    @State private var showMore: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            Text((0...8).contains(index) ? "⌘\(index + 1)" : "\(index + 1)")
                .font(.system(size: 11, weight: (0...8).contains(index) ? .bold : .regular))
                .foregroundStyle(isHovered ? .white : .primary)
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
                if buttonSide == "left" {
                    ActionButtons(command: command, showMore: $showMore, pinnedList: $pinnedList)
                        .padding(.leading, 8)
                }
                Button(action: {
                    copyToPasteboardAndPaste(text: "\(command.command)\(autoSpace ? " " : "")", enter: autoReturn)
                    if autoClose {
                        mainPanel.close()
                        menuPopover.performClose(self)
                    }
                }, label: {
                    ZStack {
                        Color.primary.opacity(0.0001)
                        HStack {
                            Text(AttributedString(SyntaxHighlighter.shared.getHighlightedText(for: command.command)))
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .multilineTextAlignment(.leading)
                                .lineLimit(showMore ? nil : 1)
                                .padding(6)
                                .padding(.leading, 2)
                            Spacer()
                            if (isOhmyzsh && command.timestamp != nil) {
                                Text(getFormattedDate(format: "YYYY-MM-dd HH:mm:ss"))
                                    .font(.system(size: 11, weight: .light, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .padding(.trailing, 30)
                                    .padding(.leading, 2)
                            }
                        }
                    }
                })
                .buttonStyle(.plain)
                .setHotkey(index: index)
                if buttonSide == "right" {
                    ActionButtons(command: command, showMore: $showMore, pinnedList: $pinnedList)
                        .padding(.trailing, 8)
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
        }
    }
    
    func getFormattedDate(format: String) -> String {
        var dateString: String = ""
        if (command.timestamp != nil) {
            let dateFormatter = DateFormatter()
            let date = Date(timeIntervalSince1970: command.timestamp!)
            dateFormatter.dateFormat = format
            
            dateString = dateFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    CommandView(
        index: 0,
        command: CommandItem(timestamp: 1649160470, command: "brew update"),
        pinnedList: Binding.constant([])
    )
}
