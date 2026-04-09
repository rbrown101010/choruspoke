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

    static let defaultLocal = RunnerConnectionConfig(
        baseURL: "http://localhost",
        token: "",
        lastConnectedAt: nil
    )

    var normalizedBaseURL: String {
        var value = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            value = Self.defaultLocal.baseURL
        }

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
    let latestVersion: String

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
    let version: String
    let source: String
    let installedSkillKey: String?
    let installedDeps: [String]
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

extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
