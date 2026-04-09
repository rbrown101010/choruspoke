import SwiftUI

struct ActionButton: View {
    let icon: RunnerHomeGlyph
    let label: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.mainButton()
            action()
        } label: {
            VStack(spacing: 9) {
                RunnerHomeIconView(glyph: icon)
                    .foregroundStyle(RunnerTheme.primaryText)
                    .frame(height: 20)

                Text(label)
                    .font(RunnerTypography.sans(11.5, weight: .semibold))
                    .foregroundStyle(RunnerTheme.primaryText.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 86)
            .background(
                RoundedRectangle(cornerRadius: RunnerTheme.radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [RunnerTheme.surface, RunnerTheme.elevated],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: RunnerTheme.radius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.white.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.28), radius: 14, x: 0, y: 12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(duration: 0.18), value: configuration.isPressed)
    }
}
