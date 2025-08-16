//
//  ComposeButtonView.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import SwiftUI

struct ComposeButtonView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.pencil")
                .font(.title2)
                .padding(16)
                .background(.thinMaterial, in: Circle())
        }
        .padding(16)
    }
}

#Preview {
    ComposeButtonView(action: {})
}
