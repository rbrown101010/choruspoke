import SwiftUI

private enum SkillsTab: Hashable {
    case installed
    case marketplace
}

private enum SkillRoute: Hashable {
    case installed(RunnerSkill)
    case marketplace(RunnerMarketplaceSkill)
}

struct SkillsSheetView: View {
    @EnvironmentObject private var appModel: RunnerAppModel
    @State private var selectedTab: SkillsTab = .installed
    @State private var installedSkills: [RunnerSkill] = []
    @State private var marketplaceSkills: [RunnerMarketplaceSkill] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            RunnerPanel(title: "Skills") {
                Group {
                    if appModel.client == nil {
                        RunnerEmptyState(
                            icon: "sparkles",
                            title: "Connect to runner first",
                            message: "Installed and marketplace skills load from the live runner workspace."
                        )
                    } else if isLoading && installedSkills.isEmpty && marketplaceSkills.isEmpty {
                        ProgressView()
                            .tint(RunnerTheme.primaryText)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(summaryLine)
                                    .font(RunnerTypography.sans(12, weight: .medium))
                                    .foregroundStyle(RunnerTheme.tertiaryText)

                                RunnerSegmentedControl(
                                    options: [(.installed, "Installed"), (.marketplace, "Marketplace")],
                                    selection: $selectedTab
                                )

                                if let error {
                                    RunnerInlineNotice(text: error)
                                }

                                if selectedTab == .installed {
                                    installedList
                                } else {
                                    marketplaceList
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationDestination(for: SkillRoute.self) { route in
                switch route {
                case .installed(let skill):
                    InstalledSkillDetailView(skill: skill)
                case .marketplace(let skill):
                    MarketplaceSkillDetailView(skill: skill)
                }
            }
            .task {
                await load()
            }
        }
    }

    private var summaryLine: String {
        switch selectedTab {
        case .installed:
            return "\(installedSkills.count) skills installed on this runner"
        case .marketplace:
            return "\(marketplaceSkills.count) skills available in marketplace"
        }
    }

    private var installedList: some View {
        Group {
            if installedSkills.isEmpty {
                RunnerEmptyState(
                    icon: "shippingbox",
                    title: "No installed skills",
                    message: "Installed skills from runner will appear here."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(installedSkills) { skill in
                        NavigationLink(value: SkillRoute.installed(skill)) {
                            installedSkillRow(skill)
                        }
                    }
                }
            }
        }
    }

    private var marketplaceList: some View {
        Group {
            if marketplaceSkills.isEmpty {
                RunnerEmptyState(
                    icon: "magnifyingglass",
                    title: "Marketplace is empty",
                    message: "Try again once runner can reach the skill marketplace."
                )
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(marketplaceSkills) { skill in
                        NavigationLink(value: SkillRoute.marketplace(skill)) {
                            marketplaceCard(skill)
                        }
                    }
                }
            }
        }
    }

    private func installedSkillRow(_ skill: RunnerSkill) -> some View {
        HStack(alignment: .top, spacing: 14) {
            RunnerSkillArtworkView(
                imageURL: appModel.client?.skillIconURL(skillKey: skill.skillKey),
                fallbackSystemName: "puzzlepiece.extension",
                size: 48
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(skill.title)
                    .font(RunnerTypography.sans(16, weight: .semibold))
                    .foregroundStyle(RunnerTheme.primaryText)
                    .multilineTextAlignment(.leading)

                Text(skill.description)
                    .font(RunnerTypography.sans(13, weight: .medium))
                    .foregroundStyle(RunnerTheme.secondaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    RunnerSkillPill(title: runnerSourceDisplayName(skill.source), systemImage: "building.2")

                    if skill.setup.needsAttention {
                        RunnerSkillPill(
                            title: "Setup",
                            systemImage: "wrench.adjustable",
                            fill: RunnerTheme.statusWarning.opacity(0.18),
                            foreground: RunnerTheme.statusWarning
                        )
                    } else if skill.setup.ready {
                        RunnerSkillPill(
                            title: "Ready",
                            systemImage: "checkmark",
                            fill: RunnerTheme.accent.opacity(0.14),
                            foreground: RunnerTheme.accent
                        )
                    }

                    if skill.always {
                        RunnerSkillPill(title: "Always", systemImage: "bolt.fill")
                    }
                }
            }

            Spacer(minLength: 10)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(RunnerTheme.tertiaryText)
                .padding(.top, 4)
        }
        .padding(16)
        .runnerCard()
    }

    private func marketplaceCard(_ skill: RunnerMarketplaceSkill) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                RunnerSkillArtworkView(
                    imageURL: appModel.client?.marketplaceIconURL(slug: skill.slug, source: skill.source),
                    fallbackSystemName: "puzzlepiece.extension",
                    size: 52
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(skill.displayName)
                        .font(RunnerTypography.sans(17, weight: .semibold))
                        .foregroundStyle(RunnerTheme.primaryText)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        Text("by \(skill.sourceDisplayName)")
                            .font(RunnerTypography.sans(12, weight: .semibold))
                            .foregroundStyle(RunnerTheme.tertiaryText)

                        if let version = skill.latestVersion, !version.isEmpty {
                            Circle()
                                .fill(RunnerTheme.tertiaryText.opacity(0.55))
                                .frame(width: 3, height: 3)

                            Text("v\(version)")
                                .font(RunnerTypography.sans(12, weight: .semibold))
                                .foregroundStyle(RunnerTheme.tertiaryText)
                        }
                    }
                }

