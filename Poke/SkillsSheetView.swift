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

    private var reloadKey: String {
        "\(appModel.selectedAgentID ?? "none")::\(appModel.config.lastConnectedAt?.timeIntervalSince1970 ?? 0)"
    }

    var body: some View {
        NavigationStack {
            RunnerPanel(title: "Skills") {
                Group {
                    if appModel.client == nil {
                        RunnerEmptyState(
                            icon: "sparkles",
                            title: "Choose an agent first",
                            message: "Installed and marketplace skills load from the selected agent workspace."
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
                    MarketplaceSkillDetailView(
                        skill: skill,
                        onInstalled: {
                            selectedTab = .installed
                            await load()
                        }
                    )
                }
            }
            .task(id: reloadKey) {
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

                Text(runnerSourceDisplayName(skill.source))
                    .font(RunnerTypography.sans(12, weight: .semibold))
                    .foregroundStyle(RunnerTheme.tertiaryText)

                Text(skill.description)
                    .font(RunnerTypography.sans(13, weight: .medium))
                    .foregroundStyle(RunnerTheme.secondaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if skill.setup.needsAttention {
                        RunnerSkillPill(
                            title: "Setup",
                            systemImage: "wrench.adjustable",
                            fill: RunnerTheme.statusWarning.opacity(0.18),
                            foreground: RunnerTheme.statusWarning
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
        guard let client = appModel.client else {
            installedSkills = []
            marketplaceSkills = []
            error = nil
            return
        }

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
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appModel: RunnerAppModel
    let skill: RunnerMarketplaceSkill
    let onInstalled: () async -> Void

    @State private var content: String?
    @State private var detail: RunnerMarketplaceSkillDetail?
    @State private var loadNote: String?
    @State private var installState: String?
    @State private var isLoading = false
    @State private var isInstalling = false
    @State private var didInstall = false
    @State private var isDescriptionExpanded = false

    var body: some View {
        ZStack {
            RunnerBackgroundView()

            Group {
                if isLoading && detail == nil && content == nil {
                    ProgressView()
                        .tint(RunnerTheme.primaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            topBar

                            if let installState {
                                RunnerInlineNotice(text: installState)
                            }

                            headerBlock

                            Rectangle()
                                .fill(RunnerTheme.border.opacity(0.7))
                                .frame(height: 1)

                            if let content, !content.isEmpty {
                                RunnerMarkdownView(content: stripSkillFrontmatter(content))
                            } else {
                                Text(detail?.summary ?? skill.summary)
                                    .font(RunnerTypography.sans(15, weight: .medium))
                                    .foregroundStyle(RunnerTheme.primaryText)
                                    .multilineTextAlignment(.leading)
                            }

                            if let loadNote {
                                RunnerSkillFootnote(text: loadNote)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                        .padding(.top, 26)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await load()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RunnerTheme.primaryText)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(RunnerTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(RunnerTheme.borderStrong, lineWidth: 1)
                    )
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                RunnerSkillArtworkView(
                    imageURL: appModel.client?.marketplaceIconURL(slug: skill.slug, source: skill.source),
                    fallbackSystemName: "puzzlepiece.extension",
                    size: 52
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(skill.displayName)
                        .font(RunnerTypography.sans(26, weight: .semibold))
                        .foregroundStyle(RunnerTheme.primaryText)
                        .multilineTextAlignment(.leading)

                    Text("by \(detail?.owner ?? skill.sourceDisplayName)")
                        .font(RunnerTypography.sans(12, weight: .semibold))
                        .foregroundStyle(RunnerTheme.tertiaryText)

                    if let version = detail?.latestVersion ?? skill.latestVersion, !version.isEmpty, isDescriptionExpanded {
                        Text("v\(version)")
                            .font(RunnerTypography.sans(12, weight: .semibold))
                            .foregroundStyle(RunnerTheme.tertiaryText)
                    }
                }

                Spacer(minLength: 12)

                Button {
                    Task {
                        await install()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isInstalling {
                            ProgressView()
                                .tint(Color.black.opacity(0.72))
                        }

                        Text(installButtonTitle)
                            .font(RunnerTypography.sans(13, weight: .bold))
                    }
                    .foregroundStyle(installButtonForeground)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(installButtonFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(installButtonBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isInstalling || didInstall)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(displayedSummary)
                    .font(RunnerTypography.sans(15, weight: .medium))
                    .foregroundStyle(RunnerTheme.secondaryText)
                    .multilineTextAlignment(.leading)

                if summaryNeedsExpansion {
                    Button(isDescriptionExpanded ? "Show Less" : "Expand") {
                        Haptics.selection()
                        withAnimation(.spring(duration: 0.22)) {
                            isDescriptionExpanded.toggle()
                        }
                    }
                    .buttonStyle(.plain)
                    .font(RunnerTypography.sans(12.5, weight: .semibold))
                    .foregroundStyle(RunnerTheme.accentBlue)
                }
            }
        }
    }

    private var installButtonTitle: String {
        if didInstall {
            return "Installed"
        }

        return isInstalling ? "Installing" : "Install Skill"
    }

    private var installButtonFill: LinearGradient {
        if didInstall {
            return LinearGradient(colors: [RunnerTheme.statusConnected, RunnerTheme.statusConnected.opacity(0.86)], startPoint: .leading, endPoint: .trailing)
        }

        if isInstalling {
            return LinearGradient(colors: [Color.white.opacity(0.96), Color.white.opacity(0.88)], startPoint: .leading, endPoint: .trailing)
        }

        return LinearGradient(colors: [RunnerTheme.accentBlue, RunnerTheme.blueHalo], startPoint: .leading, endPoint: .trailing)
    }

    private var installButtonForeground: Color {
        isInstalling ? Color.black.opacity(0.78) : .white
    }

    private var installButtonBorder: Color {
        if didInstall {
            return RunnerTheme.statusConnected.opacity(0.4)
        }

        if isInstalling {
            return Color.white.opacity(0.22)
        }

        return RunnerTheme.accentBlue.opacity(0.3)
    }

    private var fullSummary: String {
        detail?.summary ?? skill.summary
    }

    private var summaryNeedsExpansion: Bool {
        fullSummary.count > 50
    }

    private var displayedSummary: String {
        guard !isDescriptionExpanded, summaryNeedsExpansion else {
            return fullSummary
        }

        let prefix = fullSummary.prefix(50)
        return "\(prefix)…"
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
            _ = try await client.installMarketplaceSkill(slug: skill.slug, source: skill.source)
            didInstall = true
            installState = nil
            Haptics.success()

            try? await Task.sleep(for: .milliseconds(450))
            await onInstalled()
            dismiss()
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

private func stripSkillFrontmatter(_ markdown: String) -> String {
    let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")

    guard normalized.hasPrefix("---\n") else {
        return normalized
    }

    let remainder = normalized.dropFirst(4)
    guard let closingRange = remainder.range(of: "\n---\n") else {
        return normalized
    }

    return String(remainder[closingRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
}
