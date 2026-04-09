import Foundation
import OSLog

enum AgentsBackendClientError: LocalizedError {
    case invalidURL
    case malformedResponse
    case message(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The agents backend URL is invalid."
        case .malformedResponse:
            return "The agents backend returned an unexpected response."
        case .message(let message):
            return message
        }
    }
}

final class AgentsBackendClient {
    private let logger = Logger(subsystem: "com.poke.app", category: "AgentsBackend")
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: String = ChorusEnvironment.agentsBackendBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder.chorusBackend
    }

    func listAgents(clerkJWT: String) async throws -> [SandboxAgent] {
        try await request(
            path: "/api/agents",
            clerkJWT: clerkJWT,
            responseType: [SandboxAgent].self
        )
    }

    func runnerIframeURL(agentID: String, clerkJWT: String) async throws -> AgentRunnerIframeURLResponse {
        try await request(
            path: "/api/agents/\(agentID)/runner-iframe-url",
            method: "POST",
            clerkJWT: clerkJWT,
            responseType: AgentRunnerIframeURLResponse.self
        )
    }

    func listAgentConnections(agentID: String, clerkJWT: String) async throws -> [AgentConnectionRecord] {
        try await request(
            path: "/api/agents/\(agentID)/connections",
            clerkJWT: clerkJWT,
            responseType: [AgentConnectionRecord].self
        )
    }

    func listUserConnections(clerkJWT: String) async throws -> [AgentConnectionDetails] {
        try await request(
            path: "/api/connections",
            clerkJWT: clerkJWT,
            responseType: [AgentConnectionDetails].self
        )
    }

    func listConnectionCatalog(clerkJWT: String) async throws -> RunnerConnectionCatalogResponse {
        try await request(
            path: "/api/connections/providers",
            clerkJWT: clerkJWT,
            responseType: RunnerConnectionCatalogResponse.self
        )
    }

    func authorizeConnection(
        providerID: String,
        redirectTo: String,
        scopes: [String]? = nil,
        clerkJWT: String
    ) async throws -> RunnerConnectionOAuthAuthorizeResponse {
        let payload = ConnectionOAuthAuthorizeRequest(scopes: scopes, redirectTo: redirectTo)
        let body = try JSONEncoder().encode(payload)
        let encodedProvider = encodedPathComponent(providerID)
        return try await request(
            path: "/api/connections/oauth/\(encodedProvider)/authorize",
            method: "POST",
            body: body,
            clerkJWT: clerkJWT,
            responseType: RunnerConnectionOAuthAuthorizeResponse.self
        )
    }

    func createAPIKeyConnection(providerID: String, token: String, clerkJWT: String) async throws -> AgentConnectionDetails {
        let payload = APIKeyConnectionRequest(provider: providerID, token: token)
        let body = try JSONEncoder().encode(payload)
        return try await request(
            path: "/api/connections/api-key",
            method: "POST",
            body: body,
            clerkJWT: clerkJWT,
            responseType: AgentConnectionDetails.self
        )
    }

    func createManualConnection(providerID: String, values: [String: String], clerkJWT: String) async throws -> AgentConnectionDetails {
        let payload = ManualConnectionRequest(provider: providerID, values: values)
        let body = try JSONEncoder().encode(payload)
        return try await request(
            path: "/api/connections/manual",
            method: "POST",
            body: body,
            clerkJWT: clerkJWT,
            responseType: AgentConnectionDetails.self
        )
    }

    func linkConnection(agentID: String, integrationConnectionID: String, clerkJWT: String) async throws {
        let payload = LinkConnectionRequest(integrationConnectionId: integrationConnectionID)
        let body = try JSONEncoder().encode(payload)
        _ = try await request(
            path: "/api/agents/\(encodedPathComponent(agentID))/connections",
            method: "POST",
            body: body,
            clerkJWT: clerkJWT,
            responseType: EmptyResponse.self
        )
    }

    func unlinkConnection(agentID: String, integrationConnectionID: String, clerkJWT: String) async throws {
        _ = try await request(
            path: "/api/agents/\(encodedPathComponent(agentID))/connections/\(encodedPathComponent(integrationConnectionID))",
            method: "DELETE",
            clerkJWT: clerkJWT,
            responseType: RunnerConnectionMutationResponse.self
        )
    }

    func deleteConnection(connectionID: String, clerkJWT: String) async throws {
        _ = try await request(
            path: "/api/connections/\(encodedPathComponent(connectionID))",
            method: "DELETE",
            clerkJWT: clerkJWT,
            responseType: RunnerConnectionMutationResponse.self
        )
    }

    func createAgent(
        clerkJWT: String,
        name: String? = nil,
        description: String? = nil,
        instructions: String? = nil
    ) async throws -> SandboxAgent {
        let payload = CreateAgentRequest(
            name: name,
            description: description,
            instructions: instructions
        )
        let body = try JSONEncoder().encode(payload)
        return try await request(
            path: "/api/agents",
            method: "POST",
            body: body,
            clerkJWT: clerkJWT,
            responseType: SandboxAgent.self
        )
    }

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        clerkJWT: String,
        responseType: T.Type
    ) async throws -> T {
        let url = try buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(clerkJWT)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AgentsBackendClientError.malformedResponse
        }

        logger.info("Agents backend \(method, privacy: .public) \(path, privacy: .public) -> \(http.statusCode)")

        if !(200...299).contains(http.statusCode) {
            let responseText = String(data: data, encoding: .utf8) ?? ""
            logger.error("Agents backend failure \(method, privacy: .public) \(path, privacy: .public): \(responseText, privacy: .public)")
            if let nested = try? decoder.decode(AgentsBackendNestedErrorEnvelope.self, from: data),
               let message = nested.error?.message.nilIfEmpty {
                throw AgentsBackendClientError.message(message)
            }

            if let flat = try? decoder.decode(AgentsBackendFlatErrorEnvelope.self, from: data) {
                if let message = flat.message?.nilIfEmpty {
                    throw AgentsBackendClientError.message(message)
                }
                if let message = flat.error?.nilIfEmpty {
                    throw AgentsBackendClientError.message(message)
                }
            }

            let message = String(data: data, encoding: .utf8)?.nilIfEmpty ?? "Agents backend request failed."
            throw AgentsBackendClientError.message(message)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("Agents backend decode failure \(method, privacy: .public) \(path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw AgentsBackendClientError.malformedResponse
        }
    }

    private func buildURL(path: String) throws -> URL {
        guard var components = URLComponents(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AgentsBackendClientError.invalidURL
        }

        let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
        components.path = cleanPath

        guard let url = components.url else {
            throw AgentsBackendClientError.invalidURL
        }

        return url
    }

    private func encodedPathComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }
}

