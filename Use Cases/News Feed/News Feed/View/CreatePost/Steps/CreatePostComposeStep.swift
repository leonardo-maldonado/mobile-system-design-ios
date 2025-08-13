import SwiftUI

struct CreatePostComposeStep: View {
    @Binding var content: String
    @Binding var attachments: [PostAttachement]
    @Binding var isSubmitting: Bool
    var onSubmit: () -> Void
    var onBack: () -> Void

    var body: some View {
        Form {
            Section { TextField("Write a caption...", text: $content, axis: .vertical).lineLimit(4...8) } header: { Text("Caption") }
            if !attachments.isEmpty {
                Section("Attachments") {
                    ForEach(attachments.indices, id: \.self) { i in
                        HStack {
                            Image(systemName: "photo")
                            Text(attachments[i].contentUrl)
                        }
                    }
                }
            }
            Section { } footer: { Text("Your post will be uploaded when you tap Post").foregroundStyle(.secondary) }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Back", action: onBack) }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Post", action: onSubmit).disabled(isSubmitting || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}


