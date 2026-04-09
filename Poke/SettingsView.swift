import SwiftUI

private enum SettingsAction {
    case google
    case apple
    case refresh
    case signOut
}

struct SettingsView: View {
    @EnvironmentObject private var appModel: RunnerAppModel
    @Environment(\.dismiss) private var dismiss

    @State private var actionInFlight: SettingsAction?

    var body: some View {
        RunnerPanel(title: "Menu") {
            ScrollView {
                VStack(spacing: 18) {
                    profileCard
                    accountCard
                    if appModel.isSignedIn {
                        agentCard
                    }
                    environmentCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }

    private var profileCard: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [RunnerTheme.accentBlue, RunnerTheme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 76, height: 76)
                .overlay(
                    Text(initials)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                )

            Text(appModel.authenticatedUser?.displayName ?? "Chorus Companion")
                .font(RunnerTypography.sans(22, weight: .semibold))
                .foregroundStyle(RunnerTheme.primaryText)

            VStack(spacing: 3) {
                Text(appModel.authenticatedUser?.emailAddress ?? "Sign in with Clerk to load your agents")
                    .font(RunnerTypography.sans(13, weight: .semibold))
                    .foregroundStyle(RunnerTheme.secondaryText)

                Text(statusLine)
                    .font(RunnerTypography.sans(12, weight: .medium))
                    .foregroundStyle(RunnerTheme.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .runnerCard()
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(appModel.isSignedIn ? "Account" : "Sign In")
                .font(RunnerTypography.sans(15, weight: .semibold))
                .foregroundStyle(RunnerTheme.primaryText)

            if let message = appModel.authMessage {
                RunnerInlineNotice(text: message)
            }

            if let message = appModel.agentsLoadError {
                RunnerInlineNotice(text: message)
            }

            if appModel.isSignedIn {
                Button {
                    Task { await run(.refresh) { await appModel.refreshAgentsAndReconnect() } }
                } label: {
                    settingsButtonLabel(
                        title: actionInFlight == .refresh ? "Refreshing…" : "Refresh Agents",
                        icon: "arrow.clockwise",
                        fill: RunnerTheme.elevated
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(actionInFlight != nil)

                Button {
                    Task {
                        await run(.signOut) {
                            await appModel.signOut()
                        }
                        dismiss()
                    }
                } label: {
                    settingsButtonLabel(
                        title: actionInFlight == .signOut ? "Signing Out…" : "Sign Out",
                        icon: "rectangle.portrait.and.arrow.right",
                        fill: RunnerTheme.surface
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(actionInFlight != nil)
            } else {
                Button {
                    Task {
                        await run(.google) {
                            await appModel.signInWithGoogle()
                        }
                    }
                } label: {
                    settingsButtonLabel(
                        title: actionInFlight == .google ? "Connecting Google…" : "Continue with Google",
                        icon: "globe",
                        fill: LinearGradient(
                            colors: [RunnerTheme.accentBlue, RunnerTheme.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(actionInFlight != nil)

                Button {
                    Task {
                        await run(.apple) {
                            await appModel.signInWithApple()
                        }
                    }
                } label: {
                    settingsButtonLabel(
                        title: actionInFlight == .apple ? "Connecting Apple…" : "Continue with Apple",
                        icon: "apple.logo",
                        fill: RunnerTheme.surface
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(actionInFlight != nil)
            }
        }
        .padding(18)
        .runnerCard()
    }

    private var agentCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current Agent")
                .font(RunnerTypography.sans(15, weight: .semibold))
                .foregroundStyle(RunnerTheme.primaryText)

            if let agent = appModel.selectedAgent {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(agent.name)
                                .font(RunnerTypography.sans(17, weight: .semibold))
                                .foregroundStyle(RunnerTheme.primaryText)

                            Text(agent.detailLine)
                                .font(RunnerTypography.sans(13, weight: .medium))
                                .foregroundStyle(RunnerTheme.secondaryText)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 8)

                        Text(agent.statusLabel)
                            .font(RunnerTypography.sans(11, weight: .bold))
                            .foregroundStyle(RunnerTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(RunnerTheme.accent.opacity(0.14)))
                            .overlay(Capsule().stroke(RunnerTheme.accent.opacity(0.2), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        infoRow(title: "Runner host", value: appModel.currentRunnerHostLabel)
                        infoRow(title: "Connection", value: appModel.connectionStatus.label)
                    }
                }
                .padding(16)
                .runnerCard()
            } else {
                RunnerEmptyState(
                    icon: "desktopcomputer.trianglebadge.exclamationmark",
                    title: "No selected agent",
                    message: "Pick one from the home screen selector once your account loads."
                )
            }
        }
        .padding(18)
        .runnerCard()
    }

    private var environmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Environment")
                .font(RunnerTypography.sans(15, weight: .semibold))
                .foregroundStyle(RunnerTheme.primaryText)

            infoRow(title: "Agents backend", value: appModel.backendHostLabel)

            if let connectedAt = appModel.config.lastConnectedAt {
                infoRow(title: "Last connected", value: RunnerDate.shortDateTime.string(from: connectedAt))
            }

            if let message = appModel.connectionStatus.errorMessage {
                RunnerInlineNotice(text: message)
            }
        }
        .padding(18)
        .runnerCard()
    }

    private var initials: String {
        if let displayName = appModel.authenticatedUser?.displayName.nilIfEmpty {
            let pieces = displayName.split(separator: " ").prefix(2)
            let text = pieces.compactMap { $0.first }.map(String.init).joined()
            return text.isEmpty ? "C" : text.uppercased()
        }

        return "C"
    }

    private var statusLine: String {
        switch appModel.authState {
        case .loading:
            return "Loading session"
        case .signedOut:
            return "Signed out"
        case .signedIn:
            return appModel.agentStatusLine
        case .failed(let message):
            return message
        }
    }

    private func settingsButtonLabel(title: String, icon: String, fill: some ShapeStyle) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
            Text(title)
                .font(.system(size: 14, weight: .bold))
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(RunnerTheme.borderStrong, lineWidth: 1)
        )
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title)
                .font(RunnerTypography.sans(12, weight: .semibold))
                .foregroundStyle(RunnerTheme.tertiaryText)
                .frame(width: 92, alignment: .leading)

            Text(value)
                .font(RunnerTypography.sans(13, weight: .medium))
                .foregroundStyle(RunnerTheme.primaryText)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
    }

    private func run(_ action: SettingsAction, operation: @escaping @MainActor () async -> Void) async {
        actionInFlight = action
        await operation()
        actionInFlight = nil

        if appModel.isSignedIn && (action == .google || action == .apple) {
            dismiss()
        }
    }
}
