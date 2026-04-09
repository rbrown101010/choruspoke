import Foundation

struct RunnerResolvedConnection {
    let runtimeConfig: RunnerConnectionConfig
    let persistedConfig: RunnerConnectionConfig
    let source: Source

    enum Source {
        case manualToken
        case localDevToken
    }
}

protocol RunnerAuthResolving {
    func resolve(config: RunnerConnectionConfig) async throws -> RunnerResolvedConnection
}

struct RunnerAuthResolver: RunnerAuthResolving {
    func resolve(config: RunnerConnectionConfig) async throws -> RunnerResolvedConnection {
        if !config.normalizedToken.isEmpty {
            return RunnerResolvedConnection(
                runtimeConfig: config,
                persistedConfig: config,
                source: .manualToken
            )
        }

        let client = RunnerAPIClient(config: config)
        let devToken = try await client.fetchDevToken()

        var runtimeConfig = config
        runtimeConfig.token = devToken.token

        return RunnerResolvedConnection(
            runtimeConfig: runtimeConfig,
            persistedConfig: config,
            source: .localDevToken
        )
    }
}

