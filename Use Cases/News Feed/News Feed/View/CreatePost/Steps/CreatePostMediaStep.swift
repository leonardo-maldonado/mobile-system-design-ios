import SwiftUI
import PhotosUI
import UIKit

struct CreatePostMediaStep: View {
    @Binding var selected: [PhotosPickerItem]
    @Binding var images: [UIImage]
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $selected, maxSelectionCount: 10, matching: .images) {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled").font(.largeTitle)
                    Text("Select up to 10 photos").font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(images.indices, id: \.self) { i in
                        Image(uiImage: images[i]).resizable().scaledToFill().frame(width: 90, height: 90).clipped().cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            Button("Next") { onNext() }
                .buttonStyle(.borderedProminent)
                .disabled(images.isEmpty)
        }
        .padding()
        .task(id: selected) { await loadImages() }
    }

    private func loadImages() async {
        images.removeAll()
        for item in selected {
            if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                images.append(img)
            }
        }
    }
}