                Spacer(minLength: 10)
            }

            Text(skill.summary)
                .font(RunnerTypography.sans(13, weight: .medium))
                .foregroundStyle(RunnerTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            if let dependencies = skill.dependencies, !dependencies.isEmpty {
                Text("\(dependencies.count) dependencies")
                    .font(RunnerTypography.sans(12, weight: .semibold))
                    .foregroundStyle(RunnerTheme.tertiaryText)
            }
        }
        .padding(18)
        .runnerCard()
    }

    private func load() async {
        guard let client = appModel.client else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            async let skillsTask = client.listSkills()
            async let marketplaceTask = client.browseMarketplace(limit: 30)

            let skillsResponse = try await skillsTask
            let marketplaceResponse = try await marketplaceTask

            installedSkills = skillsResponse.skills.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            marketplaceSkills = marketplaceResponse.items
            error = nil
        } catch {
            installedSkills = []
            marketplaceSkills = []
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private struct InstalledSkillDetailView: View {
    @EnvironmentObject private var appModel: RunnerAppModel
    let skill: RunnerSkill

    @State private var content: String?
    @State private var loadNote: String?
    @State private var isLoading = false

    var body: some View {
        RunnerPanel(title: skill.title) {
            Group {
                if isLoading && content == nil {
                    ProgressView()
                        .tint(RunnerTheme.primaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            headerCard

                            RunnerSkillSectionCard(title: content == nil ? "Overview" : "Skill File") {
                                if let content, !content.isEmpty {
                                    RunnerMarkdownView(content: content)
                                } else {
                                    Text(skill.description)
                                        .font(RunnerTypography.sans(15, weight: .medium))
                                        .foregroundStyle(RunnerTheme.primaryText)
                                        .multilineTextAlignment(.leading)
                                }
                            }

                            if let loadNote {
                                RunnerSkillFootnote(text: loadNote)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    }
                }
            }
        }
        .task {
            await load()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                RunnerSkillArtworkView(
                    imageURL: appModel.client?.skillIconURL(skillKey: skill.skillKey),
                    fallbackSystemName: "puzzlepiece.extension",
                    size: 56
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(runnerSourceDisplayName(skill.source))
                        .font(RunnerTypography.sans(12, weight: .semibold))
                        .foregroundStyle(RunnerTheme.tertiaryText)

                    HStack(spacing: 8) {
                        if skill.setup.needsAttention {
                            RunnerSkillPill(
                                title: "Setup needed",
                                systemImage: "wrench.adjustable",
                                fill: RunnerTheme.statusWarning.opacity(0.18),
                                foreground: RunnerTheme.statusWarning
                            )
                        } else if skill.setup.ready {
                            RunnerSkillPill(
                                title: "Ready",
                                systemImage: "checkmark",
                                fill: RunnerTheme.accent.opacity(0.14),
                                foreground: RunnerTheme.accent
                            )
                        }

                        if skill.always {
                            RunnerSkillPill(title: "Always", systemImage: "bolt.fill")
                        }
                    }
                }

                Spacer()
            }

            Text(skill.description)
                .font(RunnerTypography.sans(14, weight: .medium))
                .foregroundStyle(RunnerTheme.secondaryText)
                .multilineTextAlignment(.leading)
        }
        .padding(18)
        .runnerCard()
    }

    private func load() async {
        guard let client = appModel.client else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.skillContent(name: skill.name)
            content = response.content
            loadNote = nil
        } catch {
            loadNote = "Runner couldn’t load the full skill file. Showing the installed skill summary instead."
        }
    }
}

private struct MarketplaceSkillDetailView: View {
    @EnvironmentObject private var appModel: RunnerAppModel
    let skill: RunnerMarketplaceSkill

    @State private var content: String?
    @State private var detail: RunnerMarketplaceSkillDetail?
    @State private var loadNote: String?
    @State private var installState: String?
    @State private var isLoading = false
    @State private var isInstalling = false

