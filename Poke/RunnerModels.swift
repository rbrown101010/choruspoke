import Foundation

struct RunnerEnvelope<T: Decodable>: Decodable {
    let data: T
}

struct RunnerErrorEnvelope: Decodable {
    let error: RunnerErrorPayload
}

struct RunnerErrorPayload: Decodable {
    let message: String
    let code: String
    let field: String?
}

enum RunnerClientError: LocalizedError {
    case invalidURL
    case malformedResponse
    case message(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The runner URL is invalid."
        case .malformedResponse:
            return "Runner returned an unexpected response."
        case .message(let message):
            return message
        }
    }
}

struct RunnerConnectionConfig: Codable, Equatable {
    var baseURL: String
    var token: String
    var lastConnectedAt: Date?

    static let empty = RunnerConnectionConfig(
        baseURL: "",
        token: "",
        lastConnectedAt: nil
    )

    static let defaultLocal = RunnerConnectionConfig(
        baseURL: "http://localhost",
        token: "",
        lastConnectedAt: nil
    )

    var normalizedBaseURL: String {
        var value = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while value.hasSuffix("/") {
            value.removeLast()
        }

        if value.hasSuffix("/api") {
            value = String(value.dropLast(4))
        }

        return value
    }

    var normalizedToken: String {
        token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hostLabel: String {
        guard !normalizedBaseURL.isEmpty else {
            return "No runner selected"
        }

        guard let url = URL(string: normalizedBaseURL) else {
            return normalizedBaseURL
        }

        if let host = url.host, let port = url.port {
            return "\(host):\(port)"
        }

        return url.host ?? normalizedBaseURL
    }
}

struct RunnerDevTokenResponse: Decodable {
    let token: String
    let userId: String
    let agentId: String
    let mode: String
}

struct RunnerBootstrap: Decodable {
    let agentId: String
    let deploymentId: String?
    let historySyncLimit: Int?
    let capabilities: RunnerCapabilities
    let agent: RunnerAgentSummary?
}

struct RunnerCapabilities: Decodable {
    let sessions: Bool
    let tools: Bool
}

struct RunnerAgentSummary: Decodable {
    let id: String
    let name: String
}

struct RunnerFileListResponse: Decodable {
    let path: String
    let truncated: Bool
    let entries: [RunnerFileEntry]
}

struct RunnerFileEntry: Decodable, Identifiable, Hashable {
    let name: String
    let path: String
    let isDir: Bool
    let size: Int
    let modTimeMs: Double
    let fileExtension: String?

    enum CodingKeys: String, CodingKey {
        case name
        case path
        case isDir
        case size
        case modTimeMs
        case fileExtension = "extension"
    }

    var id: String { path }

    var isMarkdown: Bool {
        [".md", ".mdx"].contains((fileExtension ?? "").lowercased())
    }
}

struct RunnerFileContent: Decodable {
    let path: String
    let name: String
    let isBinary: Bool
    let mimeType: String
    let content: String
    let contentBase64: String?
}

struct RunnerSkillsResponse: Decodable {
    let workspaceDir: String
    let managedSkillsDir: String
    let skills: [RunnerSkill]
}

struct RunnerSkill: Decodable, Identifiable, Hashable {
    let name: String
    let displayName: String?
    let description: String
    let source: String
    let bundled: Bool
    let filePath: String
    let baseDir: String
    let skillKey: String
    let primaryEnv: String?
    let emoji: String?
    let hasIcon: Bool?
    let homepage: String?
    let always: Bool
    let disabled: Bool
    let blockedByAllowlist: Bool
    let eligible: Bool
    let setup: RunnerSkillSetup

    var id: String { skillKey }