private struct CreateAgentRequest: Encodable {
    let name: String?
    let description: String?
    let instructions: String?
}

private struct ConnectionOAuthAuthorizeRequest: Encodable {
    let scopes: [String]?
    let redirectTo: String
}

private struct APIKeyConnectionRequest: Encodable {
    let provider: String
    let token: String
}

private struct ManualConnectionRequest: Encodable {
    let provider: String
    let values: [String: String]
}

private struct LinkConnectionRequest: Encodable {
    let integrationConnectionId: String
}

private struct EmptyResponse: Decodable {}

private struct AgentsBackendNestedErrorEnvelope: Decodable {
    let error: AgentsBackendNestedErrorPayload?
}

private struct AgentsBackendNestedErrorPayload: Decodable {
    let message: String
}

private struct AgentsBackendFlatErrorEnvelope: Decodable {
    let error: String?
    let message: String?
}

private extension JSONDecoder {
    static var chorusBackend: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .chorusISO8601
        return decoder
    }
}

private extension JSONDecoder.DateDecodingStrategy {
    static let chorusISO8601 = custom { decoder in
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(Double.self) {
            return Date(timeIntervalSince1970: value)
        }

        if let value = try? container.decode(Int.self) {
            return Date(timeIntervalSince1970: TimeInterval(value))
        }

        let text = try container.decode(String.self)

        if let date = ChorusDateDecoders.fractional.date(from: text) ?? ChorusDateDecoders.standard.date(from: text) {
            return date
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Expected a Chorus ISO8601 date string."
        )
    }
}

private enum ChorusDateDecoders {
    static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