    var body: some View {
        RunnerPanel(title: skill.displayName) {
            Group {
                if isLoading && detail == nil && content == nil {
                    ProgressView()
                        .tint(RunnerTheme.primaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            if let installState {
                                RunnerInlineNotice(text: installState)
                            }

                            headerCard

                            Button {
                                Task {
                                    await install()
                                }
                            } label: {
                                HStack {
                                    if isInstalling {
                                        ProgressView()
                                            .tint(.white)
                                    }

                                    Text(isInstalling ? "Installing…" : "Install Skill")
                                        .font(RunnerTypography.sans(14, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [RunnerTheme.accentBlue, RunnerTheme.blueHalo],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(isInstalling)

                            if let content, !content.isEmpty {
                                RunnerSkillSectionCard(title: "Skill File") {
                                    RunnerMarkdownView(content: content)
                                }
                            } else {
                                RunnerSkillSectionCard(title: "Overview") {
                                    VStack(alignment: .leading, spacing: 14) {
                                        Text(detail?.summary ?? skill.summary)
                                            .font(RunnerTypography.sans(15, weight: .medium))
                                            .foregroundStyle(RunnerTheme.primaryText)
                                            .multilineTextAlignment(.leading)

                                        if let dependencies = skill.dependencies, !dependencies.isEmpty {
                                            HStack(spacing: 8) {
                                                ForEach(dependencies.prefix(3), id: \.self) { dependency in
                                                    RunnerSkillPill(title: dependency, systemImage: "link")
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            if let loadNote {
                                RunnerSkillFootnote(text: loadNote)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    }
                }
            }
        }
        .task {
            await load()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                RunnerSkillArtworkView(
                    imageURL: appModel.client?.marketplaceIconURL(slug: skill.slug, source: skill.source),
                    fallbackSystemName: "puzzlepiece.extension",
                    size: 58
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("by \(detail?.owner ?? skill.sourceDisplayName)")
                        .font(RunnerTypography.sans(12, weight: .semibold))
                        .foregroundStyle(RunnerTheme.tertiaryText)

                    if let version = detail?.latestVersion ?? skill.latestVersion, !version.isEmpty {
                        Text("v\(version)")
                            .font(RunnerTypography.sans(12, weight: .semibold))
                            .foregroundStyle(RunnerTheme.tertiaryText)
                    }
                }

                Spacer()
            }

            Text(detail?.summary ?? skill.summary)
                .font(RunnerTypography.sans(14, weight: .medium))
                .foregroundStyle(RunnerTheme.secondaryText)
                .multilineTextAlignment(.leading)
        }
        .padding(18)
        .runnerCard()
    }

    private func load() async {
        guard let client = appModel.client else { return }

        isLoading = true
        defer { isLoading = false }

        var notes: [String] = []

        do {
            detail = try await client.marketplaceSkillDetail(slug: skill.slug, source: skill.source)
        } catch {
            notes.append("Showing the marketplace summary because runner couldn’t load the full skill details.")
        }

        do {
            content = try await client.marketplaceSkillFile(slug: skill.slug, source: skill.source).content
        } catch {
            notes.append("Runner couldn’t load the full skill file.")
        }

        loadNote = notes.isEmpty ? nil : notes.joined(separator: " ")
    }

    private func install() async {
        guard let client = appModel.client else { return }

        isInstalling = true
        defer { isInstalling = false }

        do {
            let result = try await client.installMarketplaceSkill(slug: skill.slug, source: skill.source)
            installState = "Installed \(result.installedSkillKey ?? result.slug)."
            Haptics.success()
        } catch {
            installState = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private struct RunnerSkillPill: View {
    let title: String
    var systemImage: String? = nil
    var fill: Color = RunnerTheme.elevated
    var foreground: Color = RunnerTheme.secondaryText

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
            }

            Text(title)
                .lineLimit(1)
        }
        .font(RunnerTypography.sans(11, weight: .semibold))
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(fill)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(RunnerTheme.border.opacity(0.8), lineWidth: 1)
        )
    }
}

private struct RunnerSkillSectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(RunnerTypography.sans(13, weight: .semibold))
                .foregroundStyle(RunnerTheme.secondaryText)

            content
        }
        .padding(18)
        .runnerCard()
    }
}

private struct RunnerSkillFootnote: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RunnerTheme.tertiaryText)
                .padding(.top, 1)

            Text(text)
                .font(RunnerTypography.sans(12, weight: .medium))
                .foregroundStyle(RunnerTheme.tertiaryText)
        }
    }
}

private struct RunnerSkillArtworkView: View {
    let imageURL: URL?
    let fallbackSystemName: String
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            .fill(RunnerTheme.surface)
            .frame(width: size, height: size)
            .overlay {
                if let imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .padding(size * 0.2)
                        default:
                            fallbackIcon
                        }
                    }
                } else {
                    fallbackIcon
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                    .stroke(RunnerTheme.border, lineWidth: 1)
            )
    }

    private var fallbackIcon: some View {
        Image(systemName: fallbackSystemName)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(RunnerTheme.primaryText)
    }
}

private func runnerSourceDisplayName(_ source: String) -> String {
    switch source {
    case "chorus":
        return "Chorus"
    case "workspace":
        return "Workspace"
    default:
        return source.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
