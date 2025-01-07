//
//  BlacklistView.swift
//  xHistory
//
//  Created by Dropout on 2025/1/7.
//

import SwiftUI

struct BlacklistView: View {
    @State private var blockedItems = [String]()
    @State private var temp = ""
    @State private var showSheet = false
    @State private var editingIndex: Int?
    
    var body: some View {
        VStack {
            GroupBox(label:
                        VStack(alignment: .leading) {
                Text("Blacklist").font(.headline)
                Text("The following commands will be ignored from the history.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ) {
                VStack(spacing: 10) {
                    ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
                        List {
                            ForEach(blockedItems.indices, id: \.self) { index in
                                HStack {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.red)
                                        .onTapGesture { if editingIndex == nil { blockedItems.remove(at: index) } }
                                    Text(blockedItems[index])
                                }
                            }
                        }
                        Button(action: {
                            showSheet = true
                        }) {
                            Image(systemName: "plus.square.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showSheet){
                            VStack {
                                TextField("Enter Command".local, text: $temp).frame(width: 300)
                                HStack(spacing: 20) {
                                    Button {
                                        if temp == "" { return }
                                        if !blockedItems.contains(temp) { blockedItems.append(temp) }
                                        temp = ""
                                        showSheet = false
                                    } label: {
                                        Text("Add to List").frame(width: 80)
                                    }.keyboardShortcut(.defaultAction)
                                    Button {
                                        showSheet = false
                                    } label: {
                                        Text("Cancel").frame(width: 80)
                                    }
                                }.padding(.top, 10)
                            }.padding()
                        }
                    }
                    Text("You can add a \"#\" at the beginning of a keyword to convert it to a regex pattern.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(5)
                .onAppear { blockedItems = (ud.object(forKey: "blockedCommands") as? [String]) ?? [] }
                .onChange(of: blockedItems) {
                    b in ud.setValue(b, forKey: "blockedCommands")
                    HistoryCopyer.shared.updateHistory()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    BlacklistView()
}
