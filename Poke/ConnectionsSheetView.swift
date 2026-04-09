import SwiftUI

struct ConnectionsSheetView: View {
    private let placeholders = [
        "Gmail",
        "Google Calendar",
        "Google Drive",
        "Notion",
        "Slack",
        "Telegram",
    ]

    private let channels = [
        "iMessage",
        "Telegram",
        "SMS",
    ]

    var body: some View {
        RunnerPanel(title: "Connections") {
            ScrollView {
                VStack(spacing: 18) {
                    RunnerInlineNotice(text: "Connections and channels stay as placeholders in this build, matching runner’s current desktop-alpha limitations.")

                    section(title: "Connections", items: placeholders, status: "Placeholder")
                    section(title: "Channels", items: channels, status: "Coming soon")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }

    private func section(title: String, items: [String], status: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(RunnerTypography.sans(13, weight: .semibold))
                .foregroundStyle(RunnerTheme.secondaryText)

            ForEach(items, id: \.self) { item in
                HStack {
                    Text(item)
                        .font(RunnerTypography.sans(15, weight: .semibold))
                        .foregroundStyle(RunnerTheme.primaryText)

                    Spacer()

                    Text(status)
                        .font(RunnerTypography.sans(11, weight: .bold))
                        .foregroundStyle(RunnerTheme.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(RunnerTheme.surface))
                        .overlay(Capsule().stroke(RunnerTheme.border, lineWidth: 1))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .runnerCard()
            }
        }
    }
}
