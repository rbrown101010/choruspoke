import SwiftUI
import UIKit

enum RunnerTheme {
    static let background = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let workspacePane = Color(red: 0.14, green: 0.14, blue: 0.17)
    static let surface = Color.white.opacity(0.08)
    static let elevated = Color.white.opacity(0.035)
    static let subtle = Color.white.opacity(0.04)
    static let border = Color.white.opacity(0.08)
    static let borderStrong = Color.white.opacity(0.15)
    static let primaryText = Color.white.opacity(0.92)
    static let secondaryText = Color.white.opacity(0.70)
    static let tertiaryText = Color.white.opacity(0.50)
    static let accent = Color(red: 0.42, green: 0.82, blue: 0.78)
    static let accentBlue = Color(red: 0.39, green: 0.63, blue: 1.0)
    static let blueHalo = Color(red: 0.58, green: 0.83, blue: 1.0)
    static let statusConnected = Color(red: 0.45, green: 0.81, blue: 0.35)
    static let statusWarning = Color(red: 0.91, green: 0.84, blue: 0.36)
    static let statusError = Color(red: 0.88, green: 0.42, blue: 0.50)
    static let userBubble = Color(red: 0.04, green: 0.52, blue: 1.0)
    static let radius: CGFloat = 16
}

enum RunnerTypography {
    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let name = resolvedFontName(for: weight) {
            return .custom(name, size: size)
        }

        return .system(size: size, weight: weight, design: .default)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    private static func resolvedFontName(for weight: Font.Weight) -> String? {
        let candidates: [String]

        switch weight {
        case .medium, .semibold, .bold, .heavy, .black:
            candidates = [
                "GTStandard-Medium",
                "GTStandard-MediumTrial",
                "GT Standard Medium",
                "GT-Standard-Medium",
                "GT-Standard-M-Standard-Medium-Trial",
            ]
        default:
            candidates = [
                "GTStandard-Regular",
                "GTStandard-RegularTrial",
                "GT Standard Regular",
                "GT-Standard-Regular",
                "GT-Standard-M-Standard-Regular-Trial",
            ]
        }

        return candidates.first { UIFont(name: $0, size: sizeProbe) != nil }
    }

    private static let sizeProbe: CGFloat = 17
}

struct RunnerBackgroundView: View {
    var body: some View {
        ZStack {
            RunnerTheme.background
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.17),
                    RunnerTheme.background,
                    Color(red: 0.10, green: 0.10, blue: 0.12),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(RunnerTheme.accentBlue.opacity(0.16))
                .frame(width: 360, height: 360)
                .blur(radius: 96)
                .offset(x: -145, y: 520)

            Circle()
                .fill(RunnerTheme.blueHalo.opacity(0.12))
                .frame(width: 330, height: 330)
                .blur(radius: 92)
                .offset(x: 150, y: 520)

            Circle()
                .fill(RunnerTheme.accentBlue.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 88)
                .offset(x: 0, y: 420)

            Circle()
                .fill(Color.white.opacity(0.035))
                .frame(width: 220, height: 220)
                .blur(radius: 74)
                .offset(x: 0, y: -210)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.03),
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.22),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

struct RunnerPanel<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ZStack {
            RunnerBackgroundView()

            VStack(spacing: 0) {
                VStack(spacing: subtitle == nil ? 0 : 4) {
                    Text(title)
                        .font(RunnerTypography.sans(19, weight: .semibold))
                        .foregroundStyle(RunnerTheme.primaryText)

                    if let subtitle {
                        Text(subtitle)
                            .font(RunnerTypography.sans(13, weight: .medium))
                            .foregroundStyle(RunnerTheme.secondaryText)
                    }
                }
                .padding(.top, 26)
                .padding(.bottom, subtitle == nil ? 12 : 18)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct RunnerGlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: RunnerTheme.radius, style: .continuous)
                    .fill(RunnerTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RunnerTheme.radius, style: .continuous)
                    .stroke(RunnerTheme.border, lineWidth: 1)
            )
    }
}

extension View {
    func runnerCard() -> some View {
        modifier(RunnerGlassCardModifier())
    }
}

struct RunnerStatusDot: View {
    let status: RunnerConnectionStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 9, height: 9)
            .shadow(color: color.opacity(0.55), radius: 6)
    }

    private var color: Color {
        switch status {
        case .connected:
            return RunnerTheme.statusConnected
        case .connecting:
            return RunnerTheme.statusWarning
        case .failed:
            return RunnerTheme.statusError
        case .idle:
            return RunnerTheme.tertiaryText
        }
    }
}

struct RunnerSegmentedControl<Value: Hashable>: View {
    let options: [(Value, String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.1) { option in
                Button {
                    Haptics.selection()
                    withAnimation(.spring(duration: 0.22)) {
                        selection = option.0
                    }
                } label: {
                    Text(option.1)
                        .font(RunnerTypography.sans(14, weight: .semibold))
                        .foregroundStyle(selection == option.0 ? RunnerTheme.primaryText : RunnerTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selection == option.0 ? RunnerTheme.surface : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selection == option.0 ? RunnerTheme.borderStrong : RunnerTheme.border.opacity(0.55), lineWidth: 1)
                        )
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RunnerTheme.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(RunnerTheme.border, lineWidth: 1)
        )
    }
}

struct RunnerEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(RunnerTypography.sans(22, weight: .medium))
                .foregroundStyle(RunnerTheme.secondaryText)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(RunnerTheme.elevated)
                )

            VStack(spacing: 5) {
                Text(title)
                    .font(RunnerTypography.sans(16, weight: .semibold))
                    .foregroundStyle(RunnerTheme.primaryText)

                Text(message)
                    .font(RunnerTypography.sans(14, weight: .medium))
                    .foregroundStyle(RunnerTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RunnerInlineNotice: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(RunnerTheme.statusWarning)
            Text(text)
                .font(RunnerTypography.sans(13, weight: .medium))
                .foregroundStyle(RunnerTheme.secondaryText)
            Spacer()
        }
        .padding(14)
        .runnerCard()
    }
}

func runnerRelativeDate(_ isoString: String) -> String {
    guard let date = runnerISODate(from: isoString) else { return isoString }
    return date.formatted(.relative(presentation: .named))
}

func runnerISODate(from value: String) -> Date? {
    RunnerDate.isoWithFractional.date(from: value) ?? RunnerDate.iso.date(from: value)
}

enum RunnerDate {
    static let isoWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

func runnerFormattedBytes(_ bytes: Int) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
}
