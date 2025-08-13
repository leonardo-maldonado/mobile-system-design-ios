import SwiftUI

@MainActor
protocol ViewInteractable {
    func send(_ interaction: ViewInteraction)
}

private struct ViewInteractionEnvironmentKey: EnvironmentKey {
    static let defaultValue: ViewInteractable? = nil
}

extension EnvironmentValues {
    var viewInteraction: ViewInteractable? {
        get { self[ViewInteractionEnvironmentKey.self] }
        set { self[ViewInteractionEnvironmentKey.self] = newValue }
    }
}

extension View {
    func viewInteraction(_ i: ViewInteractable?) -> some View { environment(\.viewInteraction, i) }
}

extension View {
    func onTapSend(_ interaction: @autoclosure @escaping () -> ViewInteraction) -> some View {
        modifier(SendOnTapModifier(makeInteraction: interaction))
    }
}

private struct SendOnTapModifier: ViewModifier {
    @Environment(\.viewInteraction) private var bus
    let makeInteraction: () -> ViewInteraction
    func body(content: Content) -> some View {
        Button(action: { if let bus { bus.send(makeInteraction()) } }) {
            content.contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

