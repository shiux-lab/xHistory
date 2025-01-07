//
//  ConfirmButton.swift
//  xHistory
//
//  Created by Dropout on 2025/1/7.
//

import SwiftUI

struct ConfirmButton: View {
    var label: LocalizedStringKey
    var title: LocalizedStringKey = "Are you sure?"
    var confirmButton: LocalizedStringKey = "Confirm"
    var message: LocalizedStringKey = "You will not be able to recover it!"
    var action: () -> Void
    @State private var showAlert = false
    
    var body: some View {
        Button(action: {
            showAlert = true
        }, label: {
            Text(label).foregroundStyle(.red)
        }).alert(title, isPresented: $showAlert) {
            Button(confirmButton, role: .destructive) { action() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(message)
        }
    }
}

#Preview {
    ConfirmButton(label: "Test") {}
        .frame(width: 100, height: 50)
}
