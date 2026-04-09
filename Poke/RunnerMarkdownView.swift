import Foundation
import SwiftUI

struct RunnerMarkdownView: View {
    let content: String

    private var blocks: [RunnerMarkdownBlock] {
        RunnerMarkdownParser.parse(content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { entry in
                blockView(entry.element)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: RunnerMarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            inlineMarkdownText(text, font: headingFont(for: level), color: RunnerTheme.primaryText)
                .padding(.top, level <= 2 ? 4 : 0)

        case .paragraph(let text):
            inlineMarkdownText(text, font: paragraphFont, color: paragraphColor)
                .lineSpacing(4)

        case .unorderedList(let items):
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { entry in
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                            .font(RunnerTypography.sans(15, weight: .bold))
                            .foregroundStyle(RunnerTheme.tertiaryText)
                            .padding(.top, 1)

                        inlineMarkdownText(entry.element, font: paragraphFont, color: listColor)
                            .lineSpacing(4)
                    }
                }
            }

        case .orderedList(let items):
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { entry in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(entry.offset + 1).")
                            .font(RunnerTypography.sans(14, weight: .semibold))
                            .foregroundStyle(RunnerTheme.tertiaryText)
                            .frame(minWidth: 20, alignment: .trailing)
                            .padding(.top, 1)

                        inlineMarkdownText(entry.element, font: paragraphFont, color: listColor)
                            .lineSpacing(4)
                    }
                }
            }

        case .blockquote(let text):
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(RunnerTheme.borderStrong)
                    .frame(width: 3)

                inlineMarkdownText(text, font: paragraphFont, color: listColor)
                    .italic()
                    .lineSpacing(4)
            }
            .padding(.vertical, 2)

        case .codeBlock(let language, let code):
            VStack(alignment: .leading, spacing: 8) {
                if let language, !language.isEmpty {
                    Text(language.uppercased())
                        .font(RunnerTypography.sans(11, weight: .bold))
                        .foregroundStyle(RunnerTheme.tertiaryText)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    Text(code)
                        .font(RunnerTypography.mono(13))
                        .foregroundStyle(RunnerTheme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.32))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(RunnerTheme.border.opacity(0.8), lineWidth: 1)
                )
            }

        case .divider:
            Rectangle()
                .fill(RunnerTheme.border.opacity(0.5))
                .frame(height: 1)
                .padding(.vertical, 4)

        case .table(let raw):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(raw)
                    .font(RunnerTypography.mono(13))
                    .foregroundStyle(RunnerTheme.secondaryText)
                    .padding(14)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(RunnerTheme.border.opacity(0.7), lineWidth: 1)
            )
        }
    }

    private var paragraphFont: Font {
        RunnerTypography.sans(15, weight: .medium)
    }

    private var paragraphColor: Color {
        RunnerTheme.primaryText.opacity(0.95)
    }

    private var listColor: Color {
        RunnerTheme.secondaryText
    }

    private func inlineMarkdownText(_ text: String, font: Font, color: Color) -> Text {
        if let attributed = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) {
            return Text(attributed)
                .font(font)
                .foregroundColor(color)
        }

        return Text(text)
            .font(font)
            .foregroundColor(color)
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1:
            return RunnerTypography.sans(28, weight: .semibold)
        case 2:
            return RunnerTypography.sans(22, weight: .semibold)
        case 3:
            return RunnerTypography.sans(18, weight: .semibold)
        default:
            return RunnerTypography.sans(16, weight: .semibold)
        }
    }
}

private enum RunnerMarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case unorderedList([String])
    case orderedList([String])
    case blockquote(String)
    case codeBlock(language: String?, code: String)
    case table(String)
    case divider
}

