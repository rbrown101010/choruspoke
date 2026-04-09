import Combine
import Foundation

@MainActor
final class RunnerAppModel: ObservableObject {
    @Published var config: RunnerConnectionConfig
    @Published var connectionStatus: RunnerConnectionStatus = .idle
    @Published var bootstrap: RunnerBootstrap?

    private let store = RunnerConnectionStore()
    private let authResolver: RunnerAuthResolving
    private(set) var client: RunnerAPIClient?

    init() {
        self.authResolver = RunnerAuthResolver()
        self.config = store.load() ?? .defaultLocal
    }

    init(authResolver: RunnerAuthResolving) {
        self.authResolver = authResolver
        self.config = store.load() ?? .defaultLocal
    }

    func bootstrapApp() async {
        await connect()
    }

    func connect(using override: RunnerConnectionConfig? = nil) async {
        let nextConfig = override ?? config
        config = nextConfig
        connectionStatus = .connecting

        do {
            let resolved = try await authResolver.resolve(config: nextConfig)
            let bootstrapClient = RunnerAPIClient(config: resolved.runtimeConfig)

            let bootstrap = try await bootstrapClient.bootstrap()

            var persisted = resolved.persistedConfig
            persisted.lastConnectedAt = Date()

            client = RunnerAPIClient(config: resolved.runtimeConfig)
            config = persisted
            self.bootstrap = bootstrap
            connectionStatus = .connected
            store.save(persisted)
        } catch {
            client = nil
            bootstrap = nil
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            connectionStatus = .failed(message)
        }
    }

    func updateConnection(baseURL: String, token: String) async {
        await connect(using: RunnerConnectionConfig(
            baseURL: baseURL,
            token: token,
            lastConnectedAt: config.lastConnectedAt
        ))
    }

    func fetchDevToken(for baseURL: String) async throws -> String {
        let temp = RunnerAPIClient(config: RunnerConnectionConfig(baseURL: baseURL, token: "", lastConnectedAt: nil))
        return try await temp.fetchDevToken().token
    }

    var agentTitle: String {
        "Runner Agent"
    }

    var agentStatusLine: String {
        switch connectionStatus {
        case .connected:
            return "Connected locally"
        case .connecting:
            return "Connecting locally"
        case .failed:
            return "Point this app at runner"
        case .idle:
            return "Waiting for runner"
        }
    }

    var agentSubtitle: String {
        "Your chorus.com agent"
    }
}

final class RunnerConnectionStore {
    private let defaults = UserDefaults.standard
    private let key = "chorus.runner.connection.v1"

    func load() -> RunnerConnectionConfig? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(RunnerConnectionConfig.self, from: data)
    }

    func save(_ config: RunnerConnectionConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: key)
    }
}
