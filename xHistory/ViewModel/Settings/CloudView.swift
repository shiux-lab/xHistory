//
//  CloudView.swift
//  xHistory
//
//  Created by Dropout on 2025/1/7.
//

import SwiftUI

struct CloudView: View {
    @AppStorage("cloudSync") var cloudSync = false
    @AppStorage("cloudDirectory") var cloudDirectory = ""
    @StateObject private var state = PageState.shared
    
    var body: some View {
        SForm(spacing: 10, noSpacer: true) {
            SGroupBox(label: "Cloud") {
                SToggle("Cloud Archiving", isOn: $cloudSync)
                SDivider()
                SItem(label: "Archive Folder", spacing: 4) {
                    Text(cloudDirectory)
                        .font(.footnote)
                        .foregroundColor(Color.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                    SInfoButton(tips: "Select a folder in iCloud Drive to store and sync history across multiple devices.")
                    Button("Select...", action: { updateCloudDirectory() })
                }
            }
            GroupBox(label:
                HStack(spacing: 5) {
                    Text("Archives").font(.headline)
                    Button(action: {
                        state.archiveList = getCloudFiles()
                    }, label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                    }).buttonStyle(.plain)
                }
                .padding(.bottom, 6)
            ) {
                VStack(spacing: 10) {
                    ScrollView(showsIndicators: true) {
                        ForEach(state.archiveList.indices, id: \.self) { index in
                            HStack {
                                Text(state.archiveList[index])
                                Spacer()
                                ConfirmButton(label: "Delete", title: "Delete This Archive?", confirmButton: "Delete") {
                                    if state.archiveList[index] == state.archiveName {
                                        state.archiveName = ""
                                        state.archiveData.removeAll()
                                    }
                                    let archiveURL = cloudDirectory.url.appendingPathComponent("\(state.archiveList[index]).xha")
                                    try? fd.removeItem(at: archiveURL)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { state.archiveList = getCloudFiles() }
                                }
                            }
                            .frame(height: 12)
                            .padding(.vertical, 4)
                            SDivider()
                        }
                    }.frame(maxWidth: .infinity)
                }.padding(5)
            }
        }
        .onAppear { state.archiveList = getCloudFiles() }
        .onChange(of: cloudSync) { _ in state.archiveList = getCloudFiles() }
    }
    
    func updateCloudDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowedContentTypes = []
        openPanel.allowsOtherFileTypes = false
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            if let path = openPanel.urls.first?.path { cloudDirectory = path }
        }
    }
}

func getCloudFiles() -> [String] {
    @AppStorage("cloudDirectory") var cloudDirectory = ""
    var result = [String]()
    
    let contents = try? fd.contentsOfDirectory(atPath: cloudDirectory)
    result = contents?.filter { $0.hasSuffix(".\(cloudFileExtension)") }.map { $0.deletingPathExtension }  ?? []
    
    return result
}

#Preview {
    CloudView()
}