    var title: String {
        displayName ?? name
    }
}

struct RunnerSkillSetup: Decodable, Hashable {
    let ready: Bool
    let needsAttention: Bool
    let requirements: [RunnerSkillRequirement]
}

struct RunnerSkillRequirement: Decodable, Hashable {
    let kind: String
    let id: String
    let label: String
    let status: String
    let action: String
}

struct RunnerSkillContentResponse: Decodable {
    let name: String
    let content: String
}

struct RunnerMarketplaceBrowseResponse: Decodable {
    let items: [RunnerMarketplaceSkill]
    let nextCursor: String?
}

struct RunnerMarketplaceSkill: Decodable, Identifiable, Hashable {
    let slug: String
    let displayName: String
    let summary: String
    let source: String
    let latestVersion: String?
    let dependencies: [String]?
    let hasIcon: Bool?

    var id: String { "\(source):\(slug)" }

    var sourceDisplayName: String {
        source == "chorus" ? "Chorus" : source.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

struct RunnerMarketplaceSkillDetail: Decodable {
    let slug: String
    let displayName: String
    let summary: String
    let source: String
    let moderation: String?
    let owner: String?
    let latestVersion: String?

    var sourceDisplayName: String {
        source == "chorus" ? "Chorus" : source.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

struct RunnerMarketplaceSkillFileResponse: Decodable {
    let slug: String
    let path: String
    let content: String
}

struct RunnerMarketplaceInstallResult: Decodable {
    let slug: String
    let version: String?
    let source: String
    let installedSkillKey: String?
    let installedDeps: [String]
    let setup: RunnerSkillSetup?
    let nextAction: RunnerMarketplaceNextAction?
    let verification: String?
}

struct RunnerMarketplaceNextAction: Decodable {
    let type: String?
    let providerIds: [String]?
    let actionId: String?
    let url: String?
}

struct RunnerCronJobsResponse: Decodable {
    let jobs: [RunnerCronJob]
    let total: Int
    let offset: Int
    let limit: Int
    let hasMore: Bool
    let nextOffset: Int?
}

struct RunnerCronJob: Decodable, Identifiable, Hashable {
    let id: String
    let agentId: String?
    let sessionKey: String?
    let name: String?
    let enabled: Bool
    let createdAtMs: Double?
    let updatedAtMs: Double?
    let schedule: RunnerCronSchedule
    let payload: RunnerCronPayload?
    let state: RunnerCronState?
}

struct RunnerCronSchedule: Decodable, Hashable {
    let kind: String
    let expr: String?
    let tz: String?
    let everyMs: Double?
    let at: String?
}

struct RunnerCronPayload: Decodable, Hashable {
    let kind: String
    let message: String?
}

struct RunnerCronState: Decodable, Hashable {
    let nextRunAtMs: Double?
    let lastRunAtMs: Double?
    let lastRunStatus: String?
    let lastStatus: String?
    let lastDurationMs: Double?
    let lastDeliveryStatus: String?
    let consecutiveErrors: Int?
    let lastError: String?
}

enum RunnerConnectionStatus: Equatable {
    case idle
    case connecting
    case connected
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            return "Not connected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .failed:
            return "Offline"
        }
    }

    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .failed(let message) = self {
            return message
        }
        return nil
    }
}

struct SandboxAgent: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let instructions: String?
    let status: String
    let previewUrl: String?
    let masterclawUrl: String?
    let createdAt: Date
    let updatedAt: Date

    var statusLabel: String {
        switch status.uppercased() {
        case "ACTIVE":
            return "Ready"
        case "AWAITING_READINESS":
            return "Preparing"
        case "FAILED":
            return "Needs attention"
        case "DELETING":
            return "Deleting"
        default:
            return status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var isRunnable: Bool {
        let value = status.uppercased()
        return value == "ACTIVE" || value == "AWAITING_READINESS"
    }

    var detailLine: String {
        if let description, !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return description
        }

        return "Your chorus.com agent"
    }
}

struct AgentRunnerIframeURLResponse: Decodable {
    let url: String
    let expiresAt: Date?
}

struct RunnerBootstrapExchangeResponse: Decodable {
    let token: String
    let userId: String
    let agentId: String
    let expiresAt: Date
}

struct ChorusAuthenticatedUser: Equatable {
    let id: String
    let displayName: String
    let emailAddress: String?
}

enum ChorusAuthState: Equatable {
    case loading
    case signedOut
    case signedIn
    case failed(String)

