import SwiftUI
import UIKit

struct ContactLinksSheetView: View {
    @Environment(\.openURL) private var openURL
    @State private var helperMessage: String?

    var body: some View {
        RunnerPanel(title: "Channels") {
            ScrollView {
                VStack(spacing: 18) {
                    RunnerInlineNotice(
                        text: helperMessage
                            ?? "Open iMessage or Telegram."
                    )

                    actionCard(
                        title: "iMessage",
                        subtitle: "Open the native Messages composer",
                        logo: AnyView(ChannelLogoImage(resourceName: "imessage")),
                        action: openMessages
                    )

                    actionCard(
                        title: "Telegram",
                        subtitle: "Open Telegram or fall back to the share link",
                        logo: AnyView(ChannelLogoImage(resourceName: "telegram")),
                        action: openTelegram
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }

    private func actionCard(title: String, subtitle: String, logo: AnyView, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.buttonPress()
            action()
        } label: {
            channelCard(title: title, subtitle: subtitle, logo: logo)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func channelCard(title: String, subtitle: String, logo: AnyView) -> some View {
        HStack(spacing: 14) {
            logo
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(RunnerTypography.sans(15, weight: .semibold))
                    .foregroundStyle(RunnerTheme.primaryText)

                Text(subtitle)
                    .font(RunnerTypography.sans(12, weight: .medium))
                    .foregroundStyle(RunnerTheme.secondaryText)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(RunnerTheme.secondaryText)
        }
        .padding(16)
        .runnerCard()
    }

    private func openMessages() {
        guard let url = URL(string: "sms:") else { return }
        helperMessage = "Opening iMessage."
        openURL(url)
    }

    private func openTelegram() {
        let deepLink = URL(string: "tg://msg_url?url=https://chorus.com&text=Open%20Chorus")
        let fallback = URL(string: "https://t.me/share/url?url=https://chorus.com&text=Open%20Chorus")

        if let deepLink, UIApplication.shared.canOpenURL(deepLink) {
            helperMessage = "Opening Telegram."
            UIApplication.shared.open(deepLink)
        } else if let fallback {
            helperMessage = "Telegram app not found. Opening the share link instead."
            openURL(fallback)
        }
    }
}

private struct ChannelLogoImage: View {
    let resourceName: String

    var body: some View {
        Group {
            if let uiImage = UIImage(named: resourceName) ?? UIImage(named: "\(resourceName).png") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(RunnerTheme.elevated)
                    .overlay(
                        Image(systemName: "message")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(RunnerTheme.primaryText)
                    )
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
    }
}
