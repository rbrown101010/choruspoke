import SwiftUI
import UIKit

private enum AgentChannelKind: CaseIterable {
    case messages
    case telegram

    var title: String {
        switch self {
        case .messages:
            return "Messages"
        case .telegram:
            return "Telegram"
        }
    }

    var resourceName: String {
        switch self {
        case .messages:
            return "imessage"
        case .telegram:
            return "telegram"
        }
    }

    var fallbackSymbol: String {
        switch self {
        case .messages:
            return "message.fill"
        case .telegram:
            return "paperplane.fill"
        }
    }
}

struct ContactLinksSheetView: View {
    @EnvironmentObject private var appModel: RunnerAppModel
    @Environment(\.openURL) private var openURL

    @State private var channels: [AgentConnectionRecord] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var helperMessage: String?

    private var reloadKey: String {
        "\(appModel.selectedAgentID ?? "none")::\(appModel.config.lastConnectedAt?.timeIntervalSince1970 ?? 0)"
    }

    private var messagesChannel: AgentConnectionRecord? {
        channels.first(where: { $0.provider == "texting" })
    }

    private var telegramChannel: AgentConnectionRecord? {
        channels.first(where: { $0.provider == "telegram" })
    }

    private var hasLinkedChannels: Bool {
        messagesChannel != nil || telegramChannel != nil
    }

    var body: some View {
        RunnerPanel(title: "Channels") {
            Group {
                if !appModel.isSignedIn {
                    RunnerEmptyState(
                        icon: "person.crop.circle.badge.exclamationmark",
                        title: "Sign in first",
                        message: "Authenticate with Chorus to load the messaging channels linked to each agent."
                    )
                } else if appModel.selectedAgent == nil {
                    RunnerEmptyState(
                        icon: "message",
                        title: "Choose an agent",
                        message: "Pick an agent from the home screen selector to see its linked channels."
                    )
                } else if isLoading && !hasLinkedChannels {
                    ProgressView()
                        .tint(RunnerTheme.primaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if let error {
                                RunnerInlineNotice(text: error)
                            }

                            if let helperMessage {
                                RunnerInlineNotice(text: helperMessage)
                            }

                            if !hasLinkedChannels && error == nil {
                                RunnerInlineNotice(text: "No messaging channels are linked to this agent yet.")
                            }

                            channelCard(kind: .messages, record: messagesChannel)
                            channelCard(kind: .telegram, record: telegramChannel)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    }
                }
            }
        }
        .task(id: reloadKey) {
            await load()
        }
    }

    @ViewBuilder
    private func channelCard(kind: AgentChannelKind, record: AgentConnectionRecord?) -> some View {
        let isActionable = isChannelActionable(kind, record: record)

        if isActionable {
            Button {
                Haptics.buttonPress()
                openChannel(kind, record: record)
            } label: {
                channelCardContent(kind: kind, record: record, isActionable: true)
            }
            .buttonStyle(ScaleButtonStyle())
        } else {
            channelCardContent(kind: kind, record: record, isActionable: false)
        }
    }

