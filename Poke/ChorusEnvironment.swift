import Foundation

enum ChorusEnvironment {
    private static let liveAgentsBackendBaseURL = "https://api.chorus.com"
    private static let liveClerkPublishableKey = "pk_live_Y2xlcmsudmliZWNvZGVhcHAuY29tJA"
    private static let debugClerkPublishableKey = "pk_test_c3RlcmxpbmctamFja2FsLTY3LmNsZXJrLmFjY291bnRzLmRldiQ"
    private static let defaultClerkRedirectURL = "vibecode://auth-redirect"
    private static let defaultConnectionRedirectURL = "vibecode://oauth/callback"

    static var agentsBackendBaseURL: String {
        let override = ProcessInfo.processInfo.environment["CHORUS_AGENTS_BACKEND_BASE_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (override?.isEmpty == false) ? override! : liveAgentsBackendBaseURL
    }

    static var clerkPublishableKey: String {
        if let override = ProcessInfo.processInfo.environment["CHORUS_CLERK_PUBLISHABLE_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !override.isEmpty {
            return override
        }

        guard let host = URL(string: agentsBackendBaseURL)?.host?.lowercased() else {
            return liveClerkPublishableKey
        }

        if host == "localhost" || host == "127.0.0.1" {
            return debugClerkPublishableKey
        }

        return liveClerkPublishableKey
    }

    static var clerkRedirectURL: String {
        let override = ProcessInfo.processInfo.environment["CHORUS_CLERK_REDIRECT_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (override?.isEmpty == false) ? override! : defaultClerkRedirectURL
    }

    static var clerkCallbackScheme: String {
        URL(string: clerkRedirectURL)?.scheme?.nilIfEmpty ?? "vibecode"
    }

    static var connectionRedirectURL: String {
        let override = ProcessInfo.processInfo.environment["CHORUS_CONNECTION_REDIRECT_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (override?.isEmpty == false) ? override! : defaultConnectionRedirectURL
    }

    static var connectionCallbackScheme: String {
        URL(string: connectionRedirectURL)?.scheme?.nilIfEmpty ?? clerkCallbackScheme
    }
}