    var isSignedIn: Bool {
        if case .signedIn = self {
            return true
        }
        return false
    }
}

struct AgentConnectionRecord: Decodable, Identifiable, Hashable {
    let id: String
    let agentId: String
    let integrationConnectionId: String
    let provider: String
    let createdAt: Date?
    let connection: AgentConnectionDetails
    let texting: AgentTextingDetails?
    let coveredIntegrationIds: [String]?

    var providerDisplayName: String {
        provider.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

struct AgentConnectionDetails: Decodable, Hashable {
    let id: String
    let provider: String
    let type: String?
    let accountEmail: String?
    let label: String?
    let source: String?
    let scopes: String?
    let isActive: Bool?
    let refreshExhausted: Bool?
    let createdAt: Date?
    let updatedAt: Date?
}

enum RunnerConnectionAuthType: String, Decodable, Hashable {
    case oauth
    case api_key
    case nango
    case manual
}

struct RunnerConnectionCatalogResponse: Decodable, Hashable {
    let categories: [RunnerConnectionCategory]
    let providers: [RunnerConnectionProvider]
}

struct RunnerConnectionCategory: Decodable, Identifiable, Hashable {
    let id: String
    let label: String
    let integrations: [RunnerConnectionIntegration]
    let sharedProvider: String?
}

struct RunnerConnectionIntegration: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let description: String?
    let providerId: String
    let authType: RunnerConnectionAuthType
    let categoryId: String
    let requiredScopes: [String]?
    let comingSoon: Bool?
    let integrations: [RunnerConnectionIntegrationFeature]?
}

struct RunnerConnectionIntegrationFeature: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let requiredScopes: [String]?
}

struct RunnerConnectionProvider: Decodable, Identifiable, Hashable {
    let id: String
    let displayName: String
    let authType: RunnerConnectionAuthType
    let apiKeyConfig: RunnerConnectionAPIKeyConfig?
    let nangoApiKeyHint: RunnerConnectionNangoHint?
    let manualConfig: RunnerConnectionManualConfig?
    let constraints: RunnerConnectionConstraints?
    let envVar: String?
}

struct RunnerConnectionAPIKeyConfig: Decodable, Hashable {
    let inputLabel: String
    let placeholder: String?
    let helpUrl: String?
    let hasVerification: Bool
}

struct RunnerConnectionManualConfig: Decodable, Hashable {
    let fields: [RunnerConnectionManualField]
}

struct RunnerConnectionManualField: Decodable, Hashable {
    let key: String
    let label: String
    let placeholder: String?
    let inputType: String?
}

struct RunnerConnectionConstraints: Decodable, Hashable {
    let maxPerAgent: Int?
    let uniqueAcrossAgents: Bool?
    let maxPerUser: Int?
}

struct RunnerConnectionNangoHint: Decodable, Hashable {
    let label: String
    let description: String
    let links: [RunnerConnectionNangoHintLink]
}

struct RunnerConnectionNangoHintLink: Decodable, Hashable {
    let url: String
    let label: String
}

struct RunnerConnectionOAuthAuthorizeResponse: Decodable {
    let authUrl: String
}

struct RunnerConnectionMutationResponse: Decodable {
    let success: Bool?
}

struct AgentTextingDetails: Decodable, Hashable {
    let destinationE164: String?
    let status: String?
    let pendingReason: String?
    let senderNumber: String?
}

extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

extension AgentConnectionDetails: Identifiable {}

extension AgentConnectionDetails {
    func covers(requiredScopes: [String]?) -> Bool {
        guard let requiredScopes, !requiredScopes.isEmpty else {
            return true
        }

        let granted = Set((scopes ?? "").split(separator: " ").map(String.init))
        return requiredScopes.allSatisfy(granted.contains)
    }
}