    private func channelCardContent(kind: AgentChannelKind, record: AgentConnectionRecord?, isActionable: Bool) -> some View {
        HStack(spacing: 14) {
            ChannelLogoImage(resourceName: kind.resourceName, fallbackSymbol: kind.fallbackSymbol)

            VStack(alignment: .leading, spacing: 6) {
                Text(kind.title)
                    .font(RunnerTypography.sans(15, weight: .semibold))
                    .foregroundStyle(RunnerTheme.primaryText)

                Text(channelSubtitle(for: kind, record: record))
                    .font(RunnerTypography.sans(12, weight: .medium))
                    .foregroundStyle(RunnerTheme.secondaryText)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 8) {
                Text(channelStatusLabel(for: record))
                    .font(RunnerTypography.sans(11, weight: .bold))
                    .foregroundStyle(channelStatusColor(for: record))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(channelStatusColor(for: record).opacity(0.12)))
                    .overlay(Capsule().stroke(channelStatusColor(for: record).opacity(0.18), lineWidth: 1))

                if isActionable {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(RunnerTheme.secondaryText)
                }
            }
        }
        .padding(16)
        .runnerCard()
        .opacity(record == nil ? 0.86 : 1)
    }

    private func channelSubtitle(for kind: AgentChannelKind, record: AgentConnectionRecord?) -> String {
        guard let record else {
            return "Not linked on this agent."
        }

        switch kind {
        case .messages:
            if let number = record.texting?.destinationE164?.nilIfEmpty {
                if let senderNumber = record.texting?.senderNumber?.nilIfEmpty {
                    return "\(number) via \(senderNumber)"
                }
                return number
            }

            if let reason = record.texting?.pendingReason?.nilIfEmpty {
                return reason.replacingOccurrences(of: "_", with: " ").capitalized
            }

            return "Texting is linked to this agent."
        case .telegram:
            return record.connection.accountEmail
                ?? record.connection.label
                ?? "Telegram is linked to this agent."
        }
    }

    private func channelStatusLabel(for record: AgentConnectionRecord?) -> String {
        guard let record else { return "Not linked" }

        if record.provider == "texting" {
            if let status = record.texting?.status?.nilIfEmpty {
                return status.replacingOccurrences(of: "_", with: " ").capitalized
            }
            return "Linked"
        }

        if record.connection.refreshExhausted == true {
            return "Needs refresh"
        }

        if record.connection.isActive == false {
            return "Inactive"
        }

        return "Linked"
    }

    private func channelStatusColor(for record: AgentConnectionRecord?) -> Color {
        guard let record else { return RunnerTheme.tertiaryText }

        if record.provider == "texting", let status = record.texting?.status?.uppercased() {
            switch status {
            case "ACTIVE", "ENROLLED":
                return RunnerTheme.accent
            case "PENDING_DEPLOYMENT", "PENDING":
                return RunnerTheme.statusWarning
            default:
                return RunnerTheme.statusError
            }
        }

        if record.connection.refreshExhausted == true || record.connection.isActive == false {
            return RunnerTheme.statusWarning
        }

        return RunnerTheme.secondaryText
    }

    private func isChannelActionable(_ kind: AgentChannelKind, record: AgentConnectionRecord?) -> Bool {
        guard let record else { return false }

        switch kind {
        case .messages:
            return record.texting?.destinationE164?.nilIfEmpty != nil
        case .telegram:
            return record.connection.isActive != false
        }
    }

    private func openChannel(_ kind: AgentChannelKind, record: AgentConnectionRecord?) {
        guard let record else { return }

        switch kind {
        case .messages:
            guard let destination = record.texting?.destinationE164?.nilIfEmpty,
                  let url = URL(string: "sms:\(destination)") else {
                return
            }

            helperMessage = "Opening Messages."
            openURL(url)

        case .telegram:
            let deepLink = URL(string: "tg://")
            let fallback = URL(string: "https://t.me")

            if let deepLink, UIApplication.shared.canOpenURL(deepLink) {
                helperMessage = "Opening Telegram."
                UIApplication.shared.open(deepLink)
            } else if let fallback {
                helperMessage = "Telegram app not found. Opening Telegram on the web instead."
                openURL(fallback)
            }
        }
    }

    private func load() async {
        guard appModel.isSignedIn, appModel.selectedAgent != nil else {
            channels = []
            error = nil
            helperMessage = nil
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            channels = try await appModel.listAgentConnections()
                .filter { $0.provider == "texting" || $0.provider == "telegram" }
            error = nil
        } catch {
            channels = []
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private struct ChannelLogoImage: View {
    let resourceName: String
    let fallbackSymbol: String

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
                        Image(systemName: fallbackSymbol)
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
