import SwiftUI

private enum HomeSheet: String, Identifiable {
    case files
    case skills
    case connections
    case cron
    case channels
    case settings

    var id: String { rawValue }
}

private enum HomeRoute: String, Identifiable {
    case newAgent

    var id: String { rawValue }
}

struct HomeView: View {
    @EnvironmentObject private var appModel: RunnerAppModel
    @State private var activeSheet: HomeSheet?
    @State private var activeRoute: HomeRoute?

    var body: some View {
        ZStack {
            RunnerBackgroundView()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                Spacer()

                hero
                    .offset(y: -84)

                bottomTabs
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .task {
            await appModel.bootstrapApp()
        }
        .sheet(item: $activeSheet) { sheet in
            destination(for: sheet)
                .presentationDetents([sheet == .files ? .fraction(0.90) : .fraction(0.86)])
                .presentationDragIndicator(.visible)
        }
        .navigationDestination(item: $activeRoute) { route in
            switch route {
            case .newAgent:
                NewAgentPageView()
            }
        }
    }

    private var topBar: some View {
        HStack {
            agentSelector

            Spacer()

            Button {
                Haptics.tap()
                activeSheet = .settings
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [RunnerTheme.accentBlue, RunnerTheme.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)

                    Text("R")
                        .font(RunnerTypography.sans(15, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var agentSelector: some View {
        Menu {
            Button {
            } label: {
                Label("Runner Agent", systemImage: "checkmark")
            }
            .disabled(true)

            Divider()

            Button {
                Haptics.mainButton()
                activeRoute = .newAgent
            } label: {
                Label("New Agent", systemImage: "plus")
            }

            Divider()

            ForEach(2...5, id: \.self) { index in
                Button("Agent \(index)") {
                }
                .disabled(true)
            }
        } label: {
            HStack(spacing: 8) {
                Text("Runner Agent")
                    .font(RunnerTypography.sans(13, weight: .semibold))
                    .foregroundStyle(RunnerTheme.primaryText)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(RunnerTheme.secondaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(RunnerTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(RunnerTheme.borderStrong, lineWidth: 1)
            )
        }
    }

    private var hero: some View {
        VStack(spacing: 0) {
            RunnerLissajousView()
                .frame(width: 336, height: 236)
                .offset(y: -42)
                .padding(.bottom, -24)

            Text(appModel.agentTitle)
                .font(RunnerTypography.sans(34, weight: .semibold))
                .foregroundStyle(RunnerTheme.primaryText)
                .tracking(-0.6)
                .padding(.top, -18)

            VStack(spacing: 4) {
                Text(appModel.agentStatusLine)
                    .font(RunnerTypography.sans(14, weight: .medium))
                    .foregroundStyle(RunnerTheme.primaryText.opacity(0.76))
                    .multilineTextAlignment(.center)

                Text(appModel.agentSubtitle)
                    .font(RunnerTypography.sans(14, weight: .medium))
                    .foregroundStyle(RunnerTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 34)
            .padding(.top, 10)
        }
        .offset(y: -26)
    }

    private var bottomTabs: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ActionButton(icon: .cron, label: "Cron Jobs") {
                    activeSheet = .cron
                }

                ActionButton(icon: .connections, label: "Connections") {
                    activeSheet = .connections
                }
            }

            HStack(spacing: 12) {
                ActionButton(icon: .files, label: "Files") {
                    activeSheet = .files
                }

                ActionButton(icon: .skills, label: "Skills") {
                    activeSheet = .skills
                }

                ActionButton(icon: .channels, label: "Channels") {
                    activeSheet = .channels
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for sheet: HomeSheet) -> some View {
        switch sheet {
        case .files:
            FilesSheetView()
        case .skills:
            SkillsSheetView()
        case .connections:
            ConnectionsSheetView()
        case .cron:
            CronJobsSheetView()
        case .channels:
            ContactLinksSheetView()
        case .settings:
            SettingsView()
        }
    }
}
