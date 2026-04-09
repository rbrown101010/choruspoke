import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: RunnerAppModel
    @Environment(\.dismiss) private var dismiss

    @State private var draftURL = ""
    @State private var draftToken = ""
    @State private var helperMessage: String?
    @State private var isResolvingToken = false
    @State private var isConnecting = false

    var body: some View {
        RunnerPanel(title: "Settings") {
            ScrollView {
                VStack(spacing: 18) {
                    profileCard
                    connectionCard
                    helperCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .task {
            draftURL = appModel.config.baseURL
            draftToken = appModel.config.token
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
                    Text("R")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                )

            Text("Chorus Companion")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(RunnerTheme.primaryText)

            VStack(spacing: 3) {
                Text(appModel.connectionStatus.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RunnerTheme.secondaryText)

                Text(appModel.config.hostLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RunnerTheme.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .runnerCard()
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Connection")
                .font(RunnerTypography.sans(15, weight: .semibold))
                .foregroundStyle(RunnerTheme.primaryText)

            field(title: "Server URL", text: $draftURL, placeholder: "http://localhost")
            field(title: "Access token", text: $draftToken, placeholder: "Optional if dev-token is enabled")

            if let message = helperMessage {
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RunnerTheme.secondaryText)
            }

            VStack(spacing: 10) {
                Button {
                    draftURL = RunnerConnectionConfig.defaultLocal.baseURL
                    draftToken = ""
                    helperMessage = "Local simulator preset loaded."
                } label: {
                    settingsButtonLabel(title: "Use local dev preset", icon: "bolt.fill", fill: RunnerTheme.surface)
                }
                .buttonStyle(ScaleButtonStyle())

                Button {
                    Task {
                        await fetchDevToken()
                    }
                } label: {
                    settingsButtonLabel(
                        title: isResolvingToken ? "Fetching dev token…" : "Fetch dev token",
                        icon: "key.fill",
                        fill: RunnerTheme.elevated
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isResolvingToken)

                Button {
                    Task {
                        await connect()
                    }
                } label: {
                    settingsButtonLabel(
                        title: isConnecting ? "Connecting…" : "Connect to runner",
                        icon: "arrow.triangle.2.circlepath",
                        fill: LinearGradient(
                            colors: [RunnerTheme.accentBlue, RunnerTheme.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isConnecting)
            }

            if let connectedAt = appModel.config.lastConnectedAt {
                Text("Last connected: \(RunnerDate.shortDateTime.string(from: connectedAt))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RunnerTheme.tertiaryText)
            }
        }
        .padding(18)
        .runnerCard()
    }

    private var helperCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RunnerTheme.primaryText)

            Text("On the iOS simulator, `http://localhost` should work. On a physical iPhone, replace `localhost` with your Mac’s LAN IP or hostname so the phone can reach your runner host.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(RunnerTheme.secondaryText)

            Text("If the access token field is empty, the app will try `/api/v1/auth/dev-token` first.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(RunnerTheme.secondaryText)
        }
        .padding(18)
        .runnerCard()
    }

    private func field(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(RunnerTheme.secondaryText)

            TextField(placeholder, text: text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(RunnerTheme.primaryText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(RunnerTheme.elevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(RunnerTheme.border, lineWidth: 1)
                )
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

    private func fetchDevToken() async {
        isResolvingToken = true
        defer { isResolvingToken = false }

        do {
            let token = try await appModel.fetchDevToken(for: draftURL)
            draftToken = token
            helperMessage = "Fetched the local dev token."
        } catch {
            helperMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func connect() async {
        isConnecting = true
        defer { isConnecting = false }

        await appModel.updateConnection(baseURL: draftURL, token: draftToken)
        helperMessage = appModel.connectionStatus.errorMessage ?? "Runner connection updated."

        if appModel.connectionStatus.isConnected {
            Haptics.success()
            dismiss()
        }
    }
}
