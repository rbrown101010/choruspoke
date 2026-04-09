import Foundation

struct RunnerResolvedConnection {
    let runtimeConfig: RunnerConnectionConfig
    let persistedConfig: RunnerConnectionConfig
    let source: Source

    enum Source {
        case sandboxAgent
    }
}

struct RunnerLaunchDescriptor {
    let baseURL: String
    let bootstrapToken: String
}

enum RunnerLaunchError: LocalizedError {
    case invalidURL
    case missingBootstrapToken

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The sandbox runner URL is invalid."
        case .missingBootstrapToken:
            return "The sandbox runner URL is missing its bootstrap token."
        }
    }
}

struct RunnerLaunchParser {
    static func parse(urlString: String) throws -> RunnerLaunchDescriptor {
        guard let url = URL(string: urlString) else {
            throw RunnerLaunchError.invalidURL
        }

        let baseURL = url.removingFragmentAndQueryString()
        guard !baseURL.isEmpty else {
            throw RunnerLaunchError.invalidURL
        }

        let fragmentItems = URLComponents(string: "https://runner.invalid/?\(url.fragment ?? "")")?.queryItems
        guard let bootstrapToken = fragmentItems?.first(where: { $0.name == "bootstrap_token" })?.value?.nilIfEmpty else {
            throw RunnerLaunchError.missingBootstrapToken
        }

        return RunnerLaunchDescriptor(baseURL: baseURL, bootstrapToken: bootstrapToken)
    }
}

struct RunnerAuthResolver {
    func resolve(urlString: String) async throws -> RunnerResolvedConnection {
        let descriptor = try RunnerLaunchParser.parse(urlString: urlString)
        let exchangeClient = RunnerAPIClient(config: RunnerConnectionConfig(
            baseURL: descriptor.baseURL,
            token: "",
            lastConnectedAt: nil
        ))
        let exchange = try await exchangeClient.exchangeBootstrapToken(descriptor.bootstrapToken)

        let runtimeConfig = RunnerConnectionConfig(
            baseURL: descriptor.baseURL,
            token: exchange.token,
            lastConnectedAt: Date()
        )

        let persistedConfig = RunnerConnectionConfig(
            baseURL: descriptor.baseURL,
            token: "",
            lastConnectedAt: runtimeConfig.lastConnectedAt
        )

        return RunnerResolvedConnection(
            runtimeConfig: runtimeConfig,
            persistedConfig: persistedConfig,
            source: .sandboxAgent
        )
    }
}

private extension URL {
    func removingFragmentAndQueryString() -> String {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return absoluteString
        }

        components.fragment = nil
        components.query = nil
        components.path = components.path.isEmpty ? "/" : components.path
        return components.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? absoluteString
    }
}
