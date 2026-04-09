import AuthenticationServices
import SwiftUI

struct ConnectionsSheetView: View {
    @EnvironmentObject private var appModel: RunnerAppModel

    @State private var oauthCoordinator = ConnectionOAuthSessionCoordinator()

    @State private var selectedCategoryID = ""
    @State private var agentConnections: [AgentConnectionRecord] = []
    @State private var userConnections: [AgentConnectionDetails] = []
    @State private var catalog: RunnerConnectionCatalogResponse?
    @State private var isLoading = false
    @State private var error: String?
    @State private var busyConnectionID: String?
    @State private var busyIntegrationID: String?
    @State private var inputSheet: ConnectionInputSheet?
    @State private var pendingDeleteTarget: ConnectionDeleteTarget?

    private var reloadKey: String {
        "\(appModel.selectedAgentID ?? "none")::\(appModel.config.lastConnectedAt?.timeIntervalSince1970 ?? 0)"
    }

    private var providerMap: [String: RunnerConnectionProvider] {
        Dictionary(uniqueKeysWithValues: (catalog?.providers ?? []).map { ($0.id, $0) })
    }

    private var nonChannelAgentConnections: [AgentConnectionRecord] {
        agentConnections.filter { !$0.isChannelLike }
    }

    private var linkedConnectionIDs: Set<String> {
        Set(nonChannelAgentConnections.map(\.integrationConnectionId))
    }

    private var reusableUserConnections: [AgentConnectionDetails] {
        userConnections.filter { connection in
            !isChannelLike(providerID: connection.provider) && connection.isActive != false && !linkedConnectionIDs.contains(connection.id)
        }
    }

    private var availableCategories: [RunnerConnectionCategory] {
        (catalog?.categories ?? []).compactMap { category in
            let integrations = category.integrations.filter { integration in
                !isChannelLike(providerID: integration.providerId) && integration.comingSoon != true
            }

            guard !integrations.isEmpty else { return nil }

            return RunnerConnectionCategory(
                id: category.id,
                label: category.label,
                integrations: integrations,
                sharedProvider: category.sharedProvider
            )
        }
    }

    private var orderedCategoryIDs: [String] {
        var ids = availableCategories.map(\.id)

        if let communicationIndex = ids.firstIndex(of: "communication"), communicationIndex != 0 {
            let communicationID = ids.remove(at: communicationIndex)
            ids.insert(communicationID, at: 0)
        }

        for providerID in nonChannelAgentConnections.map(\.provider) + reusableUserConnections.map(\.provider) {
            let categoryID = categoryID(forProvider: providerID)
            if !ids.contains(categoryID) {
                ids.append(categoryID)
            }
        }

        return ids
    }

    private var categoryTabs: [ConnectionCategoryTab] {
        orderedCategoryIDs.map {
            ConnectionCategoryTab(
                id: $0,
                label: categoryLabel(for: $0)
            )
        }
    }

    private var activeCategoryID: String {
        if categoryTabs.contains(where: { $0.id == selectedCategoryID }) {
            return selectedCategoryID
        }

        return categoryTabs.first?.id ?? ""
    }