private enum RunnerMarkdownParser {
    static func parse(_ content: String) -> [RunnerMarkdownBlock] {
        let lines = content.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        var blocks: [RunnerMarkdownBlock] = []
        var index = 0

        func trimmed(_ line: String) -> String {
            line.trimmingCharacters(in: .whitespaces)
        }

        while index < lines.count {
            let line = lines[index]
            let clean = trimmed(line)

            if clean.isEmpty {
                index += 1
                continue
            }

            if clean.hasPrefix("```") {
                let language = String(clean.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                index += 1
                var codeLines: [String] = []
                while index < lines.count && !trimmed(lines[index]).hasPrefix("```") {
                    codeLines.append(lines[index])
                    index += 1
                }
                if index < lines.count {
                    index += 1
                }
                blocks.append(.codeBlock(language: language, code: codeLines.joined(separator: "\n")))
                continue
            }

            if let heading = headingBlock(from: clean) {
                blocks.append(heading)
                index += 1
                continue
            }

            if isDivider(clean) {
                blocks.append(.divider)
                index += 1
                continue
            }

            if isTableHeader(lines, at: index) {
                var tableLines: [String] = []
                while index < lines.count {
                    let next = trimmed(lines[index])
                    if next.isEmpty || !next.contains("|") {
                        break
                    }
                    tableLines.append(lines[index])
                    index += 1
                }
                blocks.append(.table(tableLines.joined(separator: "\n")))
                continue
            }

            if let item = unorderedItem(from: clean) {
                var items = [item]
                index += 1
                while index < lines.count, let next = unorderedItem(from: trimmed(lines[index])) {
                    items.append(next)
                    index += 1
                }
                blocks.append(.unorderedList(items))
                continue
            }

            if let item = orderedItem(from: clean) {
                var items = [item]
                index += 1
                while index < lines.count, let next = orderedItem(from: trimmed(lines[index])) {
                    items.append(next)
                    index += 1
                }
                blocks.append(.orderedList(items))
                continue
            }

            if clean.hasPrefix(">") {
                var quoteLines: [String] = [String(clean.dropFirst()).trimmingCharacters(in: .whitespaces)]
                index += 1
                while index < lines.count {
                    let next = trimmed(lines[index])
                    guard next.hasPrefix(">") else { break }
                    quoteLines.append(String(next.dropFirst()).trimmingCharacters(in: .whitespaces))
                    index += 1
                }
                blocks.append(.blockquote(quoteLines.joined(separator: "\n")))
                continue
            }

            var paragraphLines: [String] = [line]
            index += 1
            while index < lines.count {
                let next = lines[index]
                let nextTrimmed = trimmed(next)
                if nextTrimmed.isEmpty
                    || nextTrimmed.hasPrefix("```")
                    || headingBlock(from: nextTrimmed) != nil
                    || isDivider(nextTrimmed)
                    || unorderedItem(from: nextTrimmed) != nil
                    || orderedItem(from: nextTrimmed) != nil
                    || nextTrimmed.hasPrefix(">")
                    || isTableHeader(lines, at: index) {
                    break
                }
                paragraphLines.append(next)
                index += 1
            }
            blocks.append(.paragraph(paragraphLines.joined(separator: "\n")))
        }

        return blocks
    }

    private static func headingBlock(from line: String) -> RunnerMarkdownBlock? {
        let hashes = line.prefix { $0 == "#" }.count
        guard (1...6).contains(hashes) else { return nil }
        let text = line.dropFirst(hashes).trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        return .heading(level: hashes, text: text)
    }

    private static func unorderedItem(from line: String) -> String? {
        guard line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") else { return nil }
        return String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
    }

    private static func orderedItem(from line: String) -> String? {
        let comps = line.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        guard comps.count == 2, Int(comps[0]) != nil else { return nil }
        let text = String(comps[1]).trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
    }

    private static func isDivider(_ line: String) -> Bool {
        let compact = line.replacingOccurrences(of: " ", with: "")
        return compact == "---" || compact == "***" || compact == "___"
    }

    private static func isTableHeader(_ lines: [String], at index: Int) -> Bool {
        guard index + 1 < lines.count else { return false }
        let header = lines[index].trimmingCharacters(in: .whitespaces)
        let separator = lines[index + 1].trimmingCharacters(in: .whitespaces)
        guard header.contains("|"), separator.contains("|") else { return false }
        let separatorSet = CharacterSet(charactersIn: "|:- ")
        return separator.unicodeScalars.allSatisfy(separatorSet.contains)
    }
}
