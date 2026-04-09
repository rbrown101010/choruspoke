import SwiftUI
import UIKit

private enum FilesTab: Hashable {
    case personality
    case files
}

private enum FileRoute: Hashable {
    case directory(String, String)
    case file(String)
}

struct FilesSheetView: View {
    @EnvironmentObject private var appModel: RunnerAppModel
    @State private var selectedTab: FilesTab = .personality
    @State private var rootEntries: [RunnerFileEntry] = []
    @State private var isLoading = false
    @State private var error: String?

    private let preferredPersonalityOrder = [
        "AGENTS.md",
        "BOOTSTRAP.md",
        "IDENTITY.md",
        "SOUL.md",
        "USER.md",
        "TOOLS.md",
        "HEARTBEAT.md",
        "TODO.md",
    ]

    var body: some View {
        NavigationStack {
            RunnerPanel(title: "Files") {
                Group {
                    if appModel.client == nil {
                        disconnectedState
                    } else if isLoading && rootEntries.isEmpty {
                        ProgressView()
                            .tint(RunnerTheme.primaryText)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                Text(subtitle)
                                    .font(RunnerTypography.sans(12, weight: .medium))
                                    .foregroundStyle(RunnerTheme.tertiaryText)

                                RunnerSegmentedControl(
                                    options: [(.personality, "Personality"), (.files, "Files")],
                                    selection: $selectedTab
                                )

                                if let error {
                                    RunnerInlineNotice(text: error)
                                }

                                if selectedTab == .personality {
                                    personalityList
                                } else {
                                    fileOverview
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationDestination(for: FileRoute.self) { route in
                switch route {
                case .directory(let path, let title):
                    FileBrowserView(path: path, title: title)
                case .file(let path):
                    FileContentView(path: path)
                }
            }
            .task {
                await loadRoot()
            }
        }
    }

    private var subtitle: String {
        return "\(personalityFiles.count) personality files · \(directories.count) folders"
    }

    private var personalityFiles: [RunnerFileEntry] {
        rootEntries
            .filter { !$0.isDir && $0.isMarkdown }
            .sorted { lhs, rhs in
                let lhsIndex = preferredPersonalityOrder.firstIndex(of: lhs.name) ?? Int.max
                let rhsIndex = preferredPersonalityOrder.firstIndex(of: rhs.name) ?? Int.max
                if lhsIndex == rhsIndex {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhsIndex < rhsIndex
            }
    }

    private var directories: [RunnerFileEntry] {
        rootEntries
            .filter(\.isDir)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var nonDirectoryFiles: [RunnerFileEntry] {
        rootEntries
            .filter { !$0.isDir && !$0.isMarkdown }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var disconnectedState: some View {
        RunnerEmptyState(
            icon: "network.slash",
            title: "Runner connection needed",
            message: "Open Settings and point the app at your local runner stack first."
        )
    }

    private var personalityList: some View {
        VStack(spacing: 10) {
            if personalityFiles.isEmpty {
                RunnerEmptyState(
                    icon: "doc.text",
                    title: "No personality files yet",
                    message: "When runner creates workspace markdown files, they’ll appear here."
                )
            } else {
                ForEach(personalityFiles) { file in
                    NavigationLink(value: FileRoute.file(file.path)) {
                        HStack(spacing: 14) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(RunnerTheme.accent)
                                .frame(width: 26)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(file.name)
                                    .font(RunnerTypography.sans(15, weight: .semibold))
                                    .foregroundStyle(RunnerTheme.primaryText)

                                Text(runnerFormattedBytes(file.size))
                                    .font(RunnerTypography.sans(12, weight: .medium))
                                    .foregroundStyle(RunnerTheme.tertiaryText)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(RunnerTheme.tertiaryText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .runnerCard()
                    }
                }
            }
        }
    }

    private var fileOverview: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !directories.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Folders")
                        .font(RunnerTypography.sans(13, weight: .semibold))
                        .foregroundStyle(RunnerTheme.secondaryText)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ], spacing: 12) {
                        ForEach(directories) { directory in
                            NavigationLink(value: FileRoute.directory(directory.path, directory.name)) {
                                VStack(spacing: 10) {
                                    RunnerFolderGlyph(size: 52)

                                    Text(directory.name)
                                        .font(RunnerTypography.sans(12, weight: .semibold))
                                        .foregroundStyle(RunnerTheme.primaryText)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 112)
                                .padding(.horizontal, 8)
                                .runnerCard()
                            }
                        }
                    }
                }
            }

            if !nonDirectoryFiles.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top-level files")
                        .font(RunnerTypography.sans(13, weight: .semibold))
                        .foregroundStyle(RunnerTheme.secondaryText)

                    ForEach(nonDirectoryFiles) { file in
                        NavigationLink(value: FileRoute.file(file.path)) {
                            HStack(spacing: 14) {
                                Image(systemName: "doc.richtext")
                                    .foregroundStyle(RunnerTheme.accentBlue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(file.name)
                                        .font(RunnerTypography.sans(15, weight: .semibold))
                                        .foregroundStyle(RunnerTheme.primaryText)
                                    Text(runnerFormattedBytes(file.size))
                                        .font(RunnerTypography.sans(12, weight: .medium))
                                        .foregroundStyle(RunnerTheme.tertiaryText)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .runnerCard()
                        }
                    }
                }
            }
        }
    }

    private func loadRoot() async {
        guard let client = appModel.client else {
            error = nil
            rootEntries = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.listFiles()
            error = nil
            rootEntries = response.entries
        } catch {
            rootEntries = []
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private struct FileBrowserView: View {
    @EnvironmentObject private var appModel: RunnerAppModel
    let path: String
    let title: String

    @State private var entries: [RunnerFileEntry] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        RunnerPanel(title: title) {
            Group {
                if isLoading && entries.isEmpty {
                    ProgressView()
                        .tint(RunnerTheme.primaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error {
                    RunnerEmptyState(
                        icon: "folder.badge.questionmark",
                        title: "Folder unavailable",
                        message: error
                    )
                } else if entries.isEmpty {
                    RunnerEmptyState(
                        icon: "folder",
                        title: "Folder is empty",
                        message: "There’s nothing in this directory yet."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            Text(path)
                                .font(RunnerTypography.sans(12, weight: .medium))
                                .foregroundStyle(RunnerTheme.tertiaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)

                            ForEach(entries) { entry in
                                if entry.isDir {
                                    NavigationLink(value: FileRoute.directory(entry.path, entry.name)) {
                                        browserRow(entry: entry, isDirectory: true)
                                    }
                                } else {
                                    NavigationLink(value: FileRoute.file(entry.path)) {
                                        browserRow(entry: entry, isDirectory: false)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func browserRow(entry: RunnerFileEntry, isDirectory: Bool) -> some View {
        HStack(spacing: 14) {
            Group {
                if isDirectory {
                    RunnerFolderGlyph(size: 28)
                } else {
                    Image(systemName: "doc.text")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(RunnerTheme.accentBlue)
                }
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(RunnerTypography.sans(15, weight: .semibold))
                    .foregroundStyle(RunnerTheme.primaryText)

                Text(entry.isDir ? "Folder" : runnerFormattedBytes(entry.size))
                    .font(RunnerTypography.sans(12, weight: .medium))
                    .foregroundStyle(RunnerTheme.tertiaryText)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(RunnerTheme.tertiaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .runnerCard()
    }

    private func load() async {
        guard let client = appModel.client else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.listFiles(path: path)
            error = nil
            entries = response.entries.sorted { lhs, rhs in
                if lhs.isDir != rhs.isDir {
                    return lhs.isDir
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private struct FileContentView: View {
    @EnvironmentObject private var appModel: RunnerAppModel
    let path: String

    @State private var content: RunnerFileContent?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        RunnerPanel(title: content?.name ?? path) {
            Group {
                if isLoading && content == nil {
                    ProgressView()
                        .tint(RunnerTheme.primaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error {
                    RunnerEmptyState(
                        icon: "doc.badge.ellipsis",
                        title: "Couldn’t open file",
                        message: error
                    )
                } else if let content {
                    fileContentBody(content)
                } else {
                    Color.clear
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    @ViewBuilder
    private func fileContentBody(_ file: RunnerFileContent) -> some View {
        if file.mimeType.hasPrefix("image/"),
           let base64 = file.contentBase64,
           let data = Data(base64Encoded: base64),
           let uiImage = UIImage(data: data) {
            ScrollView {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(20)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(path)
                        .font(RunnerTypography.sans(12, weight: .medium))
                        .foregroundStyle(RunnerTheme.tertiaryText)

                    if file.content.isEmpty {
                        Text("This file is empty.")
                            .font(RunnerTypography.sans(15, weight: .medium))
                            .foregroundStyle(RunnerTheme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if isMarkdownFile(file) {
                        RunnerMarkdownView(content: file.content)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(file.content)
                                .font(RunnerTypography.mono(14))
                                .foregroundStyle(RunnerTheme.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.black.opacity(0.22))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(RunnerTheme.border.opacity(0.7), lineWidth: 1)
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
        }
    }

    private func isMarkdownFile(_ file: RunnerFileContent) -> Bool {
        let loweredPath = path.lowercased()
        return loweredPath.hasSuffix(".md")
            || loweredPath.hasSuffix(".mdx")
            || file.mimeType.localizedCaseInsensitiveContains("markdown")
    }

    private func load() async {
        guard let client = appModel.client else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            content = try await client.fileContent(path: path)
            error = nil
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
