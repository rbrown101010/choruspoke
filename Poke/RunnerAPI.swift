import Foundation

final class RunnerAPIClient {
    let config: RunnerConnectionConfig
    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder = JSONEncoder()

    init(config: RunnerConnectionConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder = decoder
    }

    func fetchDevToken() async throws -> RunnerDevTokenResponse {
        try await request(
            path: "/api/v1/auth/dev-token",
            requiresAuth: false,
            responseType: RunnerDevTokenResponse.self
        )
    }

    func bootstrap() async throws -> RunnerBootstrap {
        try await request(path: "/api/v1/bootstrap", responseType: RunnerBootstrap.self)
    }

    func exchangeBootstrapToken(_ bootstrapToken: String) async throws -> RunnerBootstrapExchangeResponse {
        let body = try jsonEncoder.encode(["bootstrapToken": bootstrapToken])
        return try await request(
            path: "/api/v1/auth/exchange",
            method: "POST",
            body: body,
            requiresAuth: false,
            responseType: RunnerBootstrapExchangeResponse.self
        )
    }

    func listFiles(path: String = "", showHidden: Bool = false) async throws -> RunnerFileListResponse {
        var queryItems: [URLQueryItem] = []
        if !path.isEmpty {
            queryItems.append(URLQueryItem(name: "path", value: path))
        }
        if showHidden {
            queryItems.append(URLQueryItem(name: "showHidden", value: "1"))
        }
        return try await request(
            path: "/api/v1/files/list",
            queryItems: queryItems,
            responseType: RunnerFileListResponse.self
        )
    }

    func fileContent(path: String) async throws -> RunnerFileContent {
        try await request(
            path: "/api/v1/files/content",
            queryItems: [URLQueryItem(name: "path", value: path)],
            responseType: RunnerFileContent.self
        )
    }

    func listSkills() async throws -> RunnerSkillsResponse {
        try await request(path: "/api/v1/skills", responseType: RunnerSkillsResponse.self)
    }

    func skillContent(name: String) async throws -> RunnerSkillContentResponse {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        return try await request(
            path: "/api/v1/skills/\(encodedName)/content",
            responseType: RunnerSkillContentResponse.self
        )
    }

    func browseMarketplace(limit: Int = 20, cursor: String? = nil) async throws -> RunnerMarketplaceBrowseResponse {
        var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return try await request(
            path: "/api/v1/marketplace/browse",
            queryItems: queryItems,
            responseType: RunnerMarketplaceBrowseResponse.self
        )
    }

    func marketplaceSkillDetail(slug: String, source: String) async throws -> RunnerMarketplaceSkillDetail {
        let encodedSlug = slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? slug
        return try await request(
            path: "/api/v1/marketplace/skills/\(encodedSlug)",
            queryItems: [URLQueryItem(name: "source", value: source)],
            responseType: RunnerMarketplaceSkillDetail.self
        )
    }

    func marketplaceSkillFile(slug: String, source: String, path: String = "SKILL.md") async throws -> RunnerMarketplaceSkillFileResponse {
        let encodedSlug = slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? slug
        return try await request(
            path: "/api/v1/marketplace/skills/\(encodedSlug)/file",
            queryItems: [
                URLQueryItem(name: "source", value: source),
                URLQueryItem(name: "path", value: path),
            ],
            responseType: RunnerMarketplaceSkillFileResponse.self
        )
    }

    func installMarketplaceSkill(slug: String, source: String) async throws -> RunnerMarketplaceInstallResult {
        let body = try jsonEncoder.encode(["slug": slug, "source": source])
        return try await request(
            path: "/api/v1/marketplace/install",
            method: "POST",
            body: body,
            responseType: RunnerMarketplaceInstallResult.self
        )
    }

    func listCronJobs() async throws -> RunnerCronJobsResponse {
        try await request(path: "/api/v1/cron/jobs", responseType: RunnerCronJobsResponse.self)
    }

    func marketplaceIconURL(slug: String, source: String) -> URL? {
        let encodedSlug = slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? slug
        return try? buildAuthorizedURL(
            path: "/api/v1/marketplace/skills/\(encodedSlug)/icon",
            queryItems: [URLQueryItem(name: "source", value: source)]
        )
    }

    func skillIconURL(skillKey: String) -> URL? {
        let encodedSkillKey = skillKey.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? skillKey
        return try? buildAuthorizedURL(path: "/api/v1/skills/\(encodedSkillKey)/icon", queryItems: [])
    }

    private func request<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true,
        responseType: T.Type
    ) async throws -> T {
        let url = try buildURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = path == "/api/v1/marketplace/install" ? 600 : 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth, !config.normalizedToken.isEmpty {
            request.setValue("Bearer \(config.normalizedToken)", forHTTPHeaderField: "Authorization")
            request.setValue(config.normalizedToken, forHTTPHeaderField: "x-masterclaw-token")
        }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw RunnerClientError.malformedResponse
        }

        if !(200...299).contains(http.statusCode) {
            if let errorEnvelope = try? jsonDecoder.decode(RunnerErrorEnvelope.self, from: data) {
                throw RunnerClientError.message(errorEnvelope.error.message)
            }
            let text = String(data: data, encoding: .utf8)?.nilIfEmpty ?? "Request failed."
            throw RunnerClientError.message(text)
        }

        guard let envelope = try? jsonDecoder.decode(RunnerEnvelope<T>.self, from: data) else {
            throw RunnerClientError.malformedResponse
        }

        return envelope.data
    }

    private func buildURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(string: config.normalizedBaseURL) else {
            throw RunnerClientError.invalidURL
        }

        let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
        components.path = cleanPath
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw RunnerClientError.invalidURL
        }

        return url
    }

    private func buildAuthorizedURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        var items = queryItems
        if !config.normalizedToken.isEmpty {
            items.append(URLQueryItem(name: "token", value: config.normalizedToken))
        }
        return try buildURL(path: path, queryItems: items)
    }
}
