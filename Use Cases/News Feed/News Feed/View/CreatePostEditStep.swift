import SwiftUI
import UIKit

struct CreatePostEditStep: View {
    @Binding var images: [UIImage]
    @Binding var brightness: Double
    @Binding var contrast: Double
    var onNext: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            TabView {
                ForEach(images.indices, id: \.self) { i in
                    Image(uiImage: images[i])
                        .resizable()
                        .scaledToFit()
                        .brightness(brightness)
                        .contrast(contrast)
                        .frame(maxWidth: .infinity, maxHeight: 320)
                        .background(Color.black.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
            }
            .tabViewStyle(.page)

            VStack(alignment: .leading, spacing: 8) {
                Text("Adjustments").font(.headline)
                LabeledContent("Brightness") { Slider(value: $brightness, in: -0.5...0.5) }
                LabeledContent("Contrast") { Slider(value: $contrast, in: 0.5...1.5) }
            }
            .padding(.horizontal)

            HStack {
                Button("Back", action: onBack)
                Spacer()
                Button("Next", action: onNext).buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}


