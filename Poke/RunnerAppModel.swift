import AuthenticationServices
import Clerk
import Combine
import Foundation
import OSLog

@MainActor
final class RunnerAppModel: ObservableObject {
    private let logger = Logger(subsystem: "com.poke.app", category: "RunnerAppModel")

    @Published var config: RunnerConnectionConfig
    @Published var connectionStatus: RunnerConnectionStatus = .idle
    @Published var bootstrap: RunnerBootstrap?
    @Published var authState: ChorusAuthState = .loading
    @Published var authenticatedUser: ChorusAuthenticatedUser?
    @Published var agents: [SandboxAgent] = []
    @Published var selectedAgentID: String?
    @Published var authMessage: String?
    @Published var agentsLoadError: String?

    private let store = RunnerSelectionStore()
    private let authResolver = RunnerAuthResolver()
    private let agentsClient = AgentsBackendClient()
    private(set) var client: RunnerAPIClient?

    private var didBootstrap = false
    private var didConfigureClerk = false
    private var connectionRevision = 0

    init() {
        let persisted = store.load()
        self.selectedAgentID = persisted.selectedAgentID
        self.config = persisted.lastConnection ?? .empty
    }

    func bootstrapApp() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        await restoreSession()
    }

    func restoreSession() async {
        authMessage = nil
        agentsLoadError = nil

        do {
            try await configureClerkIfNeeded()

            if let user = Clerk.shared.user, Clerk.shared.session != nil {
                await applyAuthenticatedState(for: user)
            } else {
                clearAuthenticationState()
                authState = .signedOut
            }
        } catch {
            clearAuthenticationState()
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            authMessage = message
            authState = .failed(message)
        }
    }

    func signInWithGoogle() async {
        authMessage = nil
        authState = .loading

        do {
            try await configureClerkIfNeeded()
            _ = try await SignIn.authenticateWithRedirect(
                strategy: .oauth(provider: .google, redirectUrl: ChorusEnvironment.clerkRedirectURL)
            )
            try await Clerk.shared.load()

            guard let user = Clerk.shared.user else {
                throw AgentsBackendClientError.message("Clerk didn’t restore a user session after Google sign-in.")
            }

            Haptics.success()
            await applyAuthenticatedState(for: user)
        } catch {
            clearAuthenticationState()
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            authMessage = message
            authState = .signedOut
        }
    }

    func signInWithApple() async {
        authMessage = nil
        authState = .loading

        do {
            try await configureClerkIfNeeded()
            let credential = try await SignInWithAppleHelper.getAppleIdCredential()
            guard let idToken = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) }) else {
                throw AgentsBackendClientError.message("Apple didn’t return a usable identity token.")
            }

            _ = try await SignIn.authenticateWithIdToken(provider: .apple, idToken: idToken)
            try await Clerk.shared.load()

            guard let user = Clerk.shared.user else {
                throw AgentsBackendClientError.message("Clerk didn’t restore a user session after Apple sign-in.")
            }

            Haptics.success()
            await applyAuthenticatedState(for: user)
        } catch {
            clearAuthenticationState()
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            authMessage = message
            authState = .signedOut
        }
    }

    func signOut() async {
        do {
            try await configureClerkIfNeeded()
            try await Clerk.shared.signOut()
        } catch {
            authMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        clearAuthenticationState()
        authState = .signedOut
    }

    func refreshAgents() async {
        guard authState.isSignedIn else { return }

        do {
            let listed = try await fetchAgentsWithRetry()
            let sorted = listed.sorted(by: Self.isPreferredAgent)

            agents = sorted
            agentsLoadError = nil
            normalizeSelectedAgent()
            persistSelection()
            logger.info("Loaded \(sorted.count) sandbox agents")
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            agentsLoadError = message
            logger.error("Failed to load agents: \(message, privacy: .public)")
            if agents.isEmpty {
                selectedAgentID = nil
                clearRunnerConnection()
                connectionStatus = .failed(message)
            }
        }
    }

    func refreshAgentsAndReconnect() async {
        await refreshAgents()
        await reconnectToSelectedAgent()
    }

    func selectAgent(_ agent: SandboxAgent) async {
        if selectedAgentID == agent.id {
            await reconnectToSelectedAgent()
            return
        }

        Haptics.selection()
        selectedAgentID = agent.id
        persistSelection()
        await reconnectToSelectedAgent()
    }

    func listAgentConnections() async throws -> [AgentConnectionRecord] {
        guard let selectedAgent else { return [] }
        let token = try await currentClerkToken()
        return try await agentsClient.listAgentConnections(agentID: selectedAgent.id, clerkJWT: token)
    }

    func listUserConnections() async throws -> [AgentConnectionDetails] {
        let token = try await currentClerkToken()
        return try await agentsClient.listUserConnections(clerkJWT: token)
    }

    func listConnectionCatalog() async throws -> RunnerConnectionCatalogResponse {
        let token = try await currentClerkToken()
        return try await agentsClient.listConnectionCatalog(clerkJWT: token)
    }

    func authorizeConnection(providerID: String, redirectTo: String, scopes: [String]? = nil) async throws -> URL {
        let token = try await currentClerkToken()
        let response = try await agentsClient.authorizeConnection(
            providerID: providerID,
            redirectTo: redirectTo,
            scopes: scopes,
            clerkJWT: token
        )

        guard let url = URL(string: response.authUrl) else {
            throw AgentsBackendClientError.message("The connection authorization URL was invalid.")
        }

        return url
    }

    func createAPIKeyConnection(providerID: String, tokenValue: String) async throws -> AgentConnectionDetails {
        let token = try await currentClerkToken()
        return try await agentsClient.createAPIKeyConnection(
            providerID: providerID,
            token: tokenValue,
            clerkJWT: token
        )
    }

    func createManualConnection(providerID: String, values: [String: String]) async throws -> AgentConnectionDetails {
        let token = try await currentClerkToken()
        return try await agentsClient.createManualConnection(
            providerID: providerID,
            values: values,
            clerkJWT: token
        )
    }

    func linkConnectionToSelectedAgent(connectionID: String) async throws {
        guard let selectedAgent else {
            throw AgentsBackendClientError.message("Select an agent before linking a connection.")
        }

        let token = try await currentClerkToken()
        try await agentsClient.linkConnection(
            agentID: selectedAgent.id,
            integrationConnectionID: connectionID,
            clerkJWT: token
        )
    }

    func unlinkConnectionFromSelectedAgent(connectionID: String) async throws {
        guard let selectedAgent else {
            throw AgentsBackendClientError.message("Select an agent before unlinking a connection.")
        }

        let token = try await currentClerkToken()
        try await agentsClient.unlinkConnection(
            agentID: selectedAgent.id,
            integrationConnectionID: connectionID,
            clerkJWT: token
        )
    }

    func deleteConnection(connectionID: String) async throws {
        let token = try await currentClerkToken()
        try await agentsClient.deleteConnection(connectionID: connectionID, clerkJWT: token)
    }

    func createAgent(name: String? = nil, description: String? = nil, instructions: String? = nil) async throws -> SandboxAgent {
        let token = try await currentClerkToken()
        let created = try await agentsClient.createAgent(
            clerkJWT: token,
            name: name,
            description: description,
            instructions: instructions
        )
        await refreshAgents()

        let resolved = agents.first(where: { $0.id == created.id }) ?? created
        selectedAgentID = resolved.id
        persistSelection()

        if resolved.isRunnable {
            await reconnectToSelectedAgent()
        } else {
            clearRunnerConnection()
            connectionStatus = .idle
        }

        return resolved
    }

    var isSignedIn: Bool {
        authState.isSignedIn
    }

    var selectedAgent: SandboxAgent? {
        agents.first(where: { $0.id == selectedAgentID })
    }

    var selectorTitle: String {
        if let selectedAgent {
            return selectedAgent.name
        }

        if isSignedIn, let agentsLoadError, agents.isEmpty, !agentsLoadError.isEmpty {
            return "Retry Agents"
        }

        return isSignedIn ? "Select Agent" : "Sign In"
    }

    var agentTitle: String {
        selectedAgent?.name ?? "Runner Agent"
    }

    var agentStatusLine: String {
        if !isSignedIn {
            return "Sign in to load your agents"
        }

        if let agentsLoadError, agents.isEmpty {
            return "Couldn’t load agents"
        }

        guard let selectedAgent else {
            return agents.isEmpty ? "No agents on this account" : "Choose an agent"
        }

        switch connectionStatus {
        case .connected:
            return "Connected to sandbox"
        case .connecting:
            return "Connecting to sandbox"
        case .failed:
            if selectedAgent.status.uppercased() == "AWAITING_READINESS" {
                return "Agent is still preparing"
            }
            return "Unable to reach this agent"
        case .idle:
            return selectedAgent.statusLabel
        }
    }

    var agentSubtitle: String {
        if !isSignedIn {
            return "Authenticate with Chorus to load your sandbox agents"
        }

        if let agentsLoadError, agents.isEmpty {
            return agentsLoadError
        }

        if let selectedAgent {
            return selectedAgent.detailLine
        }

        return authenticatedUser?.emailAddress ?? "Your chorus.com agent"
    }

    var currentRunnerHostLabel: String {
        config.hostLabel
    }

    var backendHostLabel: String {
        URL(string: ChorusEnvironment.agentsBackendBaseURL)?.host ?? ChorusEnvironment.agentsBackendBaseURL
    }

    private func applyAuthenticatedState(for user: User) async {
        authenticatedUser = ChorusAuthenticatedUser(from: user)
        authState = .signedIn
        await refreshAgentsAndReconnect()
    }

    private func reconnectToSelectedAgent() async {
        guard authState.isSignedIn else {
            clearRunnerConnection()
            connectionStatus = .idle
            return
        }

        guard let selectedAgent else {
            clearRunnerConnection()
            connectionStatus = agents.isEmpty ? .idle : .failed("Select an agent to continue.")
            return
        }

        connectionRevision += 1
        let revision = connectionRevision
        connectionStatus = .connecting

        do {
            let token = try await currentClerkToken()
            let iframe = try await agentsClient.runnerIframeURL(agentID: selectedAgent.id, clerkJWT: token)
            let resolved = try await authResolver.resolve(urlString: iframe.url)
            let bootstrapClient = RunnerAPIClient(config: resolved.runtimeConfig)
            let bootstrapped = try await bootstrapClient.bootstrap()

            guard revision == connectionRevision else { return }

            client = bootstrapClient
            bootstrap = bootstrapped
            config = resolved.persistedConfig
            connectionStatus = .connected
            persistSelection()
        } catch {
            guard revision == connectionRevision else { return }

            clearRunnerConnection()
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            connectionStatus = .failed(message)
        }
    }

    private func configureClerkIfNeeded() async throws {
        if !didConfigureClerk {
            Clerk.shared.configure(
                publishableKey: ChorusEnvironment.clerkPublishableKey,
                settings: Clerk.Settings(
                    redirectConfig: RedirectConfig(
                        redirectUrl: ChorusEnvironment.clerkRedirectURL,
                        callbackUrlScheme: ChorusEnvironment.clerkCallbackScheme
                    )
                )
            )
            didConfigureClerk = true
        }

        if !Clerk.shared.isLoaded {
            try await Clerk.shared.load()
        }
    }

    private func currentClerkToken(forceRefresh: Bool = false) async throws -> String {
        try await configureClerkIfNeeded()

        guard let session = Clerk.shared.session else {
            throw AgentsBackendClientError.message("No active Clerk session was found.")
        }

        let options = Session.GetTokenOptions(skipCache: forceRefresh)

        guard let token = try await session.getToken(options)?.jwt.nilIfEmpty else {
            throw AgentsBackendClientError.message("Clerk did not return an access token.")
        }

        return token
    }

    private func fetchAgentsWithRetry() async throws -> [SandboxAgent] {
        var lastError: Error?

        for attempt in 0..<4 {
            do {
                let token = try await stableClerkToken(attempt: attempt)
                let listed = try await agentsClient.listAgents(clerkJWT: token)
                return listed
            } catch {
                lastError = error
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                logger.error("Agent fetch attempt \(attempt + 1) failed: \(message, privacy: .public)")
                if attempt < 3 {
                    try? await Task.sleep(for: .milliseconds(250 * (attempt + 1)))
                }
            }
        }

        throw lastError ?? AgentsBackendClientError.message("Unable to load agents.")
    }

    private func stableClerkToken(attempt: Int) async throws -> String {
        let forceRefresh = attempt > 0

        do {
            return try await currentClerkToken(forceRefresh: forceRefresh)
        } catch {
            if forceRefresh {
                try await configureClerkIfNeeded()
            }
            throw error
        }
    }

    private func clearAuthenticationState() {
        authenticatedUser = nil
        agents = []
        selectedAgentID = nil
        authState = .signedOut
        clearRunnerConnection()
        persistSelection()
    }

    private func clearRunnerConnection() {
        client = nil
        bootstrap = nil
        config = .empty
    }

    private func normalizeSelectedAgent() {
        if let selectedAgentID, agents.contains(where: { $0.id == selectedAgentID }) {
            return
        }

        selectedAgentID = agents.first?.id
    }

    private func persistSelection() {
        store.save(.init(
            selectedAgentID: selectedAgentID,
            lastConnection: config.normalizedBaseURL.isEmpty ? nil : config
        ))
    }

    private static func isPreferredAgent(lhs: SandboxAgent, rhs: SandboxAgent) -> Bool {
        if lhs.isRunnable != rhs.isRunnable {
            return lhs.isRunnable && !rhs.isRunnable
        }

        return lhs.updatedAt > rhs.updatedAt
    }
}

private struct RunnerSelectionPersistence: Codable {
    var selectedAgentID: String?
    var lastConnection: RunnerConnectionConfig?
}

private final class RunnerSelectionStore {
    private let defaults = UserDefaults.standard
    private let key = "chorus.runner.selection.v2"

    func load() -> RunnerSelectionPersistence {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(RunnerSelectionPersistence.self, from: data) else {
            return RunnerSelectionPersistence(selectedAgentID: nil, lastConnection: nil)
        }

        return decoded
    }

    func save(_ selection: RunnerSelectionPersistence) {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        defaults.set(data, forKey: key)
    }
}

private extension ChorusAuthenticatedUser {
    init(from user: User) {
        let firstName = user.firstName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = user.lastName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullName = [firstName, lastName]
            .compactMap { $0?.nilIfEmpty }
            .joined(separator: " ")
            .nilIfEmpty

        self.init(
            id: user.id,
            displayName: fullName ?? user.primaryEmailAddress?.emailAddress ?? "Chorus",
            emailAddress: user.primaryEmailAddress?.emailAddress
        )
    }
}
