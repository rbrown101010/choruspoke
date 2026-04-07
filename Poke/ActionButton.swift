import SwiftUI

struct ActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(PokeTheme.iconColor)
                
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PokeTheme.primaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 82)
            .background(
                ZStack {
                    // Base fill with subtle gradient for depth
                    RoundedRectangle(cornerRadius: PokeTheme.cardRadius)
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color(white: 0.16), Color(white: 0.12)]
                                    : [Color(white: 0.97), Color(white: 0.93)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Top highlight edge — subtle inner glow
                    RoundedRectangle(cornerRadius: PokeTheme.cardRadius)
                        .stroke(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color.white.opacity(0.12), Color.white.opacity(0.0)]
                                    : [Color.white.opacity(0.8), Color.white.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.75
                        )
                }
            )
            // Outer shadow for 3D lift (subtle)
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.06),
                radius: 3, x: 0, y: 1.5
            )
            // Subtle second shadow for depth
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.12 : 0.03),
                radius: 0.5, x: 0, y: 0.5
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