    var body: some View {
        RunnerPanel(title: "Connections") {
            Group {
                if !appModel.isSignedIn {
                    RunnerEmptyState(
                        icon: "person.crop.circle.badge.exclamationmark",
                        title: "Sign in first",
                        message: "Authenticate with Chorus to load agent connections and provider actions."
                    )
                } else if appModel.selectedAgent == nil {
                    RunnerEmptyState(
                        icon: "desktopcomputer",
                        title: "Choose an agent",
                        message: "Pick an agent from the home screen selector before managing its connections."
                    )
                } else if isLoading && agentConnections.isEmpty && userConnections.isEmpty && catalog == nil {
                    ProgressView()
                        .tint(RunnerTheme.primaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            if let error {
                                RunnerInlineNotice(text: error)
                            }

                            if !categoryTabs.isEmpty {
                                categoryTabsRow
                            }

                            unifiedContent
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
        .sheet(item: $inputSheet) { sheet in
            ConnectionInputSheetView(
                sheet: sheet,
                isSubmitting: busyIntegrationID == sheet.integration.id,
                onSubmit: { values in
                    await submitInputSheet(sheet, values: values)
                }
            )
            .presentationDetents([.medium, .large])
        }
        .alert(
            "Delete connection?",
            isPresented: Binding(
                get: { pendingDeleteTarget != nil },
                set: { if !$0 { pendingDeleteTarget = nil } }
            ),
            presenting: pendingDeleteTarget
        ) { target in
            Button("Cancel", role: .cancel) {
                pendingDeleteTarget = nil
            }

            Button("Delete", role: .destructive) {
                Task {
                    await delete(target: target)
                }
            }
        } message: { target in
            Text(target.message)
        }
    }

    private var categoryTabsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categoryTabs) { tab in
                    Button {
                        Haptics.selection()
                        withAnimation(.spring(duration: 0.22)) {
                            selectedCategoryID = tab.id
                        }
                    } label: {
                        Text(tab.label)
                            .font(RunnerTypography.sans(13, weight: .semibold))
                            .foregroundStyle(activeCategoryID == tab.id ? RunnerTheme.primaryText : RunnerTheme.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(activeCategoryID == tab.id ? RunnerTheme.surface : RunnerTheme.elevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(activeCategoryID == tab.id ? RunnerTheme.borderStrong : RunnerTheme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var unifiedContent: some View {
        let integrations = addableIntegrations(in: activeCategoryID)

        if integrations.isEmpty {
            RunnerEmptyState(
                icon: "square.grid.2x2",
                title: "No connections here",
                message: "This category does not have any available providers yet."
            )
        } else {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(integrations) { integration in
                    integrationCard(integration)
                }
            }
        }
    }

    private func integrationCard(_ integration: RunnerConnectionIntegration) -> some View {
        let isBusy = busyIntegrationID == integration.id
        let isLinked = isIntegrationLinked(integration)
        let linkableConnection = coveringConnection(for: integration)
        let providerConnection = latestUserConnection(forProvider: integration.providerId)
        let linkedRecord = linkedRecord(for: integration)
        let provider = providerMap[integration.providerId]

        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbolName(for: integration.providerId))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RunnerTheme.accentBlue)
                .frame(width: 22)

                VStack(alignment: .leading, spacing: 5) {
                    Text(integration.name)
                        .font(RunnerTypography.sans(15, weight: .semibold))
                        .foregroundStyle(RunnerTheme.primaryText)

                Text(integrationSubtitle(
                    integration: integration,
                    provider: provider,
                    providerConnection: providerConnection,
                    linkedRecord: linkedRecord,
                    isLinked: isLinked
                ))
                    .font(RunnerTypography.sans(12.5, weight: .medium))
                    .foregroundStyle(RunnerTheme.secondaryText)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 8)

            if isBusy {
                ProgressView()
                    .tint(RunnerTheme.primaryText)
            } else if isLinked {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(RunnerTheme.primaryText)

                    if let linkedRecord {
                        Menu {
                            Button("Unlink") {
                                Task {
                                    await unlink(linkedRecord)
                                }
                            }

                            Button("Delete", role: .destructive) {
                                pendingDeleteTarget = .linked(linkedRecord)
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(RunnerTheme.tertiaryText)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
            } else {
                Button {
                    Task {
                        await connect(integration)
                    }
                } label: {
                    plusActionButton(title: actionTitle(for: integration, linkableConnection: linkableConnection, providerConnection: providerConnection, provider: provider))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .runnerCard()
        .opacity(isLinked ? 0.72 : 1)
    }

    private func plusActionButton(title: String) -> some View {
        Image(systemName: "plus")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color.white)
            .frame(width: 34, height: 34)
            .background(
                Circle()
                    .fill(RunnerTheme.accentBlue)
            )
            .overlay(
                Circle()
                    .stroke(RunnerTheme.accentBlue.opacity(0.2), lineWidth: 1)
            )
            .accessibilityLabel(title)
    }

    private func integrationSubtitle(
        integration: RunnerConnectionIntegration,
        provider: RunnerConnectionProvider?,
        providerConnection: AgentConnectionDetails?,
        linkedRecord: AgentConnectionRecord?,
        isLinked: Bool
    ) -> String {
        if isLinked {
            return linkedRecord?.subtitle ?? "Already linked to this agent."
        }

        if let providerConnection, providerConnection.covers(requiredScopes: integration.requiredScopes) {
            return "Link your existing \(providerConnection.providerDisplayTitle.lowercased()) connection to this agent."
        }

        if providerConnection != nil, provider?.authType == .oauth {
            return "Reauthorize to add the scopes needed for \(integration.name.lowercased())."
        }

        if provider?.authType == .nango {
            return "Existing \(integration.name.lowercased()) connections can be linked here once they exist on your account."
        }

        if let description = integration.description?.nilIfEmpty {
            return description
        }

        return provider?.displayName ?? integration.providerId.replacingOccurrences(of: "-", with: " ").capitalized
    }

    private func actionTitle(
        for integration: RunnerConnectionIntegration,
        linkableConnection: AgentConnectionDetails?,
        providerConnection: AgentConnectionDetails?,
        provider: RunnerConnectionProvider?
    ) -> String {
        if linkableConnection != nil {
            return "Link"
        }

        if providerConnection != nil, provider?.authType == .oauth {
            return "Reauth"
        }

        switch provider?.authType {
        case .api_key:
            return "Add Key"
        case .manual:
            return "Add"
        case .nango:
            return "Web Only"
        default:
            return "Connect"
        }
    }

    private func addableIntegrations(in categoryID: String?) -> [RunnerConnectionIntegration] {
        availableCategories
            .flatMap(\.integrations)
            .filter { integration in categoryID == nil || integration.categoryId == categoryID }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func linkedRecord(for integration: RunnerConnectionIntegration) -> AgentConnectionRecord? {
        nonChannelAgentConnections.first { record in
            record.provider == integration.providerId && record.connection.covers(requiredScopes: integration.requiredScopes)
        }
    }

    private func categoryID(forProvider providerID: String) -> String {
        for category in availableCategories {
            if category.integrations.contains(where: { $0.providerId == providerID }) {
                return category.id
            }
        }

        return "more"
    }

    private func categoryLabel(for categoryID: String) -> String {
        return availableCategories.first(where: { $0.id == categoryID })?.label ?? defaultCategoryLabel(for: categoryID)
    }

    private func isIntegrationLinked(_ integration: RunnerConnectionIntegration) -> Bool {
        nonChannelAgentConnections.contains { record in
            record.provider == integration.providerId && record.connection.covers(requiredScopes: integration.requiredScopes)
        }
    }

    private func coveringConnection(for integration: RunnerConnectionIntegration) -> AgentConnectionDetails? {
        userConnections.first { connection in
            connection.isActive != false &&
                connection.provider == integration.providerId &&
                !linkedConnectionIDs.contains(connection.id) &&
                connection.covers(requiredScopes: integration.requiredScopes)
        }
    }

    private func latestUserConnection(forProvider providerID: String) -> AgentConnectionDetails? {
        userConnections.first { connection in
            connection.isActive != false && connection.provider == providerID
        }
    }

    private func mergedScopes(existing: String?, required: [String]?) -> [String]? {
        let current = existing?.split(separator: " ").map(String.init) ?? []
        let needed = required ?? []
        let merged = Array(Set(current + needed)).sorted()
        return merged.isEmpty ? nil : merged
    }

    private func connect(_ integration: RunnerConnectionIntegration) async {
        error = nil

        if let reusable = coveringConnection(for: integration) {
            await link(reusable)
            return
        }

        guard let provider = providerMap[integration.providerId] else {
            error = "The connection provider metadata was missing."
            return
        }

        switch provider.authType {
        case .api_key:
            inputSheet = .apiKey(integration: integration, provider: provider)
        case .manual:
            inputSheet = .manual(integration: integration, provider: provider)
        case .nango:
            error = "\(provider.displayName) still uses the web-only connection flow. If you already connected it on the web, it will appear above and can be linked here."
        case .oauth:
            busyIntegrationID = integration.id
            defer { busyIntegrationID = nil }

            do {
                let existingScopes = latestUserConnection(forProvider: integration.providerId)?.scopes
                let authURL = try await appModel.authorizeConnection(
                    providerID: integration.providerId,
                    redirectTo: ChorusEnvironment.connectionRedirectURL,
                    scopes: mergedScopes(existing: existingScopes, required: integration.requiredScopes)
                )

                let callbackURL = try await oauthCoordinator.authorize(
                    url: authURL,
                    callbackScheme: ChorusEnvironment.connectionCallbackScheme
                )

                try await completeOAuthCallback(callbackURL)
                Haptics.success()
                await load()
            } catch {
                if !isCancelledOAuth(error) {
                    self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    private func submitInputSheet(_ sheet: ConnectionInputSheet, values: [String: String]) async {
        busyIntegrationID = sheet.integration.id
        defer { busyIntegrationID = nil }

        do {
            let created: AgentConnectionDetails

            switch sheet {
            case .apiKey(_, let provider):
                let token = values["token"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                created = try await appModel.createAPIKeyConnection(providerID: provider.id, tokenValue: token)
            case .manual(_, let provider):
                created = try await appModel.createManualConnection(providerID: provider.id, values: values)
            }

            try await appModel.linkConnectionToSelectedAgent(connectionID: created.id)
            inputSheet = nil
            Haptics.success()
            await load()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func completeOAuthCallback(_ callbackURL: URL) async throws {
        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        func value(_ key: String) -> String? {
            queryItems.first(where: { $0.name == key })?.value?.nilIfEmpty
        }

        if value("status") == "error" {
            throw AgentsBackendClientError.message(value("error") ?? "Connection authorization failed.")
        }

        guard let connectionID = value("connectionId") else {
            throw AgentsBackendClientError.message("The connection callback did not include a connection id.")
        }

        try await appModel.linkConnectionToSelectedAgent(connectionID: connectionID)
    }

    private func link(_ connection: AgentConnectionDetails) async {
        busyConnectionID = connection.id
        defer { busyConnectionID = nil }

        do {
            try await appModel.linkConnectionToSelectedAgent(connectionID: connection.id)
            Haptics.success()
            await load()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func unlink(_ connection: AgentConnectionRecord) async {
        busyConnectionID = connection.integrationConnectionId
        defer { busyConnectionID = nil }

        do {
            try await appModel.unlinkConnectionFromSelectedAgent(connectionID: connection.integrationConnectionId)
            Haptics.buttonPress()
            await load()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func delete(target: ConnectionDeleteTarget) async {
        pendingDeleteTarget = nil
        busyConnectionID = target.connectionID
        defer { busyConnectionID = nil }

        do {
            try await appModel.deleteConnection(connectionID: target.connectionID)
            Haptics.buttonPress()
            await load()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func load() async {
        guard appModel.isSignedIn, appModel.selectedAgent != nil else {
            agentConnections = []
            userConnections = []
            catalog = nil
            error = nil
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            async let agentConnectionsTask = appModel.listAgentConnections()
            async let userConnectionsTask = appModel.listUserConnections()
            async let catalogTask = appModel.listConnectionCatalog()

            agentConnections = try await agentConnectionsTask
            userConnections = try await userConnectionsTask
            catalog = try await catalogTask
            error = nil
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func isCancelledOAuth(_ error: Error) -> Bool {
        if let authError = error as? ASWebAuthenticationSessionError {
            return authError.code == .canceledLogin
        }

        let nsError = error as NSError
        return nsError.domain == ASWebAuthenticationSessionError.errorDomain && nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue
    }

    private func isChannelLike(providerID: String) -> Bool {
        providerID == "telegram" || providerID == "texting"
    }

    private func symbolName(for providerID: String) -> String {
        switch providerID {
        case "gmail":
            return "envelope.fill"
        case "google", "google-calendar":
            return "calendar"
        case "google-drive":
            return "externaldrive.fill"
        case "notion":
            return "square.text.square"
        case "slack":
            return "bubble.left.and.bubble.right.fill"
        case "telegram":
            return "paperplane.fill"
        case "texting":
            return "message.fill"
        case "github":
            return "chevron.left.forwardslash.chevron.right"
        case "linear":
            return "line.3.horizontal.decrease.circle"
        default:
            return "link"
        }
    }
}

private struct ConnectionCategoryTab: Identifiable, Hashable {
    let id: String
    let label: String
}

private func defaultCategoryLabel(for categoryID: String) -> String {
    switch categoryID {
    case "communication":
        return "Communication"
    case "google":
        return "Google"
    case "microsoft":
        return "Microsoft"
    case "knowledge":
        return "Knowledge"
    case "engineering", "developer":
        return "Engineering"
    case "productivity":
        return "Productivity"
    case "data":
        return "Data"
    case "finance":
        return "Finance"
    case "social":
        return "Social"
    case "sales":
        return "Sales"
    default:
        return categoryID.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

private enum ConnectionDeleteTarget: Identifiable {
    case linked(AgentConnectionRecord)

    var id: String {
        switch self {
        case .linked(let record):
            return "linked-\(record.integrationConnectionId)"
        }
    }

    var connectionID: String {
        switch self {
        case .linked(let record):
            return record.integrationConnectionId
        }
    }

    var message: String {
        switch self {
        case .linked(let record):
            return "Delete \(record.providerDisplayTitle) completely from your account? This also removes it from any agent using it."
        }
    }
}

private enum ConnectionInputSheet: Identifiable {
    case apiKey(integration: RunnerConnectionIntegration, provider: RunnerConnectionProvider)
    case manual(integration: RunnerConnectionIntegration, provider: RunnerConnectionProvider)

    var id: String {
        switch self {
        case .apiKey(let integration, _):
            return "api-\(integration.id)"
        case .manual(let integration, _):
            return "manual-\(integration.id)"
        }
    }

    var integration: RunnerConnectionIntegration {
        switch self {
        case .apiKey(let integration, _), .manual(let integration, _):
            return integration
        }
    }

    var provider: RunnerConnectionProvider {
        switch self {
        case .apiKey(_, let provider), .manual(_, let provider):
            return provider
        }
    }
}

private struct ConnectionInputSheetView: View {
    @Environment(\.dismiss) private var dismiss

    let sheet: ConnectionInputSheet
    let isSubmitting: Bool
    let onSubmit: ([String: String]) async -> Void

    @State private var values: [String: String] = [:]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sheet.integration.name)
                            .font(RunnerTypography.sans(18, weight: .semibold))
                            .foregroundStyle(RunnerTheme.primaryText)

                        Text(sheet.provider.displayName)
                            .font(RunnerTypography.sans(13, weight: .medium))
                            .foregroundStyle(RunnerTheme.secondaryText)
                    }
                    .listRowBackground(Color.clear)
                }

                switch sheet {
                case .apiKey:
                    apiKeySection
                case .manual:
                    manualSection
                }
            }
            .scrollContentBackground(.hidden)
            .background(RunnerTheme.background.ignoresSafeArea())
            .navigationTitle("Add Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                            .tint(RunnerTheme.primaryText)
                    } else {
                        Button("Save") {
                            Task {
                                await onSubmit(values)
                            }
                        }
                        .disabled(!isValid)
                    }
                }
            }
        }
    }

    private var apiKeySection: some View {
        Section {
            let config = sheet.provider.apiKeyConfig

            SecureField(config?.inputLabel ?? "API Key", text: tokenBinding)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if let placeholder = config?.placeholder?.nilIfEmpty {
                Text(placeholder)
                    .font(RunnerTypography.sans(12.5, weight: .medium))
                    .foregroundStyle(RunnerTheme.secondaryText)
            }

            if let helpURLString = config?.helpUrl, let helpURL = URL(string: helpURLString) {
                Link(destination: helpURL) {
                    Text("Open provider setup guide")
                }
            }
        }
    }

    private var manualSection: some View {
        Section {
            ForEach(sheet.provider.manualConfig?.fields ?? [], id: \.key) { field in
                TextField(
                    field.label,
                    text: binding(for: field.key),
                    prompt: field.placeholder.flatMap(Text.init)
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(field.inputType == "tel" ? .phonePad : .default)
            }
        }
    }

    private var tokenBinding: Binding<String> {
        binding(for: "token")
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { values[key, default: ""] },
            set: { values[key] = $0 }
        )
    }

    private var isValid: Bool {
        switch sheet {
        case .apiKey:
            return !(values["token"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        case .manual:
            let fields = sheet.provider.manualConfig?.fields ?? []
            return !fields.isEmpty && fields.allSatisfy { field in
                !(values[field.key]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            }
        }
    }
}

private extension AgentConnectionRecord {
    var isChannelLike: Bool {
        provider == "telegram" || provider == "texting"
    }

    var providerDisplayTitle: String {
        switch provider {
        case "texting":
            return "Texting"
        case "telegram":
            return "Telegram"
        default:
            return providerDisplayName
        }
    }

    var subtitle: String? {
        if provider == "texting" {
            return texting?.destinationE164 ?? connection.label ?? connection.accountEmail
        }

        return connection.accountEmail ?? connection.label ?? connection.scopes
    }

    var statusLabel: String {
        if provider == "texting" {
            if let status = texting?.status?.nilIfEmpty {
                return status.replacingOccurrences(of: "_", with: " ").capitalized
            }
            return "Linked"
        }

        if connection.refreshExhausted == true {
            return "Needs refresh"
        }

        if connection.isActive == false {
            return "Inactive"
        }

        return "Linked"
    }

    var statusColor: Color {
        if provider == "texting", let status = texting?.status?.uppercased() {
            switch status {
            case "ACTIVE", "ENROLLED":
                return RunnerTheme.accent
            case "PENDING_DEPLOYMENT", "PENDING":
                return RunnerTheme.statusWarning
            default:
                return RunnerTheme.statusError
            }
        }

        if connection.refreshExhausted == true || connection.isActive == false {
            return RunnerTheme.statusWarning
        }

        return RunnerTheme.secondaryText
    }

    var symbolName: String {
        switch provider {
        case "gmail":
            return "envelope.fill"
        case "google-calendar":
            return "calendar"
        case "google-drive":
            return "externaldrive.fill"
        case "notion":
            return "square.text.square"
        case "slack":
            return "bubble.left.and.bubble.right.fill"
        case "telegram":
            return "paperplane.fill"
        case "texting":
            return "message.fill"
        default:
            return "link"
        }
    }
}

private extension AgentConnectionDetails {
    var providerDisplayTitle: String {
        provider.replacingOccurrences(of: "-", with: " ").capitalized
    }

    var connectionSubtitle: String? {
        accountEmail ?? label ?? scopes
    }

    var connectionStatusLabel: String {
        if refreshExhausted == true {
            return "Needs refresh"
        }

        if isActive == false {
            return "Inactive"
        }

        return "Ready"
    }

    var connectionStatusColor: Color {
        if refreshExhausted == true || isActive == false {
            return RunnerTheme.statusWarning
        }

        return RunnerTheme.secondaryText
    }
}
