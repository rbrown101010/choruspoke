import Foundation
import SwiftUI

private enum HomeSheet: String, Identifiable {
    case files
    case skills
    case connections
    case cron
    case channels
    case settings

    var id: String { rawValue }
}

struct HomeView: View {
    @EnvironmentObject private var appModel: RunnerAppModel
    @State private var activeSheet: HomeSheet?
    @State private var showingNewAgent = false

    private var heroCardDescriptor: RunnerAgentHeroCardDescriptor {
        RunnerAgentHeroCardStore.shared.descriptor(
            for: appModel.selectedAgent,
            runnerAgentID: appModel.bootstrap?.agentId
        )
    }

    var body: some View {
        ZStack {
            RunnerBackgroundView()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                Spacer()

                hero
                    .offset(y: -18)

                bottomTabs
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            destination(for: sheet)
                .presentationDetents([sheet == .files ? .fraction(0.90) : .fraction(0.86)])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showingNewAgent) {
            NewAgentPageView()
                .environmentObject(appModel)
        }
    }

    private var topBar: some View {
        HStack {
            agentSelector

            Spacer()

            Button {
                Haptics.tap()
                activeSheet = .settings
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [RunnerTheme.accentBlue, RunnerTheme.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)

                    Text("R")
                        .font(RunnerTypography.sans(15, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var agentSelector: some View {
        Group {
            if appModel.isSignedIn {
                Menu {
                    if appModel.agents.isEmpty {
                        if let message = appModel.agentsLoadError?.nilIfEmpty {
                            Text(message)
                        } else {
                            Text("No agents yet")
                        }
                    } else {
                        ForEach(appModel.agents) { agent in
                            Button {
                                Task {
                                    await appModel.selectAgent(agent)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(agent.name)
                                        Text(agent.statusLabel)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }

                                    if agent.id == appModel.selectedAgentID {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    Button {
                        Haptics.mainButton()
                        showingNewAgent = true
                    } label: {
                        Label("New Agent", systemImage: "plus")
                    }

                    Button {
                        Task {
                            await appModel.refreshAgentsAndReconnect()
                        }
                    } label: {
                        Label("Refresh Agents", systemImage: "arrow.clockwise")
                    }
                } label: {
                    selectorLabel(title: appModel.selectorTitle)
                }
            } else {
                Button {
                    Haptics.tap()
                    activeSheet = .settings
                } label: {
                    selectorLabel(title: appModel.selectorTitle)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 0) {
            RunnerAgentInteractiveHeroCard(
                title: appModel.agentTitle,
                role: heroCardDescriptor.role,
                color: heroCardDescriptor.color,
                figure: heroCardDescriptor.figure
            )
            .frame(width: 238, height: 340)
            .offset(y: -26)
            .padding(.bottom, 24)

            Text(appModel.agentTitle)
                .font(RunnerTypography.sans(34, weight: .semibold))
                .foregroundStyle(RunnerTheme.primaryText)
                .tracking(-0.6)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(appModel.agentSubtitle)
                .font(RunnerTypography.sans(14, weight: .medium))
                .foregroundStyle(RunnerTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 34)
                .padding(.top, 12)
        }
        .offset(y: 8)
    }

    private var bottomTabs: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ActionButton(icon: .cron, label: "Cron Jobs") {
                    activeSheet = .cron
                }

                ActionButton(icon: .connections, label: "Connections") {
                    activeSheet = .connections
                }
            }

            HStack(spacing: 12) {
                ActionButton(icon: .files, label: "Files") {
                    activeSheet = .files
                }

                ActionButton(icon: .skills, label: "Skills") {
                    activeSheet = .skills
                }

                ActionButton(icon: .channels, label: "Channels") {
                    activeSheet = .channels
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for sheet: HomeSheet) -> some View {
        switch sheet {
        case .files:
            FilesSheetView()
        case .skills:
            SkillsSheetView()
        case .connections:
            ConnectionsSheetView()
        case .cron:
            CronJobsSheetView()
        case .channels:
            ContactLinksSheetView()
        case .settings:
            SettingsView()
        }
    }

    private func selectorLabel(title: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(RunnerTypography.sans(13, weight: .semibold))
                .foregroundStyle(RunnerTheme.primaryText)
                .lineLimit(1)

            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(RunnerTheme.secondaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(RunnerTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(RunnerTheme.borderStrong, lineWidth: 1)
        )
    }
}

private struct RunnerAgentHeroCard: View {
    let title: String
    let role: String
    let color: RunnerAgentHeroCardColor
    let figure: RunnerAgentHeroFigure

    private let baseCardSize = CGSize(width: 280, height: 400)

    var body: some View {
        GeometryReader { geometry in
            let scale = min(
                geometry.size.width / baseCardSize.width,
                geometry.size.height / baseCardSize.height
            )
            cardBody
                .frame(width: baseCardSize.width, height: baseCardSize.height)
                .scaleEffect(scale, anchor: .center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var cardBody: some View {
        let cardShape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        return ZStack(alignment: .topLeading) {
            cardShape
                .fill(Color.white.opacity(0.025))

            cardShape
                .fill(
                    LinearGradient(
                        colors: [
                            color.backgroundTop.opacity(0.70),
                            color.backgroundBottom,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            cardShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.clear,
                            Color.clear,
                            Color.black.opacity(0.16),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            cardShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.05),
                            Color.clear,
                        ],
                        startPoint: UnitPoint(x: 0.08, y: 0.02),
                        endPoint: UnitPoint(x: 0.82, y: 0.42)
                    )
                )

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .frame(width: 72, height: 22)
                .offset(x: 16, y: 14)

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.20),
                            Color.white.opacity(0.08),
                            Color.clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 176, height: 104)
                .blur(radius: 14)
                .rotationEffect(.degrees(-10))
                .offset(x: 18, y: 8)
                .blendMode(.screen)

            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.10))
                .frame(width: 78, height: 16)
                .blur(radius: 6)
                .offset(x: 92, y: 10)
                .blendMode(.screen)

            RunnerAgentFigureView(color: color, figure: figure)
                .frame(width: 292, height: 292)
                .scaleEffect(0.93, anchor: .center)
                .offset(x: 72, y: 58)
                .allowsHitTesting(false)

            Text(title)
                .font(RunnerTypography.sans(16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .padding(.top, 18)
                .padding(.leading, 18)

        }
        .clipShape(cardShape)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            color.borderTop,
                            color.borderBottom,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 4
                )
                .padding(2)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 22, x: 0, y: 16)
        .compositingGroup()
    }
}

private struct RunnerAgentInteractiveHeroCard: View {
    let title: String
    let role: String
    let color: RunnerAgentHeroCardColor
    let figure: RunnerAgentHeroFigure

    @State private var touchLocation: CGPoint?
    @State private var isInteracting = false

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                let idleTiltX = isInteracting ? 0 : sin(time * 0.74) * 1.8
                let idleTiltY = isInteracting ? 0 : sin((time * 0.52) + 0.7) * 2.2
                let touchTilt = touchLocation.map { tilt(for: $0, in: geometry.size) }
                let tiltX = touchTilt?.x ?? idleTiltX
                let tiltY = touchTilt?.y ?? idleTiltY
                let progressX = max(0, min(1, (touchLocation?.x ?? (geometry.size.width * 0.56)) / max(geometry.size.width, 1)))
                let progressY = max(0, min(1, (touchLocation?.y ?? (geometry.size.height * 0.30)) / max(geometry.size.height, 1)))

                ZStack {
                    RunnerAgentHeroBackdropGlow(color: color)
                        .frame(width: geometry.size.width, height: geometry.size.height)

                    RunnerAgentHeroCard(
                        title: title,
                        role: role,
                        color: color,
                        figure: figure
                    )
                    .overlay {
                        RunnerAgentSpecularOverlay(
                            progressX: progressX,
                            progressY: progressY,
                            isInteracting: isInteracting
                        )
                        .compositingGroup()
                        .mask(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .allowsHitTesting(false)
                    }
                    .rotation3DEffect(.degrees(tiltX), axis: (x: 1, y: 0, z: 0), perspective: 0.7)
                    .rotation3DEffect(.degrees(tiltY), axis: (x: 0, y: 1, z: 0), perspective: 0.7)
                    .scaleEffect(isInteracting ? 1.02 : 1.0)
                    .animation(isInteracting ? .easeOut(duration: 0.1) : .spring(response: 0.42, dampingFraction: 0.82), value: tiltX)
                    .animation(isInteracting ? .easeOut(duration: 0.1) : .spring(response: 0.42, dampingFraction: 0.82), value: tiltY)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            isInteracting = true
                            touchLocation = clamped(point: value.location, in: geometry.size)
                        }
                        .onEnded { _ in
                            isInteracting = false
                            touchLocation = nil
                        }
                )
            }
        }
    }

    private func tilt(for point: CGPoint, in size: CGSize) -> (x: Double, y: Double) {
        let centerX = size.width * 0.5
        let centerY = size.height * 0.5
        let normalizedX = min(max((point.x - centerX) / max(centerX, 1), -1), 1)
        let normalizedY = min(max((point.y - centerY) / max(centerY, 1), -1), 1)
        let maxTilt = 15.0
        return (x: -normalizedY * maxTilt, y: normalizedX * maxTilt)
    }

    private func clamped(point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(0, point.x), size.width),
            y: min(max(0, point.y), size.height)
        )
    }
}

private struct RunnerAgentHeroBackdropGlow: View {
    let color: RunnerAgentHeroCardColor

    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            color.figureTop.opacity(0.22),
                            color.figureTop.opacity(0.08),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 140
                    )
                )
                .frame(width: 248, height: 188)
                .blur(radius: 28)
                .offset(y: -12)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            color.figureBottom.opacity(0.12),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 6,
                        endRadius: 160
                    )
                )
                .frame(width: 286, height: 230)
                .blur(radius: 34)
                .offset(y: 8)
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
    }
}

private struct RunnerAgentSpecularOverlay: View {
    let progressX: Double
    let progressY: Double
    let isInteracting: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(isInteracting ? 0.13 : 0.09),
                            Color.white.opacity(isInteracting ? 0.045 : 0.025),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: 92
                    )
                )
                .frame(width: 154, height: 92)
                .blur(radius: isInteracting ? 8 : 11)
                .rotationEffect(.degrees(-12))
                .offset(
                    x: ((progressX - 0.5) * 20) - 34,
                    y: ((progressY - 0.5) * 10) - 122
                )

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(isInteracting ? 0.025 : 0.015),
                            Color.white.opacity(isInteracting ? 0.075 : 0.045),
                            Color.white.opacity(isInteracting ? 0.028 : 0.016),
                            Color.clear,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 52, height: 244)
                .blur(radius: isInteracting ? 0.5 : 1.0)
                .rotationEffect(.degrees(-22))
                .offset(
                    x: ((progressX - 0.5) * 26) + 18,
                    y: ((progressY - 0.5) * 18) - 12
                )

            LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.03),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 220, height: 80)
            .blur(radius: 10)
            .rotationEffect(.degrees(-8))
            .offset(x: -10, y: -138)
        }
        .blendMode(.screen)
    }
}

private struct RunnerAgentHeroCardDescriptor {
    let color: RunnerAgentHeroCardColor
    let figure: RunnerAgentHeroFigure
    let role: String
}

private struct RunnerAgentFigureView: View {
    let color: RunnerAgentHeroCardColor
    let figure: RunnerAgentHeroFigure

    var body: some View {
        Canvas { context, size in
            let path = RunnerSVGPathCache.shared.path(for: figure.pathData)
            let gradient = Gradient(colors: [color.figureTop, color.figureBottom])
            let strokeStyle = StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)

            var glowContext = context
            glowContext.addFilter(.blur(radius: 10))
            glowContext.stroke(
                path,
                with: .color(color.figureBottom.opacity(0.36)),
                style: strokeStyle
            )

            context.stroke(
                path,
                with: .color(Color.white.opacity(0.025)),
                style: strokeStyle
            )

            context.stroke(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: size.width / 2, y: 0),
                    endPoint: CGPoint(x: size.width / 2, y: size.height)
                ),
                style: strokeStyle
            )
        }
        .drawingGroup()
        .accessibilityHidden(true)
    }
}

private enum RunnerAgentHeroCardColor: String, CaseIterable {
    case blue
    case green
    case magenta
    case purple
    case salt
    case teal
    case volt

    var backgroundTop: Color {
        switch self {
        case .blue: return RunnerHeroRGB(hex: "#1767FD").color
        case .green: return RunnerHeroRGB(hex: "#51B135").color
        case .magenta: return RunnerHeroRGB(hex: "#BB008C").color
        case .purple: return RunnerHeroRGB(hex: "#8745D0").color
        case .salt: return RunnerHeroRGB(hex: "#98A280").color
        case .teal: return RunnerHeroRGB(hex: "#2CD5A9").color
        case .volt: return RunnerHeroRGB(hex: "#D7E307").color
        }
    }

    var backgroundBottom: Color {
        switch self {
        case .blue: return RunnerHeroRGB(hex: "#01163C").color
        case .green: return RunnerHeroRGB(hex: "#11240B").color
        case .magenta: return RunnerHeroRGB(hex: "#28001E").color
        case .purple: return RunnerHeroRGB(hex: "#160925").color
        case .salt: return RunnerHeroRGB(hex: "#1F201A").color
        case .teal: return RunnerHeroRGB(hex: "#051B15").color
        case .volt: return RunnerHeroRGB(hex: "#4B4F03").color
        }
    }

    var borderTop: Color {
        switch self {
        case .blue: return RunnerHeroRGB(hex: "#3A6CC9").color
        case .green: return RunnerHeroRGB(hex: "#62A54E").color
        case .magenta: return RunnerHeroRGB(hex: "#81276A").color
        case .purple: return RunnerHeroRGB(hex: "#7C50AA").color
        case .salt: return RunnerHeroRGB(hex: "#89907B").color
        case .teal: return RunnerHeroRGB(hex: "#4D9A86").color
        case .volt: return RunnerHeroRGB(hex: "#BFC73F").color
        }
    }

    var borderBottom: Color {
        switch self {
        case .blue: return RunnerHeroRGB(hex: "#0A224C").color
        case .green: return RunnerHeroRGB(hex: "#1B3214").color
        case .magenta: return RunnerHeroRGB(hex: "#36072B").color
        case .purple: return RunnerHeroRGB(hex: "#241335").color
        case .salt: return RunnerHeroRGB(hex: "#2C2D27").color
        case .teal: return RunnerHeroRGB(hex: "#112D25").color
        case .volt: return RunnerHeroRGB(hex: "#585C0A").color
        }
    }

    var figureTop: Color {
        switch self {
        case .blue: return RunnerHeroRGB(hex: "#1767FD").color
        case .green: return RunnerHeroRGB(hex: "#51B135").color
        case .magenta: return RunnerHeroRGB(hex: "#E436B8").color
        case .purple: return RunnerHeroRGB(hex: "#9E67DA").color
        case .salt: return RunnerHeroRGB(hex: "#98A280").color
        case .teal: return RunnerHeroRGB(hex: "#2CD5A9").color
        case .volt: return RunnerHeroRGB(hex: "#D7E307").color
        }
    }

    var figureBottom: Color {
        switch self {
        case .blue: return RunnerHeroRGB(hex: "#D5E3FE").color
        case .green: return RunnerHeroRGB(hex: "#DDF3D7").color
        case .magenta: return RunnerHeroRGB(hex: "#FED1F3").color
        case .purple: return RunnerHeroRGB(hex: "#DCC9F2").color
        case .salt: return RunnerHeroRGB(hex: "#F2F6EA").color
        case .teal: return RunnerHeroRGB(hex: "#F0FCF9").color
        case .volt: return RunnerHeroRGB(hex: "#FBFDCF").color
        }
    }

    var roleTop: Color {
        borderTopRGB.interpolated(to: borderBottomRGB, progress: 0.915).color
    }

    var roleBottom: Color {
        borderTopRGB.interpolated(to: borderBottomRGB, progress: 0.99).color
    }

    private var borderTopRGB: RunnerHeroRGB {
        switch self {
        case .blue: return RunnerHeroRGB(hex: "#3A6CC9")
        case .green: return RunnerHeroRGB(hex: "#62A54E")
        case .magenta: return RunnerHeroRGB(hex: "#81276A")
        case .purple: return RunnerHeroRGB(hex: "#7C50AA")
        case .salt: return RunnerHeroRGB(hex: "#89907B")
        case .teal: return RunnerHeroRGB(hex: "#4D9A86")
        case .volt: return RunnerHeroRGB(hex: "#BFC73F")
        }
    }

    private var borderBottomRGB: RunnerHeroRGB {
        switch self {
        case .blue: return RunnerHeroRGB(hex: "#0A224C")
        case .green: return RunnerHeroRGB(hex: "#1B3214")
        case .magenta: return RunnerHeroRGB(hex: "#36072B")
        case .purple: return RunnerHeroRGB(hex: "#241335")
        case .salt: return RunnerHeroRGB(hex: "#2C2D27")
        case .teal: return RunnerHeroRGB(hex: "#112D25")
        case .volt: return RunnerHeroRGB(hex: "#585C0A")
        }
    }
}

private final class RunnerAgentHeroCardStore {
    static let shared = RunnerAgentHeroCardStore()

    func descriptor(for agent: SandboxAgent?, runnerAgentID: String?) -> RunnerAgentHeroCardDescriptor {
        guard let agent else {
            return RunnerAgentHeroCardDescriptor(color: .teal, figure: .wave, role: "OpenClaw Agent")
        }

        let hashSource = runnerAgentID?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? agent.id
        let color = RunnerAgentHeroCardColor.allCases[runnerHash(for: hashSource + "_color") % RunnerAgentHeroCardColor.allCases.count]
        let figure = RunnerAgentHeroFigure.allCases[runnerHash(for: hashSource) % RunnerAgentHeroFigure.allCases.count]
        let role = compactRole(for: agent)
        return RunnerAgentHeroCardDescriptor(color: color, figure: figure, role: role)
    }

    private func runnerHash(for value: String) -> Int {
        var hash: Int32 = 0
        for codeUnit in value.utf16 {
            hash = (hash << 5) &- hash &+ Int32(codeUnit)
        }
        return Int(abs(Int64(hash)))
    }

    private func compactRole(for agent: SandboxAgent) -> String {
        let source = [
            agent.name,
            agent.description ?? "",
            agent.instructions ?? "",
        ]
        .joined(separator: " ")
        .lowercased()

        if source.contains("ios") || source.contains("swiftui") || source.contains("xcode") {
            return "iOS Developer"
        }
        if source.contains("youtube") || source.contains("thumbnail") || source.contains("video") {
            return "YouTube Operator"
        }
        if source.contains("marketing") || source.contains("growth") || source.contains("content") {
            return "Marketing Lead"
        }
        if source.contains("sales") || source.contains("pipeline") || source.contains("lead") {
            return "Sales Operator"
        }
        if source.contains("journal") || source.contains("writing") || source.contains("story") {
            return "Writing Partner"
        }
        if source.contains("design") || source.contains("brand") || source.contains("creative") {
            return "Creative Director"
        }
        if source.contains("research") || source.contains("analysis") || source.contains("intel") {
            return "Research Analyst"
        }

        return "Software Engineer"
    }
}

private struct RunnerHeroRGB {
    let red: Double
    let green: Double
    let blue: Double

    init(hex: String) {
        let value = hex.replacingOccurrences(of: "#", with: "")
        let parsed = UInt64(value, radix: 16) ?? 0
        self.red = Double((parsed >> 16) & 0xFF) / 255.0
        self.green = Double((parsed >> 8) & 0xFF) / 255.0
        self.blue = Double(parsed & 0xFF) / 255.0
    }

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    func interpolated(to other: RunnerHeroRGB, progress: Double) -> RunnerHeroRGB {
        RunnerHeroRGB(
            red: red + ((other.red - red) * progress),
            green: green + ((other.green - green) * progress),
            blue: blue + ((other.blue - blue) * progress)
        )
    }

    private init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

private enum RunnerAgentHeroFigure: String, CaseIterable {
    case wave
    case loop
    case knot
    case figure8
    case ribbon
    case arc
    case infinity

    var pathData: String {
        switch self {
        case .wave:
            return """
            M194.799 146L189.225 152.029L183.546 158.043L177.773 164.03L171.916 169.965L165.997 175.843L160.03 181.648L154.022 187.363L147.998 192.969L141.963 198.459L135.944 203.814L129.946 209.028L123.99 214.079L118.092 218.958L112.261 223.654L106.519 228.151L100.872 232.444L95.3394 236.518L89.9376 240.361L84.677 243.969L79.5733 247.326L74.6317 250.433L69.8731 253.272L65.308 255.84L60.9468 258.13L56.8001 260.138L52.8782 261.858L49.1916 263.281L45.7455 264.41L42.5609 265.242L39.6326 265.775L36.9709 266L34.5864 265.927L32.4842 265.545L30.6697 264.865L29.1428 263.882L27.9139 262.606L26.9831 261.032L26.3556 259.171L26.0261 257.021L26 254.59L26.2771 251.886L26.8576 248.911L27.7413 245.679L28.9179 242.197L30.3925 238.468L32.16 234.51L34.2151 230.326L36.5525 225.929L39.1672 221.332L42.0537 216.542L45.1964 211.574L48.6007 206.439L52.2454 201.153L56.1307 195.73L60.2409 190.176L64.5655 184.518L69.0992 178.756L73.8264 172.915L78.7366 167.006L83.8142 161.039L89.0539 155.041L94.4295 149.017L99.9411 142.983L105.568 136.959L111.299 130.961L117.114 124.994L123.002 119.085L128.953 113.244L134.94 107.482L140.959 101.824L146.988 96.2702L153.018 90.8475L159.031 85.5607L165.008 80.4257L170.938 75.4579L176.8 70.6679L182.589 66.0715L188.289 61.6737L193.879 57.4903L199.343 53.5318L204.677 49.8034L209.864 46.3207L214.89 43.0891L219.737 40.1136L224.402 37.4101L228.867 34.9786L233.124 32.8294L237.161 30.9678L240.963 29.3938L244.529 28.1178L247.849 27.1347L250.908 26.4549L253.701 26.0732L256.227 26L258.47 26.2249L260.426 26.7582L262.099 27.5897L263.474 28.7192L264.557 30.1415L265.336 31.8619L265.817 33.87L265.995 36.1604L265.869 38.7279L265.44 41.5674L264.708 44.6735L263.678 48.0307L262.35 51.6388L260.729 55.4823L258.815 59.5559L256.619 63.849L254.14 68.3462L251.39 73.042L248.378 77.9209L245.099 82.9723L241.574 88.1858L237.809 93.5405L233.809 99.0312L229.589 104.637L225.16 110.352L220.527 116.157L215.711 122.035L210.712 127.97L205.556 133.957L200.243 139.971L194.799 146Z
            """
        case .loop:
            return """
            M146 146L148.264 147.506L150.523 149.017L152.782 150.523L155.041 152.029L157.294 153.535L159.542 155.041L161.786 156.541L164.029 158.042L166.261 159.542L168.484 161.038L170.706 162.533L172.912 164.029L175.114 165.519L177.299 167.004L179.48 168.484L181.644 169.963L183.799 171.443L185.937 172.912L188.065 174.382L190.173 175.841L192.269 177.299L194.35 178.753L196.41 180.201L198.455 181.644L200.478 183.082L202.486 184.515L204.468 185.937L206.434 187.359L208.379 188.771L210.298 190.173L212.196 191.574L214.073 192.965L215.924 194.35L217.749 195.725L219.548 197.095L221.325 198.455L223.072 199.804L224.792 201.148L226.481 202.486L228.144 203.809L229.78 205.127L231.386 206.434L232.959 207.731L234.502 209.022L236.013 210.298L237.493 211.569L238.941 212.824L240.353 214.073L241.733 215.307L243.082 216.536L244.395 217.749L245.671 218.952L246.915 220.144L248.118 221.325L249.289 222.491L250.424 223.647L251.516 224.792L252.578 225.922L253.597 227.041L254.58 228.144L255.522 229.237L256.426 230.319L257.294 231.386L258.12 232.437L258.905 233.477L259.652 234.502L260.358 235.511L261.022 236.51L261.644 237.493L262.23 238.46L262.774 239.417L263.271 240.353L263.731 241.278L264.149 242.188L264.52 243.082L264.855 243.961L265.148 244.824L265.393 245.671L265.597 246.502L265.765 247.318L265.885 248.118L265.963 248.902L266 249.671L265.99 250.424L265.942 251.156L265.848 251.877L265.712 252.578L265.535 253.263L265.315 253.927L265.054 254.58L264.75 255.213L264.4 255.83L264.013 256.426L263.584 257.012L263.108 257.571L262.596 258.12L262.042 258.648L261.446 259.161L260.808 259.652L260.128 260.128L259.407 260.583L258.648 261.022L257.848 261.446L257.012 261.848L256.128 262.23L255.213 262.596L254.256 262.941L253.263 263.271L252.227 263.584L251.156 263.872L250.047 264.149L248.902 264.4L247.72 264.641L246.502 264.855L245.247 265.054L243.961 265.231L242.638 265.393L241.278 265.535L239.888 265.66L238.46 265.765L237.001 265.848L235.511 265.916L233.99 265.963L232.437 265.99L230.852 266L229.237 265.99L227.595 265.963L225.922 265.916L224.222 265.848L222.491 265.765L220.735 265.66L218.952 265.535L217.142 265.393L215.307 265.231L213.451 265.054L211.569 264.855L209.66 264.641L207.731 264.4L205.78 264.149L203.809 263.872L201.817 263.584L199.804 263.271L197.775 262.941L195.725 262.596L193.66 262.23L191.574 261.848L189.472 261.446L187.359 261.022L185.226 260.583L183.082 260.128L180.923 259.652L178.753 259.161L176.573 258.648L174.382 258.12L172.175 257.571L169.963 257.012L167.746 256.426L165.519 255.83L163.281 255.213L161.038 254.58L158.795 253.927L156.541 253.263L154.288 252.578L152.029 251.877L149.77 251.156L147.506 250.424L145.247 249.671L142.983 248.902L140.724 248.118L138.465 247.318L136.207 246.502L133.958 245.671L131.71 244.824L129.467 243.961L127.229 243.082L124.996 242.188L122.774 241.278L120.557 240.353L118.356 239.417L116.159 238.46L113.974 237.493L111.799 236.51L109.634 235.511L107.485 234.502L105.352 233.477L103.229 232.437L101.127 231.386L99.0353 230.319L96.9647 229.237L94.9046 228.144L92.8706 227.041L90.8523 225.922L88.8497 224.792L86.8732 223.647L84.9124 222.491L82.9778 221.325L81.064 220.144L79.1765 218.952L77.3098 217.749L75.4641 216.536L73.6497 215.307L71.8562 214.073L70.0941 212.824L68.3529 211.569L66.6431 210.298L64.9595 209.022L63.3072 207.731L61.681 206.434L60.0863 205.127L58.5229 203.809L56.9909 202.486L55.4902 201.148L54.0209 199.804L52.583 198.455L51.1817 197.095L49.8118 195.725L48.4784 194.35L47.1765 192.965L45.9111 191.574L44.6824 190.173L43.485 188.771L42.3294 187.359L41.2105 185.937L40.1229 184.515L39.0771 183.082L38.0732 181.644L37.1007 180.201L36.1699 178.753L35.281 177.299L34.4288 175.841L33.6131 174.382L32.8392 172.912L32.1072 171.443L31.417 169.963L30.7634 168.484L30.1516 167.004L29.5869 165.519L29.0588 164.029L28.5725 162.533L28.1281 161.038L27.7203 159.542L27.3595 158.042L27.0405 156.541L26.7686 155.041L26.5333 153.535L26.3399 152.029L26.1935 150.523L26.0837 149.017L26.0209 147.506L26 146L26.0209 144.494L26.0837 142.983L26.1935 141.477L26.3399 139.971L26.5333 138.465L26.7686 136.959L27.0405 135.459L27.3595 133.958L27.7203 132.458L28.1281 130.962L28.5725 129.467L29.0588 127.971L29.5869 126.481L30.1516 124.996L30.7634 123.516L31.417 122.037L32.1072 120.557L32.8392 119.088L33.6131 117.618L34.4288 116.159L35.281 114.701L36.1699 113.247L37.1007 111.799L38.0732 110.356L39.0771 108.918L40.1229 107.485L41.2105 106.063L42.3294 104.641L43.485 103.229L44.6824 101.827L45.9111 100.426L47.1765 99.0353L48.4784 97.6497L49.8118 96.2745L51.1817 94.9046L52.583 93.5451L54.0209 92.1961L55.4902 90.8523L56.9909 89.5137L58.5229 88.1908L60.0863 86.8732L61.681 85.566L63.3072 84.2693L64.9595 82.9778L66.6431 81.702L68.3529 80.4314L70.0941 79.1765L71.8562 77.9268L73.6497 76.6928L75.4641 75.4641L77.3098 74.251L79.1765 73.0484L81.064 71.8562L82.9778 70.6745L84.9124 69.5085L86.8732 68.3529L88.8497 67.2078L90.8523 66.0784L92.8706 64.9595L94.9046 63.8562L96.9647 62.7634L99.0353 61.681L101.127 60.6144L103.229 59.5634L105.352 58.5229L107.485 57.498L109.634 56.4889L111.799 55.4902L113.974 54.5072L116.159 53.5399L118.356 52.583L120.557 51.6471L122.774 50.7216L124.996 49.8118L127.229 48.9176L129.467 48.0392L131.71 47.1765L133.958 46.3294L136.207 45.498L138.465 44.6824L140.724 43.8824L142.983 43.098L145.247 42.3294L147.506 41.5765L149.77 40.8444L152.029 40.1229L154.288 39.4222L156.541 38.7373L158.795 38.0732L161.038 37.4196L163.281 36.7869L165.519 36.1699L167.746 35.5739L169.963 34.9882L172.175 34.4288L174.382 33.8797L176.573 33.3516L178.753 32.8392L180.923 32.3477L183.082 31.8719L185.226 31.417L187.359 30.9778L189.472 30.5543L191.574 30.1516L193.66 29.7699L195.725 29.4039L197.775 29.0588L199.804 28.7294L201.817 28.4157L203.809 28.1281L205.78 27.851L207.731 27.6L209.66 27.3595L211.569 27.1451L213.451 26.9464L215.307 26.7686L217.142 26.6065L218.952 26.4654L220.735 26.3399L222.491 26.2353L224.222 26.1516L225.922 26.0837L227.595 26.0366L229.237 26.0105L230.852 26L232.437 26.0105L233.99 26.0366L235.511 26.0837L237.001 26.1516L238.46 26.2353L239.888 26.3399L241.278 26.4654L242.638 26.6065L243.961 26.7686L245.247 26.9464L246.502 27.1451L247.72 27.3595L248.902 27.6L250.047 27.851L251.156 28.1281L252.227 28.4157L253.263 28.7294L254.256 29.0588L255.213 29.4039L256.128 29.7699L257.012 30.1516L257.848 30.5543L258.648 30.9778L259.407 31.417L260.128 31.8719L260.808 32.3477L261.446 32.8392L262.042 33.3516L262.596 33.8797L263.108 34.4288L263.584 34.9882L264.013 35.5739L264.4 36.1699L264.75 36.7869L265.054 37.4196L265.315 38.0732L265.535 38.7373L265.712 39.4222L265.848 40.1229L265.942 40.8444L265.99 41.5765L266 42.3294L265.963 43.098L265.885 43.8824L265.765 44.6824L265.597 45.498L265.393 46.3294L265.148 47.1765L264.855 48.0392L264.52 48.9176L264.149 49.8118L263.731 50.7216L263.271 51.6471L262.774 52.583L262.23 53.5399L261.644 54.5072L261.022 55.4902L260.358 56.4889L259.652 57.498L258.905 58.5229L258.12 59.5634L257.294 60.6144L256.426 61.681L255.522 62.7634L254.58 63.8562L253.597 64.9595L252.578 66.0784L251.516 67.2078L250.424 68.3529L249.289 69.5085L248.118 70.6745L246.915 71.8562L245.671 73.0484L244.395 74.251L243.082 75.4641L241.733 76.6928L240.353 77.9268L238.941 79.1765L237.493 80.4314L236.013 81.702L234.502 82.9778L232.959 84.2693L231.386 85.566L229.78 86.8732L228.144 88.1908L226.481 89.5137L224.792 90.8523L223.072 92.1961L221.325 93.5451L219.548 94.9046L217.749 96.2745L215.924 97.6497L214.073 99.0353L212.196 100.426L210.298 101.827L208.379 103.229L206.434 104.641L204.468 106.063L202.486 107.485L200.478 108.918L198.455 110.356L196.41 111.799L194.35 113.247L192.269 114.701L190.173 116.159L188.065 117.618L185.937 119.088L183.799 120.557L181.644 122.037L179.48 123.516L177.299 124.996L175.114 126.481L172.912 127.971L170.706 129.467L168.484 130.962L166.261 132.458L164.029 133.958L161.786 135.459L159.542 136.959L157.294 138.465L155.041 139.971L152.782 141.477L150.523 142.983L148.264 144.494L146 146Z
            """
        case .ribbon:
            return """
            M266 146L265.979 146.753L265.916 147.506L265.807 148.264L265.66 149.017L265.467 149.77L265.231 150.523L264.959 151.276L264.641 152.029L264.28 152.782L263.872 153.535L263.427 154.288L262.941 155.041L262.413 155.793L261.848 156.541L261.237 157.294L260.583 158.042L259.893 158.795L259.161 159.542L258.387 160.29L257.571 161.038L256.719 161.786L255.83 162.533L254.899 163.281L253.927 164.029L252.923 164.771L251.877 165.519L250.79 166.261L249.671 167.004L248.515 167.746L247.318 168.484L246.089 169.226L244.824 169.963L243.522 170.706L242.188 171.443L240.818 172.175L239.417 172.912L237.979 173.644L236.51 174.382L235.009 175.114L233.477 175.841L231.914 176.573L230.319 177.299L228.693 178.026L227.041 178.753L225.357 179.48L223.647 180.201L221.906 180.923L220.144 181.644L218.35 182.366L216.536 183.082L214.69 183.799L212.824 184.515L210.936 185.226L209.022 185.937L207.088 186.648L205.127 187.359L203.15 188.065L201.148 188.771L199.129 189.472L197.095 190.173L195.035 190.873L192.965 191.574L190.873 192.269L188.771 192.965L186.648 193.66L184.515 194.35L182.366 195.035L180.201 195.726L178.026 196.41L175.841 197.095L173.644 197.775L171.443 198.455L169.226 199.129L167.004 199.804L164.771 200.478L162.533 201.148L160.29 201.817L158.042 202.486L155.793 203.15L153.535 203.809L151.276 204.468L149.017 205.127L146.753 205.78L144.494 206.434L142.23 207.088L139.971 207.731L137.712 208.379L135.459 209.022L133.205 209.66L130.962 210.298L128.719 210.936L126.481 211.569L124.254 212.196L122.037 212.824L119.825 213.451L117.618 214.073L115.427 214.69L113.247 215.307L111.077 215.924L108.918 216.536L106.774 217.142L104.641 217.749L102.528 218.35L100.426 218.952L98.3399 219.548L96.2745 220.144L94.2248 220.735L92.1961 221.325L90.183 221.906L88.1909 222.492L86.2196 223.072L84.2693 223.647L82.3399 224.222L80.4314 224.792L78.549 225.357L76.6928 225.922L74.8575 226.481L73.0484 227.041L71.2654 227.595L69.5085 228.144L67.7778 228.693L66.0784 229.237L64.4052 229.78L62.7634 230.319L61.1477 230.852L59.5634 231.386L58.0105 231.914L56.4889 232.437L54.9987 232.959L53.5399 233.477L52.1124 233.99L50.7216 234.502L49.3621 235.009L48.0392 235.511L46.7529 236.013L45.498 236.51L44.2797 237.001L43.098 237.493L41.9529 237.979L40.8444 238.46L39.7725 238.941L38.7373 239.417L37.7438 239.888L36.7869 240.353L35.8719 240.818L34.9882 241.278L34.1516 241.733L33.3516 242.188L32.5935 242.638L31.8719 243.082L31.1922 243.522L30.5543 243.961L29.9582 244.395L29.4039 244.824L28.8915 245.247L28.4157 245.671L27.9869 246.089L27.6 246.502L27.2497 246.915L26.9464 247.318L26.685 247.72L26.4654 248.118L26.2876 248.515L26.1516 248.902L26.0575 249.289L26.0105 249.671L26 250.047L26.0366 250.424L26.115 250.79L26.2353 251.156L26.4026 251.516L26.6065 251.877L26.8523 252.227L27.1451 252.578L27.4797 252.923L27.851 253.263L28.2693 253.597L28.7294 253.927L29.2261 254.256L29.7699 254.58L30.3556 254.899L30.9778 255.213L31.6418 255.522L32.3477 255.83L33.0954 256.128L33.8797 256.426L34.7059 256.719L35.5739 257.012L36.4784 257.294L37.4196 257.571L38.4026 257.848L39.4222 258.12L40.4837 258.387L41.5765 258.648L42.7111 258.905L43.8824 259.161L45.085 259.407L46.3294 259.652L47.6052 259.893L48.9176 260.128L50.2667 260.358L51.6471 260.583L53.0588 260.808L54.5072 261.022L55.9869 261.237L57.498 261.446L59.0405 261.644L60.6144 261.848L62.2196 262.042L63.8562 262.23L65.519 262.413L67.2078 262.596L68.9281 262.774L70.6745 262.941L72.4523 263.109L74.251 263.271L76.0758 263.427L77.9268 263.584L79.8039 263.731L81.702 263.872L83.6209 264.013L85.566 264.149L87.532 264.28L89.5137 264.4L91.5216 264.52L93.5451 264.641L95.5895 264.75L97.6497 264.855L99.7307 264.959L101.827 265.054L103.935 265.148L106.063 265.231L108.201 265.315L110.356 265.393L112.52 265.467L114.701 265.535L116.886 265.597L119.088 265.66L121.294 265.712L123.516 265.765L125.739 265.807L127.971 265.848L130.214 265.885L132.458 265.916L134.706 265.943L136.959 265.963L139.218 265.979L141.477 265.99L143.736 266H146H148.264L150.523 265.99L152.782 265.979L155.041 265.963L157.294 265.943L159.542 265.916L161.786 265.885L164.029 265.848L166.261 265.807L168.484 265.765L170.706 265.712L172.912 265.66L175.114 265.597L177.299 265.535L179.48 265.467L181.644 265.393L183.799 265.315L185.937 265.231L188.065 265.148L190.173 265.054L192.269 264.959L194.35 264.855L196.41 264.75L198.455 264.641L200.478 264.52L202.486 264.4L204.468 264.28L206.434 264.149L208.379 264.013L210.298 263.872L212.196 263.731L214.073 263.584L215.924 263.427L217.749 263.271L219.548 263.109L221.325 262.941L223.072 262.774L224.792 262.596L226.481 262.413L228.144 262.23L229.78 262.042L231.386 261.848L232.959 261.644L234.502 261.446L236.013 261.237L237.493 261.022L238.941 260.808L240.353 260.583L241.733 260.358L243.082 260.128L244.395 259.893L245.671 259.652L246.915 259.407L248.118 259.161L249.289 258.905L250.424 258.648L251.516 258.387L252.578 258.12L253.597 257.848L254.58 257.571L255.522 257.294L256.426 257.012L257.294 256.719L258.12 256.426L258.905 256.128L259.652 255.83L260.358 255.522L261.022 255.213L261.644 254.899L262.23 254.58L262.774 254.256L263.271 253.927L263.731 253.597L264.149 253.263L264.52 252.923L264.855 252.578L265.148 252.227L265.393 251.877L265.597 251.516L265.765 251.156L265.885 250.79L265.963 250.424L266 250.047L265.99 249.671L265.943 249.289L265.848 248.902L265.712 248.515L265.535 248.118L265.315 247.72L265.054 247.318L264.75 246.915L264.4 246.502L264.013 246.089L263.584 245.671L263.109 245.247L262.596 244.824L262.042 244.395L261.446 243.961L260.808 243.522L260.128 243.082L259.407 242.638L258.648 242.188L257.848 241.733L257.012 241.278L256.128 240.818L255.213 240.353L254.256 239.888L253.263 239.417L252.227 238.941L251.156 238.46L250.047 237.979L248.902 237.493L247.72 237.001L246.502 236.51L245.247 236.013L243.961 235.511L242.638 235.009L241.278 234.502L239.888 233.99L238.46 233.477L237.001 232.959L235.511 232.437L233.99 231.914L232.437 231.386L230.852 230.852L229.237 230.319L227.595 229.78L225.922 229.237L224.222 228.693L222.492 228.144L220.735 227.595L218.952 227.041L217.142 226.481L215.307 225.922L213.451 225.357L211.569 224.792L209.66 224.222L207.731 223.647L205.78 223.072L203.809 222.492L201.817 221.906L199.804 221.325L197.775 220.735L195.726 220.144L193.66 219.548L191.574 218.952L189.472 218.35L187.359 217.749L185.226 217.142L183.082 216.536L180.923 215.924L178.753 215.307L176.573 214.69L174.382 214.073L172.175 213.451L169.963 212.824L167.746 212.196L165.519 211.569L163.281 210.936L161.038 210.298L158.795 209.66L156.541 209.022L154.288 208.379L152.029 207.731L149.77 207.088L147.506 206.434L145.247 205.78L142.983 205.127L140.724 204.468L138.465 203.809L136.207 203.15L133.958 202.486L131.71 201.817L129.467 201.148L127.229 200.478L124.996 199.804L122.774 199.129L120.557 198.455L118.356 197.775L116.159 197.095L113.974 196.41L111.799 195.726L109.634 195.035L107.485 194.35L105.352 193.66L103.229 192.965L101.127 192.269L99.0353 191.574L96.9647 190.873L94.9046 190.173L92.8706 189.472L90.8523 188.771L88.8497 188.065L86.8732 187.359L84.9124 186.648L82.9778 185.937L81.0641 185.226L79.1765 184.515L77.3098 183.799L75.4641 183.082L73.6497 182.366L71.8562 181.644L70.0941 180.923L68.3529 180.201L66.6431 179.48L64.9595 178.753L63.3072 178.026L61.6811 177.299L60.0863 176.573L58.5229 175.841L56.9909 175.114L55.4902 174.382L54.0209 173.644L52.583 172.912L51.1817 172.175L49.8118 171.443L48.4784 170.706L47.1765 169.963L45.9111 169.226L44.6824 168.484L43.485 167.746L42.3294 167.004L41.2105 166.261L40.1229 165.519L39.0771 164.771L38.0732 164.029L37.1007 163.281L36.1699 162.533L35.281 161.786L34.4288 161.038L33.6131 160.29L32.8392 159.542L32.1072 158.795L31.417 158.042L30.7634 157.294L30.1516 156.541L29.5869 155.793L29.0588 155.041L28.5725 154.288L28.1281 153.535L27.7203 152.782L27.3595 152.029L27.0405 151.276L26.7686 150.523L26.5333 149.77L26.3399 149.017L26.1935 148.264L26.0837 147.506L26.0209 146.753L26 146L26.0209 145.247L26.0837 144.494L26.1935 143.736L26.3399 142.983L26.5333 142.23L26.7686 141.477L27.0405 140.724L27.3595 139.971L27.7203 139.218L28.1281 138.465L28.5725 137.712L29.0588 136.959L29.5869 136.207L30.1516 135.459L30.7634 134.706L31.417 133.958L32.1072 133.205L32.8392 132.458L33.6131 131.71L34.4288 130.962L35.281 130.214L36.1699 129.467L37.1007 128.719L38.0732 127.971L39.0771 127.229L40.1229 126.481L41.2105 125.739L42.3294 124.996L43.485 124.254L44.6824 123.516L45.9111 122.774L47.1765 122.037L48.4784 121.294L49.8118 120.557L51.1817 119.825L52.583 119.088L54.0209 118.356L55.4902 117.618L56.9909 116.886L58.5229 116.159L60.0863 115.427L61.6811 114.701L63.3072 113.974L64.9595 113.247L66.6431 112.52L68.3529 111.799L70.0941 111.077L71.8562 110.356L73.6497 109.634L75.4641 108.918L77.3098 108.201L79.1765 107.485L81.0641 106.774L82.9778 106.063L84.9124 105.352L86.8732 104.641L88.8497 103.935L90.8523 103.229L92.8706 102.528L94.9046 101.827L96.9647 101.127L99.0353 100.426L101.127 99.7307L103.229 99.0353L105.352 98.3399L107.485 97.6497L109.634 96.9647L111.799 96.2745L113.974 95.5895L116.159 94.9046L118.356 94.2248L120.557 93.5451L122.774 92.8706L124.996 92.1961L127.229 91.5216L129.467 90.8523L131.71 90.183L133.958 89.5137L136.207 88.8497L138.465 88.1909L140.724 87.532L142.983 86.8732L145.247 86.2196L147.506 85.566L149.77 84.9124L152.029 84.2693L154.288 83.6209L156.541 82.9778L158.795 82.3399L161.038 81.702L163.281 81.0641L165.519 80.4314L167.746 79.8039L169.963 79.1765L172.175 78.549L174.382 77.9268L176.573 77.3098L178.753 76.6928L180.923 76.0758L183.082 75.4641L185.226 74.8575L187.359 74.251L189.472 73.6497L191.574 73.0484L193.66 72.4523L195.726 71.8562L197.775 71.2654L199.804 70.6745L201.817 70.0941L203.809 69.5085L205.78 68.9281L207.731 68.3529L209.66 67.7778L211.569 67.2078L213.451 66.6431L215.307 66.0784L217.142 65.519L218.952 64.9595L220.735 64.4052L222.492 63.8562L224.222 63.3072L225.922 62.7634L227.595 62.2196L229.237 61.6811L230.852 61.1477L232.437 60.6144L233.99 60.0863L235.511 59.5634L237.001 59.0405L238.46 58.5229L239.888 58.0105L241.278 57.498L242.638 56.9909L243.961 56.4889L245.247 55.9869L246.502 55.4902L247.72 54.9987L248.902 54.5072L250.047 54.0209L251.156 53.5399L252.227 53.0588L253.263 52.583L254.256 52.1124L255.213 51.6471L256.128 51.1817L257.012 50.7216L257.848 50.2667L258.648 49.8118L259.407 49.3621L260.128 48.9176L260.808 48.4784L261.446 48.0392L262.042 47.6052L262.596 47.1765L263.109 46.7529L263.584 46.3294L264.013 45.9111L264.4 45.498L264.75 45.085L265.054 44.6824L265.315 44.2797L265.535 43.8824L265.712 43.485L265.848 43.098L265.943 42.7111L265.99 42.3294L266 41.9529L265.963 41.5765L265.885 41.2105L265.765 40.8444L265.597 40.4837L265.393 40.1229L265.148 39.7725L264.855 39.4222L264.52 39.0771L264.149 38.7373L263.731 38.4026L263.271 38.0732L262.774 37.7438L262.23 37.4196L261.644 37.1007L261.022 36.7869L260.358 36.4784L259.652 36.1699L258.905 35.8719L258.12 35.5739L257.294 35.281L256.426 34.9882L255.522 34.7059L254.58 34.4288L253.597 34.1516L252.578 33.8797L251.516 33.6131L250.424 33.3516L249.289 33.0954L248.118 32.8392L246.915 32.5935L245.671 32.3477L244.395 32.1072L243.082 31.8719L241.733 31.6418L240.353 31.417L238.941 31.1922L237.493 30.9778L236.013 30.7634L234.502 30.5543L232.959 30.3556L231.386 30.1516L229.78 29.9582L228.144 29.7699L226.481 29.5869L224.792 29.4039L223.072 29.2261L221.325 29.0588L219.548 28.8915L217.749 28.7294L215.924 28.5725L214.073 28.4157L212.196 28.2693L210.298 28.1281L208.379 27.9869L206.434 27.851L204.468 27.7203L202.486 27.6L200.478 27.4797L198.455 27.3595L196.41 27.2497L194.35 27.1451L192.269 27.0405L190.173 26.9464L188.065 26.8523L185.937 26.7686L183.799 26.685L181.644 26.6065L179.48 26.5333L177.299 26.4654L175.114 26.4026L172.912 26.3399L170.706 26.2876L168.484 26.2353L166.261 26.1935L164.029 26.1516L161.786 26.115L159.542 26.0837L157.294 26.0575L155.041 26.0366L152.782 26.0209L150.523 26.0105L148.264 26H146H143.736L141.477 26.0105L139.218 26.0209L136.959 26.0366L134.706 26.0575L132.458 26.0837L130.214 26.115L127.971 26.1516L125.739 26.1935L123.516 26.2353L121.294 26.2876L119.088 26.3399L116.886 26.4026L114.701 26.4654L112.52 26.5333L110.356 26.6065L108.201 26.685L106.063 26.7686L103.935 26.8523L101.827 26.9464L99.7307 27.0405L97.6497 27.1451L95.5895 27.2497L93.5451 27.3595L91.5216 27.4797L89.5137 27.6L87.532 27.7203L85.566 27.851L83.6209 27.9869L81.702 28.1281L79.8039 28.2693L77.9268 28.4157L76.0758 28.5725L74.251 28.7294L72.4523 28.8915L70.6745 29.0588L68.9281 29.2261L67.2078 29.4039L65.519 29.5869L63.8562 29.7699L62.2196 29.9582L60.6144 30.1516L59.0405 30.3556L57.498 30.5543L55.9869 30.7634L54.5072 30.9778L53.0588 31.1922L51.6471 31.417L50.2667 31.6418L48.9176 31.8719L47.6052 32.1072L46.3294 32.3477L45.085 32.5935L43.8824 32.8392L42.7111 33.0954L41.5765 33.3516L40.4837 33.6131L39.4222 33.8797L38.4026 34.1516L37.4196 34.4288L36.4784 34.7059L35.5739 34.9882L34.7059 35.281L33.8797 35.5739L33.0954 35.8719L32.3477 36.1699L31.6418 36.4784L30.9778 36.7869L30.3556 37.1007L29.7699 37.4196L29.2261 37.7438L28.7294 38.0732L28.2693 38.4026L27.851 38.7373L27.4797 39.0771L27.1451 39.4222L26.8523 39.7725L26.6065 40.1229L26.4026 40.4837L26.2353 40.8444L26.115 41.2105L26.0366 41.5765L26 41.9529L26.0105 42.3294L26.0575 42.7111L26.1516 43.098L26.2876 43.485L26.4654 43.8824L26.685 44.2797L26.9464 44.6824L27.2497 45.085L27.6 45.498L27.9869 45.9111L28.4157 46.3294L28.8915 46.7529L29.4039 47.1765L29.9582 47.6052L30.5543 48.0392L31.1922 48.4784L31.8719 48.9176L32.5935 49.3621L33.3516 49.8118L34.1516 50.2667L34.9882 50.7216L35.8719 51.1817L36.7869 51.6471L37.7438 52.1124L38.7373 52.583L39.7725 53.0588L40.8444 53.5399L41.9529 54.0209L43.098 54.5072L44.2797 54.9987L45.498 55.4902L46.7529 55.9869L48.0392 56.4889L49.3621 56.9909L50.7216 57.498L52.1124 58.0105L53.5399 58.5229L54.9987 59.0405L56.4889 59.5634L58.0105 60.0863L59.5634 60.6144L61.1477 61.1477L62.7634 61.6811L64.4052 62.2196L66.0784 62.7634L67.7778 63.3072L69.5085 63.8562L71.2654 64.4052L73.0484 64.9595L74.8575 65.519L76.6928 66.0784L78.549 66.6431L80.4314 67.2078L82.3399 67.7778L84.2693 68.3529L86.2196 68.9281L88.1909 69.5085L90.183 70.0941L92.1961 70.6745L94.2248 71.2654L96.2745 71.8562L98.3399 72.4523L100.426 73.0484L102.528 73.6497L104.641 74.251L106.774 74.8575L108.918 75.4641L111.077 76.0758L113.247 76.6928L115.427 77.3098L117.618 77.9268L119.825 78.549L122.037 79.1765L124.254 79.8039L126.481 80.4314L128.719 81.0641L130.962 81.702L133.205 82.3399L135.459 82.9778L137.712 83.6209L139.971 84.2693L142.23 84.9124L144.494 85.566L146.753 86.2196L149.017 86.8732L151.276 87.532L153.535 88.1909L155.793 88.8497L158.042 89.5137L160.29 90.183L162.533 90.8523L164.771 91.5216L167.004 92.1961L169.226 92.8706L171.443 93.5451L173.644 94.2248L175.841 94.9046L178.026 95.5895L180.201 96.2745L182.366 96.9647L184.515 97.6497L186.648 98.3399L188.771 99.0353L190.873 99.7307L192.965 100.426L195.035 101.127L197.095 101.827L199.129 102.528L201.148 103.229L203.15 103.935L205.127 104.641L207.088 105.352L209.022 106.063L210.936 106.774L212.824 107.485L214.69 108.201L216.536 108.918L218.35 109.634L220.144 110.356L221.906 111.077L223.647 111.799L225.357 112.52L227.041 113.247L228.693 113.974L230.319 114.701L231.914 115.427L233.477 116.159L235.009 116.886L236.51 117.618L237.979 118.356L239.417 119.088L240.818 119.825L242.188 120.557L243.522 121.294L244.824 122.037L246.089 122.774L247.318 123.516L248.515 124.254L249.671 124.996L250.79 125.739L251.877 126.481L252.923 127.229L253.927 127.971L254.899 128.719L255.83 129.467L256.719 130.214L257.571 130.962L258.387 131.71L259.161 132.458L259.893 133.205L260.583 133.958L261.237 134.706L261.848 135.459L262.413 136.207L262.941 136.959L263.427 137.712L263.872 138.465L264.28 139.218L264.641 139.971L264.959 140.724L265.231 141.477L265.467 142.23L265.66 142.983L265.807 143.736L265.916 144.494L265.979 145.247L266 146Z
            """
        case .arc:
            return """
            M194.81 146L192.735 150.523L190.643 155.041L188.536 159.542L186.413 164.029L184.275 168.484L182.125 172.912L179.961 177.299L177.786 181.644L175.6 185.937L173.404 190.173L171.197 194.35L168.98 198.455L166.753 202.486L164.525 206.434L162.288 210.298L160.044 214.073L157.791 217.749L155.542 221.325L153.284 224.792L151.025 228.144L148.766 231.386L146.502 234.502L144.243 237.493L141.979 240.353L139.72 243.082L137.461 245.671L135.208 248.118L132.954 250.424L130.711 252.578L128.468 254.58L126.235 256.426L124.008 258.12L121.791 259.652L119.579 261.022L117.378 262.23L115.187 263.271L113.007 264.149L110.837 264.855L108.677 265.393L106.539 265.765L104.405 265.963L102.293 265.99L100.196 265.848L98.1098 265.535L96.0444 265.054L94 264.4L91.9712 263.584L89.9582 262.596L87.9712 261.446L86 260.128L84.0497 258.648L82.1255 257.012L80.2222 255.213L78.3399 253.263L76.4837 251.156L74.6536 248.902L72.8497 246.502L71.0667 243.961L69.315 241.278L67.5895 238.46L65.8902 235.511L64.2222 232.437L62.5804 229.237L60.9699 225.922L59.3908 222.491L57.8379 218.952L56.3216 215.307L54.8314 211.569L53.3778 207.731L51.9556 203.809L50.5699 199.804L49.2157 195.725L47.8928 191.574L46.6118 187.359L45.3621 183.082L44.1438 178.753L42.9673 174.382L41.8275 169.963L40.7242 165.519L39.6575 161.038L38.6274 156.541L37.634 152.029L36.6823 147.506L35.7673 142.983L34.8941 138.465L34.0627 133.958L33.268 129.467L32.5098 124.996L31.7935 120.557L31.1242 116.159L30.4863 111.799L29.8954 107.485L29.3464 103.229L28.834 99.0353L28.3686 94.9046L27.9399 90.8523L27.5582 86.8732L27.2131 82.9778L26.915 79.1765L26.6588 75.4641L26.4444 71.8562L26.2719 68.3529L26.1412 64.9595L26.0523 61.681L26.0052 58.5229V55.4902L26.0471 52.583L26.1255 49.8118L26.251 47.1765L26.4183 44.6824L26.6327 42.3294L26.8837 40.1229L27.1817 38.0732L27.5163 36.1699L27.898 34.4288L28.3163 32.8392L28.7817 31.417L29.2889 30.1516L29.8327 29.0588L30.4183 28.1281L31.051 27.3595L31.7203 26.7686L32.4314 26.3399L33.1791 26.0837L33.9686 26L34.8 26.0837L35.6732 26.3399L36.5778 26.7686L37.5294 27.3595L38.5124 28.1281L39.5373 29.0588L40.6039 30.1516L41.702 31.417L42.8366 32.8392L44.0131 34.4288L45.2209 36.1699L46.4706 38.0732L47.7516 40.1229L49.0641 42.3294L50.4183 44.6824L51.7987 47.1765L53.2209 49.8118L54.6693 52.583L56.1542 55.4902L57.6706 58.5229L59.2131 61.681L60.7922 64.9595L62.4026 68.3529L64.0392 71.8562L65.702 75.4641L67.4013 79.1765L69.1216 82.9778L70.8732 86.8732L72.651 90.8523L74.4549 94.9046L76.2797 99.0353L78.136 103.229L80.0131 107.485L81.9111 111.799L83.8353 116.159L85.7804 120.557L87.7516 124.996L89.7386 129.467L91.7464 133.958L93.7699 138.465L95.8196 142.983L97.8797 147.506L99.9608 152.029L102.058 156.541L104.17 161.038L106.298 165.519L108.442 169.963L110.596 174.382L112.761 178.753L114.941 183.082L117.132 187.359L119.333 191.574L121.545 195.725L123.762 199.804L125.99 203.809L128.222 207.731L130.46 211.569L132.708 215.307L134.957 218.952L137.21 222.491L139.469 225.922L141.728 229.237L143.987 232.437L146.251 235.511L148.515 238.46L150.774 241.278L153.033 243.961L155.292 246.502L157.545 248.902L159.793 251.156L162.037 253.263L164.275 255.213L166.507 257.012L168.735 258.648L170.952 260.128L173.158 261.446L175.354 262.596L177.545 263.584L179.72 264.4L181.885 265.054L184.039 265.535L186.178 265.848L188.301 265.99L190.408 265.963L192.499 265.765L194.58 265.393L196.641 264.855L198.68 264.149L200.703 263.271L202.706 262.23L204.688 261.022L206.654 259.652L208.593 258.12L210.512 256.426L212.405 254.58L214.277 252.578L216.128 250.424L217.948 248.118L219.746 245.671L221.519 243.082L223.265 240.353L224.98 237.493L226.669 234.502L228.327 231.386L229.958 228.144L231.558 224.792L233.132 221.325L234.669 217.749L236.18 214.073L237.655 210.298L239.098 206.434L240.51 202.486L241.885 198.455L243.229 194.35L244.536 190.173L245.812 185.937L247.051 181.644L248.254 177.299L249.414 172.912L250.544 168.484L251.637 164.029L252.693 159.542L253.707 155.041L254.685 150.523L255.626 146L256.525 141.477L257.388 136.959L258.209 132.458L258.988 127.971L259.731 123.516L260.431 119.088L261.095 114.701L261.712 110.356L262.293 106.063L262.831 101.827L263.323 97.6497L263.778 93.5451L264.191 89.5137L264.562 85.566L264.892 81.702L265.174 77.9268L265.42 74.251L265.618 70.6745L265.78 67.2078L265.895 63.8562L265.969 60.6144L266 57.498L265.99 54.5072L265.932 51.6471L265.838 48.9176L265.697 46.3294L265.514 43.8824L265.289 41.5765L265.022 39.4222L264.714 37.4196L264.363 35.5739L263.966 33.8797L263.532 32.3477L263.056 30.9778L262.539 29.7699L261.974 28.7294L261.373 27.851L260.735 27.1451L260.05 26.6065L259.323 26.2353L258.559 26.0366L257.759 26.0105L256.912 26.1516L256.029 26.4654L255.108 26.9464L254.146 27.6L253.148 28.4157L252.112 29.4039L251.035 30.5543L249.922 31.8719L248.771 33.3516L247.59 34.9882L246.366 36.7869L245.106 38.7373L243.814 40.8444L242.486 43.098L241.127 45.498L239.731 48.0392L238.303 50.7216L236.839 53.5399L235.344 56.4889L233.817 59.5634L232.264 62.7634L230.675 66.0784L229.059 69.5085L227.412 73.0484L225.733 76.6928L224.029 80.4314L222.298 84.2693L220.536 88.1908L218.753 92.1961L216.939 96.2745L215.103 100.426L213.242 104.641L211.354 108.918L209.446 113.247L207.516 117.618L205.566 122.037L203.59 126.481L201.597 130.962L199.579 135.459L197.55 139.971L195.495 144.494L193.425 149.017L191.339 153.535L189.237 158.042L187.119 162.533L184.991 167.004L182.842 171.443L180.682 175.841L178.512 180.201L176.327 184.515L174.136 188.771L171.929 192.965L169.718 197.095L167.495 201.148L165.268 205.127L163.03 209.022L160.792 212.824L158.544 216.536L156.29 220.144L154.037 223.647L151.778 227.041L149.519 230.319L147.255 233.477L144.996 236.51L142.732 239.417L140.473 242.188L138.214 244.824L135.961 247.318L133.707 249.671L131.459 251.877L129.216 253.927L126.978 255.83L124.75 257.571L122.528 259.161L120.311 260.583L118.11 261.848L115.914 262.941L113.728 263.872L111.558 264.641L109.399 265.231L107.25 265.66L105.116 265.916L102.993 266L100.892 265.916L98.8052 265.66L96.7346 265.231L94.6797 264.641L92.6457 263.872L90.6275 262.941L88.6301 261.848L86.6536 260.583L84.698 259.161L82.7634 257.571L80.8549 255.83L78.9673 253.927L77.1007 251.877L75.2601 249.671L73.4458 247.318L71.6575 244.824L69.8954 242.188L68.1595 239.417L66.4549 236.51L64.7765 233.477L63.1242 230.319L61.5033 227.041L59.9137 223.647L58.3503 220.144L56.8235 216.536L55.3229 212.824L53.8588 209.022L52.4261 205.127L51.0301 201.148L49.6601 197.095L48.332 192.965L47.0353 188.771L45.7699 184.515L44.5464 180.201L43.3542 175.841L42.2039 171.443L41.085 167.004L40.0078 162.533L38.9673 158.042L37.9634 153.535L36.9961 149.017L36.0706 144.494L35.1817 139.971L34.3346 135.459L33.5242 130.962L32.7556 126.481L32.0288 122.037L31.3438 117.618L30.6954 113.247L30.0889 108.918L29.5242 104.641L29.0013 100.426L28.5203 96.2745L28.081 92.1961L27.6784 88.1908L27.3229 84.2693L27.0091 80.4314L26.7373 76.6928L26.5072 73.0484L26.3242 69.5085L26.1778 66.0784L26.0784 62.7634L26.0157 59.5634L26 56.4889L26.0261 53.5399L26.0941 50.7216L26.2039 48.0392L26.3608 45.498L26.5542 43.098L26.7948 40.8444L27.0771 38.7373L27.4013 36.7869L27.7673 34.9882L28.1752 33.3516L28.6248 31.8719L29.1111 30.5543L29.6444 29.4039L30.2196 28.4157L30.8366 27.6L31.4902 26.9464L32.1856 26.4654L32.9229 26.1516L33.702 26.0105L34.5176 26.0366L35.3752 26.2353L36.2745 26.6065L37.2052 27.1451L38.183 27.851L39.1922 28.7294L40.2431 29.7699L41.3307 30.9778L42.4549 32.3477L43.6157 33.8797L44.8131 35.5739L46.0471 37.4196L47.3176 39.4222L48.6248 41.5765L49.9634 43.8824L51.3333 46.3294L52.7451 48.9176L54.183 51.6471L55.6575 54.5072L57.1582 57.498L58.6954 60.6144L60.2641 63.8562L61.8588 67.2078L63.4902 70.6745L65.1477 74.251L66.8314 77.9268L68.5464 81.702L70.2876 85.566L72.0549 89.5137L73.8484 93.5451L75.668 97.6497L77.5137 101.827L79.3856 106.063L81.2784 110.356L83.1922 114.701L85.132 119.088L87.0928 123.516L89.0745 127.971L91.0719 132.458L93.0954 136.959L95.1346 141.477L97.1895 146L99.2654 150.523L101.357 155.041L103.464 159.542L105.587 164.029L107.725 168.484L109.875 172.912L112.039 177.299L114.214 181.644L116.4 185.937L118.596 190.173L120.803 194.35L123.02 198.455L125.247 202.486L127.475 206.434L129.712 210.298L131.956 214.073L134.209 217.749L136.458 221.325L138.716 224.792L140.975 228.144L143.234 231.386L145.498 234.502L147.757 237.493L150.021 240.353L152.28 243.082L154.539 245.671L156.792 248.118L159.046 250.424L161.289 252.578L163.532 254.58L165.765 256.426L167.992 258.12L170.209 259.652L172.421 261.022L174.622 262.23L176.813 263.271L178.993 264.149L181.163 264.855L183.323 265.393L185.461 265.765L187.595 265.963L189.707 265.99L191.804 265.848L193.89 265.535L195.956 265.054L198 264.4L200.029 263.584L202.042 262.596L204.029 261.446L206 260.128L207.95 258.648L209.875 257.012L211.778 255.213L213.66 253.263L215.516 251.156L217.346 248.902L219.15 246.502L220.933 243.961L222.685 241.278L224.41 238.46L226.11 235.511L227.778 232.437L229.42 229.237L231.03 225.922L232.609 222.491L234.162 218.952L235.678 215.307L237.169 211.569L238.622 207.731L240.044 203.809L241.43 199.804L242.784 195.725L244.107 191.574L245.388 187.359L246.638 183.082L247.856 178.753L249.033 174.382L250.173 169.963L251.276 165.519L252.342 161.038L253.373 156.541L254.366 152.029L255.318 147.506L256.233 142.983L257.106 138.465L257.937 133.958L258.732 129.467L259.49 124.996L260.207 120.557L260.876 116.159L261.514 111.799L262.105 107.485L262.654 103.229L263.166 99.0353L263.631 94.9046L264.06 90.8523L264.442 86.8732L264.787 82.9778L265.085 79.1765L265.341 75.4641L265.556 71.8562L265.728 68.3529L265.859 64.9595L265.948 61.681L265.995 58.5229V55.4902L265.953 52.583L265.875 49.8118L265.749 47.1765L265.582 44.6824L265.367 42.3294L265.116 40.1229L264.818 38.0732L264.484 36.1699L264.102 34.4288L263.684 32.8392L263.218 31.417L262.711 30.1516L262.167 29.0588L261.582 28.1281L260.949 27.3595L260.28 26.7686L259.569 26.3399L258.821 26.0837L258.031 26L257.2 26.0837L256.327 26.3399L255.422 26.7686L254.471 27.3595L253.488 28.1281L252.463 29.0588L251.396 30.1516L250.298 31.417L249.163 32.8392L247.987 34.4288L246.779 36.1699L245.529 38.0732L244.248 40.1229L242.936 42.3294L241.582 44.6824L240.201 47.1765L238.779 49.8118L237.331 52.583L235.846 55.4902L234.329 58.5229L232.787 61.681L231.208 64.9595L229.597 68.3529L227.961 71.8562L226.298 75.4641L224.599 79.1765L222.878 82.9778L221.127 86.8732L219.349 90.8523L217.545 94.9046L215.72 99.0353L213.864 103.229L211.987 107.485L210.089 111.799L208.165 116.159L206.22 120.557L204.248 124.996L202.261 129.467L200.254 133.958L198.23 138.465L196.18 142.983L194.12 147.506L192.039 152.029L189.942 156.541L187.83 161.038L185.702 165.519L183.558 169.963L181.404 174.382L179.239 178.753L177.059 183.082L174.868 187.359L172.667 191.574L170.455 195.725L168.238 199.804L166.01 203.809L163.778 207.731L161.54 211.569L159.291 215.307L157.043 218.952L154.79 222.491L152.531 225.922L150.272 229.237L148.013 232.437L145.749 235.511L143.485 238.46L141.226 241.278L138.967 243.961L136.708 246.502L134.455 248.902L132.207 251.156L129.963 253.263L127.725 255.213L125.493 257.012L123.265 258.648L121.048 260.128L118.842 261.446L116.646 262.596L114.455 263.584L112.28 264.4L110.115 265.054L107.961 265.535L105.822 265.848L103.699 265.99L101.592 265.963L99.5007 265.765L97.4196 265.393L95.3595 264.855L93.3203 264.149L91.2967 263.271L89.2941 262.23L87.3124 261.022L85.3464 259.652L83.4065 258.12L81.4876 256.426L79.5948 254.58L77.7229 252.578L75.8719 250.424L74.0523 248.118L72.2536 245.671L70.481 243.082L68.7346 240.353L67.0196 237.493L65.3307 234.502L63.6732 231.386L62.0418 228.144L60.4418 224.792L58.868 221.325L57.3307 217.749L55.8196 214.073L54.3451 210.298L52.902 206.434L51.4902 202.486L50.115 198.455L48.7712 194.35L47.4641 190.173L46.1882 185.937L44.949 181.644L43.7464 177.299L42.5856 172.912L41.4562 168.484L40.3634 164.029L39.3072 159.542L38.2928 155.041L37.315 150.523L36.3739 146L35.4745 141.477L34.6118 136.959L33.7908 132.458L33.0118 127.971L32.2693 123.516L31.5686 119.088L30.9046 114.701L30.2876 110.356L29.7072 106.063L29.1686 101.827L28.6771 97.6497L28.2222 93.5451L27.8092 89.5137L27.4379 85.566L27.1085 81.702L26.8261 77.9268L26.5804 74.251L26.3817 70.6745L26.2196 67.2078L26.1046 63.8562L26.0314 60.6144L26 57.498L26.0105 54.5072L26.068 51.6471L26.1621 48.9176L26.3033 46.3294L26.4863 43.8824L26.7111 41.5765L26.9778 39.4222L27.2863 37.4196L27.6366 35.5739L28.034 33.8797L28.468 32.3477L28.9438 30.9778L29.4614 29.7699L30.0261 28.7294L30.6275 27.851L31.2654 27.1451L31.9503 26.6065L32.6771 26.2353L33.4405 26.0366L34.2405 26.0105L35.0876 26.1516L35.9712 26.4654L36.8915 26.9464L37.8536 27.6L38.8523 28.4157L39.8876 29.4039L40.9647 30.5543L42.0784 31.8719L43.2288 33.3516L44.4105 34.9882L45.634 36.7869L46.8941 38.7373L48.1856 40.8444L49.5137 43.098L50.8732 45.498L52.2693 48.0392L53.6967 50.7216L55.1608 53.5399L56.6562 56.4889L58.183 59.5634L59.7359 62.7634L61.3255 66.0784L62.9412 69.5085L64.5882 73.0484L66.2667 76.6928L67.9712 80.4314L69.702 84.2693L71.4641 88.1908L73.2471 92.1961L75.0614 96.2745L76.8967 100.426L78.7582 104.641L80.6458 108.918L82.5542 113.247L84.4837 117.618L86.434 122.037L88.4105 126.481L90.4026 130.962L92.4209 135.459L94.4497 139.971L96.5046 144.494L98.5752 149.017L100.661 153.535L102.763 158.042L104.881 162.533L107.009 167.004L109.158 171.443L111.318 175.841L113.488 180.201L115.673 184.515L117.864 188.771L120.071 192.965L122.282 197.095L124.505 201.148L126.732 205.127L128.97 209.022L131.208 212.824L133.456 216.536L135.71 220.144L137.963 223.647L140.222 227.041L142.481 230.319L144.745 233.477L147.004 236.51L149.268 239.417L151.527 242.188L153.786 244.824L156.039 247.318L158.293 249.671L160.541 251.877L162.784 253.927L165.022 255.83L167.25 257.571L169.472 259.161L171.689 260.583L173.89 261.848L176.086 262.941L178.272 263.872L180.442 264.641L182.601 265.231L184.75 265.66L186.884 265.916L189.007 266L191.108 265.916L193.195 265.66L195.265 265.231L197.32 264.641L199.354 263.872L201.373 262.941L203.37 261.848L205.346 260.583L207.302 259.161L209.237 257.571L211.145 255.83L213.033 253.927L214.899 251.877L216.74 249.671L218.554 247.318L220.342 244.824L222.105 242.188L223.841 239.417L225.545 236.51L227.224 233.477L228.876 230.319L230.497 227.041L232.086 223.647L233.65 220.144L235.176 216.536L236.677 212.824L238.141 209.022L239.574 205.127L240.97 201.148L242.34 197.095L243.668 192.965L244.965 188.771L246.23 184.515L247.454 180.201L248.646 175.841L249.796 171.443L250.915 167.004L251.992 162.533L253.033 158.042L254.037 153.535L255.004 149.017L255.929 144.494L256.818 139.971L257.665 135.459L258.476 130.962L259.244 126.481L259.971 122.037L260.656 117.618L261.305 113.247L261.911 108.918L262.476 104.641L262.999 100.426L263.48 96.2745L263.919 92.1961L264.322 88.1908L264.677 84.2693L264.991 80.4314L265.263 76.6928L265.493 73.0484L265.676 69.5085L265.822 66.0784L265.922 62.7634L265.984 59.5634L266 56.4889L265.974 53.5399L265.906 50.7216L265.796 48.0392L265.639 45.498L265.446 43.098L265.205 40.8444L264.923 38.7373L264.599 36.7869L264.233 34.9882L263.825 33.3516L263.375 31.8719L262.889 30.5543L262.356 29.4039L261.78 28.4157L261.163 27.6L260.51 26.9464L259.814 26.4654L259.077 26.1516L258.298 26.0105L257.482 26.0366L256.625 26.2353L255.725 26.6065L254.795 27.1451L253.817 27.851L252.808 28.7294L251.757 29.7699L250.669 30.9778L249.545 32.3477L248.384 33.8797L247.187 35.5739L245.953 37.4196L244.682 39.4222L243.375 41.5765L242.037 43.8824L240.667 46.3294L239.255 48.9176L237.817 51.6471L236.342 54.5072L234.842 57.498L233.305 60.6144L231.736 63.8562L230.141 67.2078L228.51 70.6745L226.852 74.251L225.169 77.9268L223.454 81.702L221.712 85.566L219.945 89.5137L218.152 93.5451L216.332 97.6497L214.486 101.827L212.614 106.063L210.722 110.356L208.808 114.701L206.868 119.088L204.907 123.516L202.925 127.971L200.928 132.458L198.905 136.959L196.865 141.477L194.81 146Z
            """
        case .knot:
            return """
            M249.922 146.001L252.463 148.265L254.795 150.524L256.912 152.783L258.821 155.041L260.51 157.295L261.974 159.543L263.218 161.787L264.233 164.03L265.022 166.262L265.582 168.485L265.906 170.707L266 172.913L265.859 175.115L265.493 177.3L264.892 179.481L264.06 181.645L262.999 183.8L261.712 185.938L260.207 188.066L258.476 190.174L256.525 192.27L254.366 194.351L251.992 196.411L249.414 198.456L246.638 200.479L243.668 202.487L240.51 204.469L237.169 206.435L233.65 208.38L229.958 210.299L226.11 212.197L222.105 214.074L217.948 215.925L213.66 217.75L209.237 219.549L204.688 221.326L200.029 223.073L195.265 224.793L190.408 226.482L185.461 228.145L180.442 229.781L175.354 231.387L170.209 232.96L165.022 234.503L159.793 236.014L154.539 237.494L149.268 238.942L143.987 240.354L138.716 241.734L133.456 243.083L128.222 244.396L123.02 245.672L117.864 246.916L112.761 248.119L107.725 249.29L102.763 250.425L97.8797 251.517L93.0954 252.579L88.4105 253.598L83.8353 254.581L79.3856 255.523L75.0614 256.427L70.8732 257.295L66.8314 258.121L62.9412 258.906L59.2131 259.653L55.6575 260.359L52.2693 261.023L49.0641 261.645L46.0471 262.231L43.2288 262.775L40.6039 263.272L38.183 263.732L35.9712 264.15L33.9686 264.521L32.1856 264.856L30.6275 265.149L29.2889 265.394L28.1752 265.598L27.2863 265.766L26.6327 265.886L26.2039 265.964L26.0105 266.001L26.0523 265.991L26.3242 265.943L26.8261 265.849L27.5582 265.713L28.5203 265.536L29.7072 265.316L31.1242 265.055L32.7556 264.751L34.6118 264.401L36.6823 264.014L38.9673 263.585L41.4562 263.109L44.1438 262.597L47.0353 262.043L50.115 261.447L53.3778 260.809L56.8235 260.129L60.4418 259.408L64.2222 258.649L68.1595 257.849L72.2536 257.013L76.4837 256.129L80.8549 255.214L85.3464 254.257L89.9582 253.264L94.6797 252.228L99.5007 251.157L104.405 250.048L109.399 248.903L114.455 247.721L119.579 246.503L124.75 245.248L129.963 243.962L135.208 242.639L140.473 241.279L145.749 239.889L151.025 238.461L156.29 237.002L161.54 235.512L166.753 233.991L171.929 232.438L177.059 230.853L182.125 229.238L187.119 227.596L192.039 225.923L196.865 224.223L201.597 222.492L206.22 220.736L210.722 218.953L215.103 217.143L219.349 215.308L223.454 213.452L227.412 211.57L231.208 209.661L234.842 207.732L238.303 205.781L241.582 203.81L244.682 201.818L247.59 199.805L250.298 197.776L252.808 195.726L255.108 193.661L257.2 191.575L259.077 189.473L260.735 187.36L262.167 185.227L263.375 183.083L264.363 180.924L265.116 178.754L265.639 176.574L265.932 174.383L265.995 172.176L265.822 169.964L265.42 167.747L264.787 165.52L263.919 163.282L262.831 161.039L261.514 158.796L259.971 156.542L258.209 154.289L256.233 152.03L254.037 149.771L251.637 147.507L249.033 145.248L246.23 142.984L243.229 140.725L240.044 138.466L236.677 136.208L233.132 133.959L229.42 131.711L225.545 129.468L221.519 127.23L217.346 124.997L213.033 122.775L208.593 120.558L204.029 118.357L199.354 116.16L194.58 113.975L189.707 111.8L184.75 109.635L179.72 107.486L174.622 105.353L169.472 103.23L164.275 101.128L159.046 99.0363L153.786 96.9657L148.515 94.9056L143.234 92.8716L137.963 90.8533L132.708 88.8506L127.475 86.8742L122.282 84.9134L117.132 82.9788L112.039 81.065L107.009 79.1774L102.058 77.3108L97.1895 75.465L92.4209 73.6507L87.7516 71.8572L83.1922 70.0951L78.7582 68.3539L74.4549 66.6441L70.2876 64.9605L66.2667 63.3082L62.4026 61.682L58.6954 60.0873L55.1608 58.5239L51.7987 56.9918L48.6248 55.4912L45.634 54.0219L42.8366 52.584L40.2431 51.1827L37.8536 49.8127L35.6732 48.4794L33.702 47.1774L31.9503 45.9121L30.4183 44.6833L29.1111 43.4859L28.034 42.3304L27.1817 41.2114L26.5542 40.1238L26.1621 39.0781L26.0052 38.0742L26.0784 37.1016L26.3817 36.1709L26.915 35.282L27.6784 34.4297L28.6771 33.614L29.8954 32.8402L31.3438 32.1082L33.0118 31.418L34.8941 30.7644L36.9961 30.1526L39.3072 29.5879L41.8275 29.0598L44.5464 28.5735L47.4641 28.1291L50.5699 27.7212L53.8588 27.3605L57.3307 27.0415L60.9699 26.7696L64.7765 26.5343L68.7346 26.3408L72.8497 26.1944L77.1007 26.0846L81.4876 26.0219L86 26.001L90.6275 26.0219L95.3595 26.0846L100.196 26.1944L105.116 26.3408L110.115 26.5343L115.187 26.7696L120.311 27.0415L125.493 27.3605L130.711 27.7212L135.961 28.1291L141.226 28.5735L146.502 29.0598L151.778 29.5879L157.043 30.1526L162.288 30.7644L167.495 31.418L172.667 32.1082L177.786 32.8402L182.842 33.614L187.83 34.4297L192.735 35.282L197.55 36.1709L202.261 37.1016L206.868 38.0742L211.354 39.0781L215.72 40.1238L219.945 41.2114L224.029 42.3304L227.961 43.4859L231.736 44.6833L235.344 45.9121L238.779 47.1774L242.037 48.4794L245.106 49.8127L247.987 51.1827L250.669 52.584L253.148 54.0219L255.422 55.4912L257.482 56.9918L259.323 58.5239L260.949 60.0873L262.356 61.682L263.532 63.3082L264.484 64.9605L265.205 66.6441L265.697 68.3539L265.953 70.0951L265.984 71.8572L265.78 73.6507L265.341 75.465L264.677 77.3108L263.778 79.1774L262.654 81.065L261.305 82.9788L259.731 84.9134L257.937 86.8742L255.929 88.8506L253.707 90.8533L251.276 92.8716L248.646 94.9056L245.812 96.9657L242.784 99.0363L239.574 101.128L236.18 103.23L232.609 105.353L228.876 107.486L224.98 109.635L220.933 111.8L216.74 113.975L212.405 116.16L207.95 118.357L203.37 120.558L198.68 122.775L193.89 124.997L189.007 127.23L184.039 129.468L178.993 131.711L173.89 133.959L168.735 136.208L163.532 138.466L158.293 140.725L153.033 142.984L147.757 145.248L142.481 147.507L137.21 149.771L131.956 152.03L126.732 154.289L121.545 156.542L116.4 158.796L111.318 161.039L106.298 163.282L101.357 165.52L96.5046 167.747L91.7464 169.964L87.0928 172.176L82.5542 174.383L78.136 176.574L73.8484 178.754L69.702 180.924L65.702 183.083L61.8588 185.227L58.183 187.36L54.6693 189.473L51.3333 191.575L48.1856 193.661L45.2209 195.726L42.4549 197.776L39.8876 199.805L37.5294 201.818L35.3752 203.81L33.4405 205.781L31.7203 207.732L30.2196 209.661L28.9438 211.57L27.898 213.452L27.0771 215.308L26.4863 217.143L26.1255 218.953L26 220.736L26.1046 222.492L26.4444 224.223L27.0091 225.923L27.8092 227.596L28.834 229.238L30.0889 230.853L31.5686 232.438L33.268 233.991L35.1817 235.512L37.315 237.002L39.6575 238.461L42.2039 239.889L44.949 241.279L47.8928 242.639L51.0301 243.962L54.3451 245.248L57.8379 246.503L61.5033 247.721L65.3307 248.903L69.315 250.048L73.4458 251.157L77.7229 252.228L82.1255 253.264L86.6536 254.257L91.2967 255.214L96.0444 256.129L100.892 257.013L105.822 257.849L110.837 258.649L115.914 259.408L121.048 260.129L126.235 260.809L131.459 261.447L136.708 262.043L141.979 262.597L147.255 263.109L152.531 263.585L157.791 264.014L163.03 264.401L168.238 264.751L173.404 265.055L178.512 265.316L183.558 265.536L188.536 265.713L193.425 265.849L198.23 265.943L202.925 265.991L207.516 266.001L211.987 265.964L216.332 265.886L220.536 265.766L224.599 265.598L228.51 265.394L232.264 265.149L235.846 264.856L239.255 264.521L242.486 264.15L245.529 263.732L248.384 263.272L251.035 262.775L253.488 262.231L255.725 261.645L257.759 261.023L259.569 260.359L261.163 259.653L262.539 258.906L263.684 258.121L264.599 257.295L265.289 256.427L265.749 255.523L265.974 254.581L265.969 253.598L265.728 252.579L265.263 251.517L264.562 250.425L263.631 249.29L262.476 248.119L261.095 246.916L259.49 245.672L257.665 244.396L255.626 243.083L253.373 241.734L250.915 240.354L248.254 238.942L245.388 237.494L242.34 236.014L239.098 234.503L235.678 232.96L232.086 231.387L228.327 229.781L224.41 228.145L220.342 226.482L216.128 224.793L211.778 223.073L207.302 221.326L202.706 219.549L198 217.75L193.195 215.925L188.301 214.074L183.323 212.197L178.272 210.299L173.158 208.38L167.992 206.435L162.784 204.469L157.545 202.487L152.28 200.479L147.004 198.456L141.728 196.411L136.458 194.351L131.208 192.27L125.99 190.174L120.803 188.066L115.673 185.938L110.596 183.8L105.587 181.645L100.661 179.481L95.8196 177.3L91.0719 175.115L86.434 172.913L81.9111 170.707L77.5137 168.485L73.2471 166.262L69.1216 164.03L65.1477 161.787L61.3255 159.543L57.6706 157.295L54.183 155.041L50.8732 152.783L47.7516 150.524L44.8131 148.265L42.0784 146.001L39.5373 143.737L37.2052 141.478L35.0876 139.219L33.1791 136.96L31.4902 134.707L30.0261 132.458L28.7817 130.215L27.7673 127.972L26.9778 125.74L26.4183 123.517L26.0941 121.295L26 119.089L26.1412 116.887L26.5072 114.702L27.1085 112.521L27.9399 110.357L29.0013 108.202L30.2876 106.064L31.7935 103.936L33.5242 101.828L35.4745 99.7317L37.634 97.6506L40.0078 95.5905L42.5856 93.5461L45.3621 91.5225L48.332 89.5147L51.4902 87.533L54.8314 85.567L58.3503 83.6219L62.0418 81.7029L65.8902 79.8049L69.8954 77.9278L74.0523 76.0768L78.3399 74.252L82.7634 72.4533L87.3124 70.6755L91.9712 68.9291L96.7346 67.2088L101.592 65.5199L106.539 63.8572L111.558 62.2206L116.646 60.6154L121.791 59.0415L126.978 57.499L132.207 55.9879L137.461 54.5082L142.732 53.0598L148.013 51.648L153.284 50.2676L158.544 48.9186L163.778 47.6062L168.98 46.3304L174.136 45.0859L179.239 43.8833L184.275 42.7121L189.237 41.5774L194.12 40.4846L198.905 39.4232L203.59 38.4036L208.165 37.4206L212.614 36.4794L216.939 35.5748L221.127 34.7069L225.169 33.8807L229.059 33.0964L232.787 32.3487L236.342 31.6428L239.731 30.9788L242.936 30.3565L245.953 29.7709L248.771 29.2271L251.396 28.7304L253.817 28.2703L256.029 27.852L258.031 27.4807L259.814 27.1461L261.373 26.8533L262.711 26.6075L263.825 26.4036L264.714 26.2363L265.367 26.116L265.796 26.0376L265.99 26.001L265.948 26.0114L265.676 26.0585L265.174 26.1526L264.442 26.2886L263.48 26.4663L262.293 26.6859L260.876 26.9474L259.244 27.2506L257.388 27.601L255.318 27.9879L253.033 28.4167L250.544 28.8925L247.856 29.4049L244.965 29.9592L241.885 30.5552L238.622 31.1931L235.176 31.8729L231.558 32.5944L227.778 33.3526L223.841 34.1526L219.746 34.9892L215.516 35.8729L211.145 36.7879L206.654 37.7448L202.042 38.7382L197.32 39.7735L192.499 40.8454L187.595 41.9539L182.601 43.099L177.545 44.2807L172.421 45.499L167.25 46.7539L162.037 48.0402L156.792 49.3631L151.527 50.7225L146.251 52.1134L140.975 53.5408L135.71 54.9997L130.46 56.4899L125.247 58.0114L120.071 59.5644L114.941 61.1487L109.875 62.7644L104.881 64.4062L99.9608 66.0794L95.1346 67.7788L90.4026 69.5095L85.7804 71.2663L81.2784 73.0493L76.8967 74.8585L72.651 76.6938L68.5464 78.55L64.5882 80.4323L60.7922 82.3408L57.1582 84.2703L53.6967 86.2206L50.4183 88.1918L47.3176 90.184L44.4105 92.1971L41.702 94.2258L39.1922 96.2755L36.8915 98.3408L34.8 100.427L32.9229 102.529L31.2654 104.641L29.8327 106.775L28.6248 108.919L27.6366 111.078L26.8837 113.248L26.3608 115.428L26.068 117.619L26.0052 119.826L26.1778 122.038L26.5804 124.255L27.2131 126.482L28.081 128.72L29.1686 130.963L30.4863 133.206L32.0288 135.46L33.7908 137.713L35.7673 139.972L37.9634 142.231L40.3634 144.495L42.9673 146.754L45.7699 149.018L48.7712 151.277L51.9556 153.536L55.3229 155.794L58.868 158.043L62.5804 160.291L66.4549 162.534L70.481 164.772L74.6536 167.005L78.9673 169.227L83.4065 171.444L87.9712 173.645L92.6457 175.841L97.4196 178.027L102.293 180.202L107.25 182.367L112.28 184.516L117.378 186.649L122.528 188.772L127.725 190.874L132.954 192.966L138.214 195.036L143.485 197.096L148.766 199.13L154.037 201.149L159.291 203.151L164.525 205.128L169.718 207.089L174.868 209.023L179.961 210.937L184.991 212.824L189.942 214.691L194.81 216.537L199.579 218.351L204.248 220.145L208.808 221.907L213.242 223.648L217.545 225.358L221.712 227.041L225.733 228.694L229.597 230.32L233.305 231.915L236.839 233.478L240.201 235.01L243.375 236.511L246.366 237.98L249.163 239.418L251.757 240.819L254.146 242.189L256.327 243.523L258.298 244.825L260.05 246.09L261.582 247.319L262.889 248.516L263.966 249.672L264.818 250.791L265.446 251.878L265.838 252.924L265.995 253.928L265.922 254.9L265.618 255.831L265.085 256.72L264.322 257.572L263.323 258.388L262.105 259.162L260.656 259.894L258.988 260.584L257.106 261.238L255.004 261.849L252.693 262.414L250.173 262.942L247.454 263.428L244.536 263.873L241.43 264.281L238.141 264.641L234.669 264.96L231.03 265.232L227.224 265.468L223.265 265.661L219.15 265.808L214.899 265.917L210.512 265.98L206 266.001L201.373 265.98L196.641 265.917L191.804 265.808L186.884 265.661L181.885 265.468L176.813 265.232L171.689 264.96L166.507 264.641L161.289 264.281L156.039 263.873L150.774 263.428L145.498 262.942L140.222 262.414L134.957 261.849L129.712 261.238L124.505 260.584L119.333 259.894L114.214 259.162L109.158 258.388L104.17 257.572L99.2654 256.72L94.4497 255.831L89.7386 254.9L85.132 253.928L80.6458 252.924L76.2797 251.878L72.0549 250.791L67.9712 249.672L64.0392 248.516L60.2641 247.319L56.6562 246.09L53.2209 244.825L49.9634 243.523L46.8941 242.189L44.0131 240.819L41.3307 239.418L38.8523 237.98L36.5778 236.511L34.5176 235.01L32.6771 233.478L31.051 231.915L29.6444 230.32L28.468 228.694L27.5163 227.041L26.7948 225.358L26.3033 223.648L26.0471 221.907L26.0157 220.145L26.2196 218.351L26.6588 216.537L27.3229 214.691L28.2222 212.824L29.3464 210.937L30.6954 209.023L32.2693 207.089L34.0627 205.128L36.0706 203.151L38.2928 201.149L40.7242 199.13L43.3542 197.096L46.1882 195.036L49.2157 192.966L52.4261 190.874L55.8196 188.772L59.3908 186.649L63.1242 184.516L67.0196 182.367L71.0667 180.202L75.2601 178.027L79.5948 175.841L84.0497 173.645L88.6301 171.444L93.3203 169.227L98.1098 167.005L102.993 164.772L107.961 162.534L113.007 160.291L118.11 158.043L123.265 155.794L128.468 153.536L133.707 151.277L138.967 149.018L144.243 146.754L149.519 144.495L154.79 142.231L160.044 139.972L165.268 137.713L170.455 135.46L175.6 133.206L180.682 130.963L185.702 128.72L190.643 126.482L195.495 124.255L200.254 122.038L204.907 119.826L209.446 117.619L213.864 115.428L218.152 113.248L222.298 111.078L226.298 108.919L230.141 106.775L233.817 104.641L237.331 102.529L240.667 100.427L243.814 98.3408L246.779 96.2755L249.545 94.2258L252.112 92.1971L254.471 90.184L256.625 88.1918L258.559 86.2206L260.28 84.2703L261.78 82.3408L263.056 80.4323L264.102 78.55L264.923 76.6938L265.514 74.8585L265.875 73.0493L266 71.2663L265.895 69.5095L265.556 67.7788L264.991 66.0794L264.191 64.4062L263.166 62.7644L261.911 61.1487L260.431 59.5644L258.732 58.0114L256.818 56.4899L254.685 54.9997L252.342 53.5408L249.796 52.1134L247.051 50.7225L244.107 49.3631L240.97 48.0402L237.655 46.7539L234.162 45.499L230.497 44.2807L226.669 43.099L222.685 41.9539L218.554 40.8454L214.277 39.7735L209.875 38.7382L205.346 37.7448L200.703 36.7879L195.956 35.8729L191.108 34.9892L186.178 34.1526L181.163 33.3526L176.086 32.5944L170.952 31.8729L165.765 31.1931L160.541 30.5552L155.292 29.9592L150.021 29.4049L144.745 28.8925L139.469 28.4167L134.209 27.9879L128.97 27.601L123.762 27.2506L118.596 26.9474L113.488 26.6859L108.442 26.4663L103.464 26.2886L98.5752 26.1526L93.7699 26.0585L89.0745 26.0114L84.4837 26.001L80.0131 26.0376L75.668 26.116L71.4641 26.2363L67.4013 26.4036L63.4902 26.6075L59.7359 26.8533L56.1542 27.1461L52.7451 27.4807L49.5137 27.852L46.4706 28.2703L43.6157 28.7304L40.9647 29.2271L38.5124 29.7709L36.2745 30.3565L34.2405 30.9788L32.4314 31.6428L30.8366 32.3487L29.4614 33.0964L28.3163 33.8807L27.4013 34.7069L26.7111 35.5748L26.251 36.4794L26.0261 37.4206L26.0314 38.4036L26.2719 39.4232L26.7373 40.4846L27.4379 41.5774L28.3686 42.7121L29.5242 43.8833L30.9046 45.0859L32.5098 46.3304L34.3346 47.6062L36.3739 48.9186L38.6274 50.2676L41.085 51.648L43.7464 53.0598L46.6118 54.5082L49.6601 55.9879L52.902 57.499L56.3216 59.0415L59.9137 60.6154L63.6732 62.2206L67.5895 63.8572L71.6575 65.5199L75.8719 67.2088L80.2222 68.9291L84.698 70.6755L89.2941 72.4533L94 74.252L98.8052 76.0768L103.699 77.9278L108.677 79.8049L113.728 81.7029L118.842 83.6219L124.008 85.567L129.216 87.533L134.455 89.5147L139.72 91.5225L144.996 93.5461L150.272 95.5905L155.542 97.6506L160.792 99.7317L166.01 101.828L171.197 103.936L176.327 106.064L181.404 108.202L186.413 110.357L191.339 112.521L196.18 114.702L200.928 116.887L205.566 119.089L210.089 121.295L214.486 123.517L218.753 125.74L222.878 127.972L226.852 130.215L230.675 132.458L234.329 134.707L237.817 136.96L241.127 139.219L244.248 141.478L247.187 143.737L249.922 146.001Z
            """
        case .figure8:
            return """
            M183.082 146L182.508 146.753L181.934 147.506L181.355 148.264L180.781 149.016L180.202 149.769L179.624 150.522L179.045 151.275L178.466 152.028L177.882 152.781L177.299 153.534L176.72 154.287L176.136 155.04L175.548 155.793L174.965 156.541L174.381 157.294L173.793 158.042L173.205 158.795L172.616 159.544L172.028 160.292L171.44 161.04L170.852 161.788L170.259 162.536L169.671 163.28L169.078 164.028L168.485 164.772L167.892 165.515L167.299 166.259L166.706 167.002L166.113 167.746L165.515 168.485L164.922 169.228L164.325 169.967L163.727 170.701L163.134 171.44L162.536 172.179L161.939 172.913L161.341 173.647L160.739 174.381L160.141 175.111L159.544 175.845L158.941 176.574L158.344 177.299L157.741 178.028L157.144 178.753L156.541 179.478L155.939 180.202L155.341 180.922L154.739 181.647L154.136 182.362L153.534 183.082L152.932 183.798L152.329 184.513L151.727 185.228L151.125 185.939L150.522 186.649L149.92 187.355L149.318 188.066L148.715 188.772L148.113 189.473L147.506 190.174L146.904 190.875L146.301 191.572L145.699 192.268L145.096 192.965L144.494 193.656L143.887 194.348L143.285 195.04L142.682 195.727L142.08 196.409L141.478 197.092L140.875 197.774L140.273 198.452L139.671 199.129L139.068 199.807L138.466 200.48L137.864 201.148L137.261 201.816L136.659 202.485L136.061 203.148L135.459 203.812L134.856 204.471L134.259 205.129L133.656 205.784L133.059 206.433L132.456 207.087L131.859 207.732L131.261 208.376L130.659 209.021L130.061 209.661L129.464 210.301L128.866 210.936L128.273 211.567L127.675 212.198L127.078 212.824L126.485 213.449L125.887 214.071L125.294 214.692L124.701 215.308L124.108 215.925L123.515 216.536L122.922 217.144L122.329 217.751L121.741 218.353L121.148 218.951L120.56 219.548L119.972 220.141L119.384 220.734L118.795 221.322L118.207 221.911L117.619 222.489L117.035 223.068L116.452 223.647L115.864 224.221L115.28 224.791L114.701 225.355L114.118 225.92L113.534 226.48L112.955 227.04L112.376 227.595L111.798 228.146L111.219 228.692L110.645 229.238L110.066 229.779L109.492 230.32L108.918 230.852M183.082 146L182.508 145.247L181.934 144.494L181.355 143.736L180.781 142.984L180.202 142.231L179.624 141.478L179.045 140.725L178.466 139.972L177.882 139.219L177.299 138.466L176.72 137.713L176.136 136.96L175.548 136.207L174.965 135.459L174.381 134.706L173.793 133.958L173.205 133.205L172.616 132.456L172.028 131.708L171.44 130.96L170.852 130.212L170.259 129.464L169.671 128.72L169.078 127.972L168.485 127.228L167.892 126.485L167.299 125.741L166.706 124.998L166.113 124.254L165.515 123.515L164.922 122.772L164.325 122.033L163.727 121.299L163.134 120.56L162.536 119.821L161.939 119.087L161.341 118.353L160.739 117.619L160.141 116.889L159.544 116.155L158.941 115.426L158.344 114.701L157.741 113.972L157.144 113.247L156.541 112.522L155.939 111.798L155.341 111.078L154.739 110.353L154.136 109.638L153.534 108.918L152.932 108.202L152.329 107.487L151.727 106.772L151.125 106.061L150.522 105.351L149.92 104.645L149.318 103.934L148.715 103.228L148.113 102.527L147.506 101.826L146.904 101.125L146.301 100.428L145.699 99.7318L145.096 99.0353L144.494 98.3435L143.887 97.6518L143.285 96.96L142.682 96.2729L142.08 95.5906L141.478 94.9082L140.875 94.2259L140.273 93.5482L139.671 92.8706L139.068 92.1929L138.466 91.52L137.864 90.8518L137.261 90.1835L136.659 89.5153L136.061 88.8518L135.459 88.1882L134.856 87.5294L134.259 86.8706L133.656 86.2165L133.059 85.5671L132.456 84.9129L131.859 84.2682L131.261 83.6235L130.659 82.9788L130.061 82.3388L129.464 81.6988L128.866 81.0635L128.273 80.4329L127.675 79.8024L127.078 79.1765L126.485 78.5506L125.887 77.9294L125.294 77.3082L124.701 76.6918L124.108 76.0753L123.515 75.4635L122.922 74.8565L122.329 74.2494L121.741 73.6471L121.148 73.0494L120.56 72.4518L119.972 71.8588L119.384 71.2659L118.795 70.6776L118.207 70.0894L117.619 69.5106L117.035 68.9318L116.452 68.3529L115.864 67.7788L115.28 67.2094L114.701 66.6447L114.118 66.08L113.534 65.52L112.955 64.96L112.376 64.4047L111.798 63.8541L111.219 63.3082L110.645 62.7624L110.066 62.2212L109.492 61.68L108.918 61.1482M183.082 146L183.656 146.753L184.226 147.506L184.8 148.264L185.369 149.016L185.939 149.769L186.508 150.522L187.073 151.275L187.642 152.028L188.207 152.781L188.772 153.534L189.332 154.287L189.896 155.04L190.456 155.793L191.016 156.541L191.572 157.294L192.132 158.042L192.687 158.795L193.242 159.544L193.798 160.292L194.348 161.04L194.899 161.788L195.449 162.536L196 163.28L196.546 164.028L197.092 164.772L197.638 165.515L198.184 166.259L198.725 167.002L199.266 167.746L199.807 168.485L200.344 169.228L200.88 169.967L201.416 170.701L201.953 171.44L202.485 172.179L203.016 172.913L203.548 173.647L204.075 174.381L204.602 175.111L205.129 175.845L205.652 176.574L206.174 177.299L206.696 178.028L207.214 178.753L207.732 179.478L208.249 180.202L208.762 180.922L209.275 181.647L209.788 182.362L210.301 183.082L210.809 183.798L211.313 184.513L211.821 185.228L212.325 185.939L212.824 186.649L213.327 187.355L213.826 188.066L214.32 188.772L214.814 189.473L215.308 190.174L215.802 190.875L216.292 191.572L216.776 192.268L217.266 192.965L217.751 193.656L218.231 194.348L218.711 195.04L219.191 195.727L219.666 196.409L220.141 197.092L220.616 197.774L221.087 198.452L221.558 199.129L222.024 199.807L222.489 200.48L222.955 201.148L223.416 201.816L223.878 202.485L224.334 203.148L224.791 203.812L225.242 204.471L225.694 205.129L226.146 205.784L226.593 206.433L227.04 207.087L227.482 207.732L227.925 208.376L228.367 209.021L228.805 209.661L229.238 210.301L229.671 210.936L230.104 211.567L230.532 212.198L230.96 212.824L231.384 213.449L231.807 214.071L232.226 214.692L232.645 215.308L233.064 215.925L233.478 216.536L233.887 217.144L234.296 217.751L234.706 218.353L235.111 218.951L235.511 219.548L235.915 220.141L236.311 220.734L236.706 221.322L237.101 221.911L237.492 222.489L237.882 223.068L238.268 223.647L238.654 224.221L239.035 224.791L239.416 225.355L239.793 225.92L240.169 226.48L240.541 227.04L240.913 227.595L241.28 228.146L241.642 228.692L242.009 229.238L242.367 229.779L242.725 230.32L243.082 230.852M183.082 146L183.656 145.247L184.226 144.494L184.8 143.736L185.369 142.984L185.939 142.231L186.508 141.478L187.073 140.725L187.642 139.972L188.207 139.219L188.772 138.466L189.332 137.713L189.896 136.96L190.456 136.207L191.016 135.459L191.572 134.706L192.132 133.958L192.687 133.205L193.242 132.456L193.798 131.708L194.348 130.96L194.899 130.212L195.449 129.464L196 128.72L196.546 127.972L197.092 127.228L197.638 126.485L198.184 125.741L198.725 124.998L199.266 124.254L199.807 123.515L200.344 122.772L200.88 122.033L201.416 121.299L201.953 120.56L202.485 119.821L203.016 119.087L203.548 118.353L204.075 117.619L204.602 116.889L205.129 116.155L205.652 115.426L206.174 114.701L206.696 113.972L207.214 113.247L207.732 112.522L208.249 111.798L208.762 111.078L209.275 110.353L209.788 109.638L210.301 108.918L210.809 108.202L211.313 107.487L211.821 106.772L212.325 106.061L212.824 105.351L213.327 104.645L213.826 103.934L214.32 103.228L214.814 102.527L215.308 101.826L215.802 101.125L216.292 100.428L216.776 99.7318L217.266 99.0353L217.751 98.3435L218.231 97.6518L218.711 96.96L219.191 96.2729L219.666 95.5906L220.141 94.9082L220.616 94.2259L221.087 93.5482L221.558 92.8706L222.024 92.1929L222.489 91.52L222.955 90.8518L223.416 90.1835L223.878 89.5153L224.334 88.8518L224.791 88.1882L225.242 87.5294L225.694 86.8706L226.146 86.2165L226.593 85.5671L227.04 84.9129L227.482 84.2682L227.925 83.6235L228.367 82.9788L228.805 82.3388L229.238 81.6988L229.671 81.0635L230.104 80.4329L230.532 79.8024L230.96 79.1765L231.384 78.5506L231.807 77.9294L232.226 77.3082L232.645 76.6918L233.064 76.0753L233.478 75.4635L233.887 74.8565L234.296 74.2494L234.706 73.6471L235.111 73.0494L235.511 72.4518L235.915 71.8588L236.311 71.2659L236.706 70.6776L237.101 70.0894L237.492 69.5106L237.882 68.9318L238.268 68.3529L238.654 67.7788L239.035 67.2094L239.416 66.6447L239.793 66.08L240.169 65.52L240.541 64.96L240.913 64.4047L241.28 63.8541L241.642 63.3082L242.009 62.7624L242.367 62.2212L242.725 61.68L243.082 61.1482M108.918 230.852L108.344 231.384L107.774 231.911L107.2 232.438L106.631 232.96L106.061 233.478L105.492 233.991L104.927 234.504L104.358 235.007L103.793 235.511L103.228 236.014L102.668 236.508L102.104 237.002L101.544 237.492L100.984 237.981L100.428 238.461L99.8682 238.941L99.3129 239.416L98.7576 239.887L98.2023 240.353L97.6518 240.819L97.1012 241.28L96.5506 241.736L96 242.188L95.4541 242.635L94.9082 243.082L94.3624 243.525L93.8165 243.962L93.2753 244.395L92.7341 244.824L92.1929 245.252L91.6565 245.671L91.12 246.089L90.5835 246.504L90.0471 246.913L89.5153 247.318L88.9835 247.722L88.4518 248.118L87.9247 248.513L87.3976 248.904L86.8706 249.289L86.3482 249.671L85.8259 250.047L85.3035 250.424L84.7859 250.791L84.2682 251.158L83.7506 251.52L83.2376 251.873L82.7247 252.226L82.2118 252.574L81.6988 252.922L81.1906 253.261L80.6871 253.595L80.1788 253.929L79.6753 254.254L79.1765 254.579L78.6729 254.899L78.1741 255.214L77.68 255.525L77.1859 255.831L76.6918 256.132L76.1976 256.428L75.7082 256.72L75.2235 257.007L74.7341 257.294L74.2494 257.572L73.7694 257.849L73.2894 258.118L72.8094 258.386L72.3341 258.649L71.8588 258.904L71.3835 259.158L70.9129 259.407L70.4424 259.652L69.9765 259.892L69.5106 260.127L69.0447 260.358L68.5835 260.584L68.1223 260.805L67.6659 261.021L67.2094 261.233L66.7576 261.445L66.3059 261.647L65.8541 261.845L65.4071 262.042L64.96 262.231L64.5177 262.414L64.0753 262.598L63.6329 262.772L63.1953 262.941L62.7624 263.111L62.3294 263.271L61.8965 263.431L61.4682 263.581L61.04 263.732L60.6165 263.873L60.1929 264.014L59.7741 264.146L59.3553 264.278L58.9365 264.4L58.5224 264.522L58.1129 264.64L57.7035 264.748L57.2941 264.856L56.8894 264.955L56.4894 265.054L56.0847 265.148L55.6894 265.233L55.2941 265.318L54.8988 265.393L54.5082 265.468L54.1176 265.534L53.7318 265.6L53.3459 265.661L52.9647 265.713L52.5835 265.765L52.2071 265.807L51.8306 265.849L51.4588 265.882L51.0871 265.915L50.72 265.939L50.3576 265.962L49.9906 265.976L49.6329 265.991L49.2753 265.995L48.9176 266L48.5647 265.995L48.2118 265.991L47.8635 265.976L47.52 265.962L47.1765 265.939L46.8329 265.915L46.4988 265.882L46.16 265.849L45.8259 265.807L45.4965 265.765L45.1671 265.713L44.8424 265.661L44.5177 265.6L44.1976 265.534L43.8824 265.468L43.5671 265.393L43.2518 265.318L42.9412 265.233L42.6353 265.148L42.3294 265.054L42.0282 264.955L41.7271 264.856L41.4306 264.748L41.1341 264.64L40.8424 264.522L40.5553 264.4L40.2682 264.278L39.9812 264.146L39.7035 264.014L39.4259 263.873L39.1482 263.732L38.8753 263.581L38.6024 263.431L38.3341 263.271L38.0706 263.111L37.8071 262.941L37.5482 262.772L37.2941 262.598L37.04 262.414L36.7859 262.231L36.5365 262.042L36.2918 261.845L36.0518 261.647L35.8118 261.445L35.5718 261.233L35.3365 261.021L35.1059 260.805L34.8753 260.584L34.6494 260.358L34.4282 260.127L34.2071 259.892L33.9906 259.652L33.7741 259.407L33.5624 259.158L33.3506 258.904L33.1435 258.649L32.9412 258.386L32.7388 258.118L32.5412 257.849L32.3482 257.572L32.1553 257.294L31.9671 257.007L31.7788 256.72L31.5953 256.428L31.4165 256.132L31.2376 255.831L31.0635 255.525L30.8941 255.214L30.7247 254.899L30.5553 254.579L30.3953 254.254L30.2353 253.929L30.0753 253.595L29.92 253.261L29.7694 252.922L29.6235 252.574L29.4776 252.226L29.3318 251.873L29.1953 251.52L29.0588 251.158L28.9224 250.791L28.7906 250.424L28.6635 250.047L28.5412 249.671L28.4188 249.289L28.2965 248.904L28.1835 248.513L28.0706 248.118L27.9576 247.722L27.8541 247.318L27.7459 246.913L27.6471 246.504L27.5482 246.089L27.4541 245.671L27.36 245.252L27.2706 244.824L27.1859 244.395L27.1012 243.962L27.0212 243.525L26.9459 243.082L26.8706 242.635L26.8 242.188L26.7341 241.736L26.6682 241.28L26.6071 240.819L26.5459 240.353L26.4894 239.887L26.4376 239.416L26.3859 238.941L26.3388 238.461L26.2965 237.981L26.2541 237.492L26.2165 237.002L26.1835 236.508L26.1506 236.014L26.1224 235.511L26.0988 235.007L26.0753 234.504L26.0565 233.991L26.0376 233.478L26.0235 232.96L26.0141 232.438L26.0047 231.911L26 231.384V230.852V230.32L26.0047 229.779L26.0141 229.238L26.0235 228.692L26.0376 228.146L26.0565 227.595L26.0753 227.04L26.0988 226.48L26.1224 225.92L26.1506 225.355L26.1835 224.791L26.2165 224.221L26.2541 223.647L26.2965 223.068L26.3388 222.489L26.3859 221.911L26.4376 221.322L26.4894 220.734L26.5459 220.141L26.6071 219.548L26.6682 218.951L26.7341 218.353L26.8 217.751L26.8706 217.144L26.9459 216.536L27.0212 215.925L27.1012 215.308L27.1859 214.692L27.2706 214.071L27.36 213.449L27.4541 212.824L27.5482 212.198L27.6471 211.567L27.7459 210.936L27.8541 210.301L27.9576 209.661L28.0706 209.021L28.1835 208.376L28.2965 207.732L28.4188 207.087L28.5412 206.433L28.6635 205.784L28.7906 205.129L28.9224 204.471L29.0588 203.812L29.1953 203.148L29.3318 202.485L29.4776 201.816L29.6235 201.148L29.7694 200.48L29.92 199.807L30.0753 199.129L30.2353 198.452L30.3953 197.774L30.5553 197.092L30.7247 196.409L30.8941 195.727L31.0635 195.04L31.2376 194.348L31.4165 193.656L31.5953 192.965L31.7788 192.268L31.9671 191.572L32.1553 190.875L32.3482 190.174L32.5412 189.473L32.7388 188.772L32.9412 188.066L33.1435 187.355L33.3506 186.649L33.5624 185.939L33.7741 185.228L33.9906 184.513L34.2071 183.798L34.4282 183.082L34.6494 182.362L34.8753 181.647L35.1059 180.922L35.3365 180.202L35.5718 179.478L35.8118 178.753L36.0518 178.028L36.2918 177.299L36.5365 176.574L36.7859 175.845L37.04 175.111L37.2941 174.381L37.5482 173.647L37.8071 172.913L38.0706 172.179L38.3341 171.44L38.6024 170.701L38.8753 169.967L39.1482 169.228L39.4259 168.485L39.7035 167.746L39.9812 167.002L40.2682 166.259L40.5553 165.515L40.8424 164.772L41.1341 164.028L41.4306 163.28L41.7271 162.536L42.0282 161.788L42.3294 161.04L42.6353 160.292L42.9412 159.544L43.2518 158.795L43.5671 158.042L43.8824 157.294L44.1976 156.541L44.5177 155.793L44.8424 155.04L45.1671 154.287L45.4965 153.534L45.8259 152.781L46.16 152.028L46.4988 151.275L46.8329 150.522L47.1765 149.769L47.52 149.016L47.8635 148.264L48.2118 147.506L48.5647 146.753L48.9176 146M108.918 230.852L109.492 231.384L110.066 231.911L110.645 232.438L111.219 232.96L111.798 233.478L112.376 233.991L112.955 234.504L113.534 235.007L114.118 235.511L114.701 236.014L115.28 236.508L115.864 237.002L116.452 237.492L117.035 237.981L117.619 238.461L118.207 238.941L118.795 239.416L119.384 239.887L119.972 240.353L120.56 240.819L121.148 241.28L121.741 241.736L122.329 242.188L122.922 242.635L123.515 243.082L124.108 243.525L124.701 243.962L125.294 244.395L125.887 244.824L126.485 245.252L127.078 245.671L127.675 246.089L128.273 246.504L128.866 246.913L129.464 247.318L130.061 247.722L130.659 248.118L131.261 248.513L131.859 248.904L132.456 249.289L133.059 249.671L133.656 250.047L134.259 250.424L134.856 250.791L135.459 251.158L136.061 251.52L136.659 251.873L137.261 252.226L137.864 252.574L138.466 252.922L139.068 253.261L139.671 253.595L140.273 253.929L140.875 254.254L141.478 254.579L142.08 254.899L142.682 255.214L143.285 255.525L143.887 255.831L144.494 256.132L145.096 256.428L145.699 256.72L146.301 257.007L146.904 257.294L147.506 257.572L148.113 257.849L148.715 258.118L149.318 258.386L149.92 258.649L150.522 258.904L151.125 259.158L151.727 259.407L152.329 259.652L152.932 259.892L153.534 260.127L154.136 260.358L154.739 260.584L155.341 260.805L155.939 261.021L156.541 261.233L157.144 261.445L157.741 261.647L158.344 261.845L158.941 262.042L159.544 262.231L160.141 262.414L160.739 262.598L161.341 262.772L161.939 262.941L162.536 263.111L163.134 263.271L163.727 263.431L164.325 263.581L164.922 263.732L165.515 263.873L166.113 264.014L166.706 264.146L167.299 264.278L167.892 264.4L168.485 264.522L169.078 264.64L169.671 264.748L170.259 264.856L170.852 264.955L171.44 265.054L172.028 265.148L172.616 265.233L173.205 265.318L173.793 265.393L174.381 265.468L174.965 265.534L175.548 265.6L176.136 265.661L176.72 265.713L177.299 265.765L177.882 265.807L178.466 265.849L179.045 265.882L179.624 265.915L180.202 265.939L180.781 265.962L181.355 265.976L181.934 265.991L182.508 265.995L183.082 266L183.656 265.995L184.226 265.991L184.8 265.976L185.369 265.962L185.939 265.939L186.508 265.915L187.073 265.882L187.642 265.849L188.207 265.807L188.772 265.765L189.332 265.713L189.896 265.661L190.456 265.6L191.016 265.534L191.572 265.468L192.132 265.393L192.687 265.318L193.242 265.233L193.798 265.148L194.348 265.054L194.899 264.955L195.449 264.856L196 264.748L196.546 264.64L197.092 264.522L197.638 264.4L198.184 264.278L198.725 264.146L199.266 264.014L199.807 263.873L200.344 263.732L200.88 263.581L201.416 263.431L201.953 263.271L202.485 263.111L203.016 262.941L203.548 262.772L204.075 262.598L204.602 262.414L205.129 262.231L205.652 262.042L206.174 261.845L206.696 261.647L207.214 261.445L207.732 261.233L208.249 261.021L208.762 260.805L209.275 260.584L209.788 260.358L210.301 260.127L210.809 259.892L211.313 259.652L211.821 259.407L212.325 259.158L212.824 258.904L213.327 258.649L213.826 258.386L214.32 258.118L214.814 257.849L215.308 257.572L215.802 257.294L216.292 257.007L216.776 256.72L217.266 256.428L217.751 256.132L218.231 255.831L218.711 255.525L219.191 255.214L219.666 254.899L220.141 254.579L220.616 254.254L221.087 253.929L221.558 253.595L222.024 253.261L222.489 252.922L222.955 252.574L223.416 252.226L223.878 251.873L224.334 251.52L224.791 251.158L225.242 250.791L225.694 250.424L226.146 250.047L226.593 249.671L227.04 249.289L227.482 248.904L227.925 248.513L228.367 248.118L228.805 247.722L229.238 247.318L229.671 246.913L230.104 246.504L230.532 246.089L230.96 245.671L231.384 245.252L231.807 244.824L232.226 244.395L232.645 243.962L233.064 243.525L233.478 243.082L233.887 242.635L234.296 242.188L234.706 241.736L235.111 241.28L235.511 240.819L235.915 240.353L236.311 239.887L236.706 239.416L237.101 238.941L237.492 238.461L237.882 237.981L238.268 237.492L238.654 237.002L239.035 236.508L239.416 236.014L239.793 235.511L240.169 235.007L240.541 234.504L240.913 233.991L241.28 233.478L241.642 232.96L242.009 232.438L242.367 231.911L242.725 231.384L243.082 230.852M108.918 230.852L108.344 230.32L107.774 229.779L107.2 229.238L106.631 228.692L106.061 228.146L105.492 227.595L104.927 227.04L104.358 226.48L103.793 225.92L103.228 225.355L102.668 224.791L102.104 224.221L101.544 223.647L100.984 223.068L100.428 222.489L99.8682 221.911L99.3129 221.322L98.7576 220.734L98.2023 220.141L97.6518 219.548L97.1012 218.951L96.5506 218.353L96 217.751L95.4541 217.144L94.9082 216.536L94.3624 215.925L93.8165 215.308L93.2753 214.692L92.7341 214.071L92.1929 213.449L91.6565 212.824L91.12 212.198L90.5835 211.567L90.0471 210.936L89.5153 210.301L88.9835 209.661L88.4518 209.021L87.9247 208.376L87.3976 207.732L86.8706 207.087L86.3482 206.433L85.8259 205.784L85.3035 205.129L84.7859 204.471L84.2682 203.812L83.7506 203.148L83.2376 202.485L82.7247 201.816L82.2118 201.148L81.6988 200.48L81.1906 199.807L80.6871 199.129L80.1788 198.452L79.6753 197.774L79.1765 197.092L78.6729 196.409L78.1741 195.727L77.68 195.04L77.1859 194.348L76.6918 193.656L76.1976 192.965L75.7082 192.268L75.2235 191.572L74.7341 190.875L74.2494 190.174L73.7694 189.473L73.2894 188.772L72.8094 188.066L72.3341 187.355L71.8588 186.649L71.3835 185.939L70.9129 185.228L70.4424 184.513L69.9765 183.798L69.5106 183.082L69.0447 182.362L68.5835 181.647L68.1223 180.922L67.6659 180.202L67.2094 179.478L66.7576 178.753L66.3059 178.028L65.8541 177.299L65.4071 176.574L64.96 175.845L64.5177 175.111L64.0753 174.381L63.6329 173.647L63.1953 172.913L62.7624 172.179L62.3294 171.44L61.8965 170.701L61.4682 169.967L61.04 169.228L60.6165 168.485L60.1929 167.746L59.7741 167.002L59.3553 166.259L58.9365 165.515L58.5224 164.772L58.1129 164.028L57.7035 163.28L57.2941 162.536L56.8894 161.788L56.4894 161.04L56.0847 160.292L55.6894 159.544L55.2941 158.795L54.8988 158.042L54.5082 157.294L54.1176 156.541L53.7318 155.793L53.3459 155.04L52.9647 154.287L52.5835 153.534L52.2071 152.781L51.8306 152.028L51.4588 151.275L51.0871 150.522L50.72 149.769L50.3576 149.016L49.9906 148.264L49.6329 147.506L49.2753 146.753L48.9176 146M48.9176 146L49.2753 145.247L49.6329 144.494L49.9906 143.736L50.3576 142.984L50.72 142.231L51.0871 141.478L51.4588 140.725L51.8306 139.972L52.2071 139.219L52.5835 138.466L52.9647 137.713L53.3459 136.96L53.7318 136.207L54.1176 135.459L54.5082 134.706L54.8988 133.958L55.2941 133.205L55.6894 132.456L56.0847 131.708L56.4894 130.96L56.8894 130.212L57.2941 129.464L57.7035 128.72L58.1129 127.972L58.5224 127.228L58.9365 126.485L59.3553 125.741L59.7741 124.998L60.1929 124.254L60.6165 123.515L61.04 122.772L61.4682 122.033L61.8965 121.299L62.3294 120.56L62.7624 119.821L63.1953 119.087L63.6329 118.353L64.0753 117.619L64.5177 116.889L64.96 116.155L65.4071 115.426L65.8541 114.701L66.3059 113.972L66.7576 113.247L67.2094 112.522L67.6659 111.798L68.1223 111.078L68.5835 110.353L69.0447 109.638L69.5106 108.918L69.9765 108.202L70.4424 107.487L70.9129 106.772L71.3835 106.061L71.8588 105.351L72.3341 104.645L72.8094 103.934L73.2894 103.228L73.7694 102.527L74.2494 101.826L74.7341 101.125L75.2235 100.428L75.7082 99.7318L76.1976 99.0353L76.6918 98.3435L77.1859 97.6518L77.68 96.96L78.1741 96.2729L78.6729 95.5906L79.1765 94.9082L79.6753 94.2259L80.1788 93.5482L80.6871 92.8706L81.1906 92.1929L81.6988 91.52L82.2118 90.8518L82.7247 90.1835L83.2376 89.5153L83.7506 88.8518L84.2682 88.1882L84.7859 87.5294L85.3035 86.8706L85.8259 86.2165L86.3482 85.5671L86.8706 84.9129L87.3976 84.2682L87.9247 83.6235L88.4518 82.9788L88.9835 82.3388L89.5153 81.6988L90.0471 81.0635L90.5835 80.4329L91.12 79.8024L91.6565 79.1765L92.1929 78.5506L92.7341 77.9294L93.2753 77.3082L93.8165 76.6918L94.3624 76.0753L94.9082 75.4635L95.4541 74.8565L96 74.2494L96.5506 73.6471L97.1012 73.0494L97.6518 72.4518L98.2023 71.8588L98.7576 71.2659L99.3129 70.6776L99.8682 70.0894L100.428 69.5106L100.984 68.9318L101.544 68.3529L102.104 67.7788L102.668 67.2094L103.228 66.6447L103.793 66.08L104.358 65.52L104.927 64.96L105.492 64.4047L106.061 63.8541L106.631 63.3082L107.2 62.7624L107.774 62.2212L108.344 61.68L108.918 61.1482M48.9176 146L48.5647 145.247L48.2118 144.494L47.8635 143.736L47.52 142.984L47.1765 142.231L46.8329 141.478L46.4988 140.725L46.16 139.972L45.8259 139.219L45.4965 138.466L45.1671 137.713L44.8424 136.96L44.5177 136.207L44.1976 135.459L43.8824 134.706L43.5671 133.958L43.2518 133.205L42.9412 132.456L42.6353 131.708L42.3294 130.96L42.0282 130.212L41.7271 129.464L41.4306 128.72L41.1341 127.972L40.8424 127.228L40.5553 126.485L40.2682 125.741L39.9812 124.998L39.7035 124.254L39.4259 123.515L39.1482 122.772L38.8753 122.033L38.6024 121.299L38.3341 120.56L38.0706 119.821L37.8071 119.087L37.5482 118.353L37.2941 117.619L37.04 116.889L36.7859 116.155L36.5365 115.426L36.2918 114.701L36.0518 113.972L35.8118 113.247L35.5718 112.522L35.3365 111.798L35.1059 111.078L34.8753 110.353L34.6494 109.638L34.4282 108.918L34.2071 108.202L33.9906 107.487L33.7741 106.772L33.5624 106.061L33.3506 105.351L33.1435 104.645L32.9412 103.934L32.7388 103.228L32.5412 102.527L32.3482 101.826L32.1553 101.125L31.9671 100.428L31.7788 99.7318L31.5953 99.0353L31.4165 98.3435L31.2376 97.6518L31.0635 96.96L30.8941 96.2729L30.7247 95.5906L30.5553 94.9082L30.3953 94.2259L30.2353 93.5482L30.0753 92.8706L29.92 92.1929L29.7694 91.52L29.6235 90.8518L29.4776 90.1835L29.3318 89.5153L29.1953 88.8518L29.0588 88.1882L28.9224 87.5294L28.7906 86.8706L28.6635 86.2165L28.5412 85.5671L28.4188 84.9129L28.2965 84.2682L28.1835 83.6235L28.0706 82.9788L27.9576 82.3388L27.8541 81.6988L27.7459 81.0635L27.6471 80.4329L27.5482 79.8024L27.4541 79.1765L27.36 78.5506L27.2706 77.9294L27.1859 77.3082L27.1012 76.6918L27.0212 76.0753L26.9459 75.4635L26.8706 74.8565L26.8 74.2494L26.7341 73.6471L26.6682 73.0494L26.6071 72.4518L26.5459 71.8588L26.4894 71.2659L26.4376 70.6776L26.3859 70.0894L26.3388 69.5106L26.2965 68.9318L26.2541 68.3529L26.2165 67.7788L26.1835 67.2094L26.1506 66.6447L26.1224 66.08L26.0988 65.52L26.0753 64.96L26.0565 64.4047L26.0376 63.8541L26.0235 63.3082L26.0141 62.7624L26.0047 62.2212L26 61.68V61.1482V60.6165L26.0047 60.0894L26.0141 59.5624L26.0235 59.04L26.0376 58.5224L26.0565 58.0094L26.0753 57.4965L26.0988 56.9929L26.1224 56.4894L26.1506 55.9859L26.1835 55.4918L26.2165 54.9976L26.2541 54.5082L26.2965 54.0188L26.3388 53.5388L26.3859 53.0588L26.4376 52.5835L26.4894 52.1129L26.5459 51.6471L26.6071 51.1812L26.6682 50.72L26.7341 50.2635L26.8 49.8118L26.8706 49.3647L26.9459 48.9176L27.0212 48.4753L27.1012 48.0376L27.1859 47.6047L27.2706 47.1765L27.36 46.7482L27.4541 46.3294L27.5482 45.9106L27.6471 45.4965L27.7459 45.0871L27.8541 44.6824L27.9576 44.2776L28.0706 43.8824L28.1835 43.4871L28.2965 43.0965L28.4188 42.7106L28.5412 42.3294L28.6635 41.9529L28.7906 41.5765L28.9224 41.2094L29.0588 40.8424L29.1953 40.48L29.3318 40.1271L29.4776 39.7741L29.6235 39.4259L29.7694 39.0776L29.92 38.7388L30.0753 38.4047L30.2353 38.0706L30.3953 37.7459L30.5553 37.4212L30.7247 37.1012L30.8941 36.7859L31.0635 36.4753L31.2376 36.1694L31.4165 35.8682L31.5953 35.5718L31.7788 35.28L31.9671 34.9929L32.1553 34.7059L32.3482 34.4282L32.5412 34.1506L32.7388 33.8824L32.9412 33.6141L33.1435 33.3506L33.3506 33.0965L33.5624 32.8424L33.7741 32.5929L33.9906 32.3482L34.2071 32.1082L34.4282 31.8729L34.6494 31.6424L34.8753 31.4165L35.1059 31.1953L35.3365 30.9788L35.5718 30.7671L35.8118 30.5553L36.0518 30.3529L36.2918 30.1553L36.5365 29.9576L36.7859 29.7694L37.04 29.5859L37.2941 29.4024L37.5482 29.2282L37.8071 29.0588L38.0706 28.8894L38.3341 28.7294L38.6024 28.5694L38.8753 28.4188L39.1482 28.2682L39.4259 28.1271L39.7035 27.9859L39.9812 27.8541L40.2682 27.7224L40.5553 27.6L40.8424 27.4776L41.1341 27.36L41.4306 27.2518L41.7271 27.1435L42.0282 27.0447L42.3294 26.9459L42.6353 26.8518L42.9412 26.7671L43.2518 26.6824L43.5671 26.6071L43.8824 26.5318L44.1976 26.4659L44.5177 26.4L44.8424 26.3388L45.1671 26.2871L45.4965 26.2353L45.8259 26.1929L46.16 26.1506L46.4988 26.1176L46.8329 26.0847L47.1765 26.0612L47.52 26.0376L47.8635 26.0235L48.2118 26.0094L48.5647 26.0047L48.9176 26L49.2753 26.0047L49.6329 26.0094L49.9906 26.0235L50.3576 26.0376L50.72 26.0612L51.0871 26.0847L51.4588 26.1176L51.8306 26.1506L52.2071 26.1929L52.5835 26.2353L52.9647 26.2871L53.3459 26.3388L53.7318 26.4L54.1176 26.4659L54.5082 26.5318L54.8988 26.6071L55.2941 26.6824L55.6894 26.7671L56.0847 26.8518L56.4894 26.9459L56.8894 27.0447L57.2941 27.1435L57.7035 27.2518L58.1129 27.36L58.5224 27.4776L58.9365 27.6L59.3553 27.7224L59.7741 27.8541L60.1929 27.9859L60.6165 28.1271L61.04 28.2682L61.4682 28.4188L61.8965 28.5694L62.3294 28.7294L62.7624 28.8894L63.1953 29.0588L63.6329 29.2282L64.0753 29.4024L64.5177 29.5859L64.96 29.7694L65.4071 29.9576L65.8541 30.1553L66.3059 30.3529L66.7576 30.5553L67.2094 30.7671L67.6659 30.9788L68.1223 31.1953L68.5835 31.4165L69.0447 31.6424L69.5106 31.8729L69.9765 32.1082L70.4424 32.3482L70.9129 32.5929L71.3835 32.8424L71.8588 33.0965L72.3341 33.3506L72.8094 33.6141L73.2894 33.8824L73.7694 34.1506L74.2494 34.4282L74.7341 34.7059L75.2235 34.9929L75.7082 35.28L76.1976 35.5718L76.6918 35.8682L77.1859 36.1694L77.68 36.4753L78.1741 36.7859L78.6729 37.1012L79.1765 37.4212L79.6753 37.7459L80.1788 38.0706L80.6871 38.4047L81.1906 38.7388L81.6988 39.0776L82.2118 39.4259L82.7247 39.7741L83.2376 40.1271L83.7506 40.48L84.2682 40.8424L84.7859 41.2094L85.3035 41.5765L85.8259 41.9529L86.3482 42.3294L86.8706 42.7106L87.3976 43.0965L87.9247 43.4871L88.4518 43.8824L88.9835 44.2776L89.5153 44.6824L90.0471 45.0871L90.5835 45.4965L91.12 45.9106L91.6565 46.3294L92.1929 46.7482L92.7341 47.1765L93.2753 47.6047L93.8165 48.0376L94.3624 48.4753L94.9082 48.9176L95.4541 49.3647L96 49.8118L96.5506 50.2635L97.1012 50.72L97.6518 51.1812L98.2023 51.6471L98.7576 52.1129L99.3129 52.5835L99.8682 53.0588L100.428 53.5388L100.984 54.0188L101.544 54.5082L102.104 54.9976L102.668 55.4918L103.228 55.9859L103.793 56.4894L104.358 56.9929L104.927 57.4965L105.492 58.0094L106.061 58.5224L106.631 59.04L107.2 59.5624L107.774 60.0894L108.344 60.6165L108.918 61.1482M108.918 61.1482L109.492 60.6165L110.066 60.0894L110.645 59.5624L111.219 59.04L111.798 58.5224L112.376 58.0094L112.955 57.4965L113.534 56.9929L114.118 56.4894L114.701 55.9859L115.28 55.4918L115.864 54.9976L116.452 54.5082L117.035 54.0188L117.619 53.5388L118.207 53.0588L118.795 52.5835L119.384 52.1129L119.972 51.6471L120.56 51.1812L121.148 50.72L121.741 50.2635L122.329 49.8118L122.922 49.3647L123.515 48.9176L124.108 48.4753L124.701 48.0376L125.294 47.6047L125.887 47.1765L126.485 46.7482L127.078 46.3294L127.675 45.9106L128.273 45.4965L128.866 45.0871L129.464 44.6824L130.061 44.2776L130.659 43.8824L131.261 43.4871L131.859 43.0965L132.456 42.7106L133.059 42.3294L133.656 41.9529L134.259 41.5765L134.856 41.2094L135.459 40.8424L136.061 40.48L136.659 40.1271L137.261 39.7741L137.864 39.4259L138.466 39.0776L139.068 38.7388L139.671 38.4047L140.273 38.0706L140.875 37.7459L141.478 37.4212L142.08 37.1012L142.682 36.7859L143.285 36.4753L143.887 36.1694L144.494 35.8682L145.096 35.5718L145.699 35.28L146.301 34.9929L146.904 34.7059L147.506 34.4282L148.113 34.1506L148.715 33.8824L149.318 33.6141L149.92 33.3506L150.522 33.0965L151.125 32.8424L151.727 32.5929L152.329 32.3482L152.932 32.1082L153.534 31.8729L154.136 31.6424L154.739 31.4165L155.341 31.1953L155.939 30.9788L156.541 30.7671L157.144 30.5553L157.741 30.3529L158.344 30.1553L158.941 29.9576L159.544 29.7694L160.141 29.5859L160.739 29.4024L161.341 29.2282L161.939 29.0588L162.536 28.8894L163.134 28.7294L163.727 28.5694L164.325 28.4188L164.922 28.2682L165.515 28.1271L166.113 27.9859L166.706 27.8541L167.299 27.7224L167.892 27.6L168.485 27.4776L169.078 27.36L169.671 27.2518L170.259 27.1435L170.852 27.0447L171.44 26.9459L172.028 26.8518L172.616 26.7671L173.205 26.6824L173.793 26.6071L174.381 26.5318L174.965 26.4659L175.548 26.4L176.136 26.3388L176.72 26.2871L177.299 26.2353L177.882 26.1929L178.466 26.1506L179.045 26.1176L179.624 26.0847L180.202 26.0612L180.781 26.0376L181.355 26.0235L181.934 26.0094L182.508 26.0047L183.082 26L183.656 26.0047L184.226 26.0094L184.8 26.0235L185.369 26.0376L185.939 26.0612L186.508 26.0847L187.073 26.1176L187.642 26.1506L188.207 26.1929L188.772 26.2353L189.332 26.2871L189.896 26.3388L190.456 26.4L191.016 26.4659L191.572 26.5318L192.132 26.6071L192.687 26.6824L193.242 26.7671L193.798 26.8518L194.348 26.9459L194.899 27.0447L195.449 27.1435L196 27.2518L196.546 27.36L197.092 27.4776L197.638 27.6L198.184 27.7224L198.725 27.8541L199.266 27.9859L199.807 28.1271L200.344 28.2682L200.88 28.4188L201.416 28.5694L201.953 28.7294L202.485 28.8894L203.016 29.0588L203.548 29.2282L204.075 29.4024L204.602 29.5859L205.129 29.7694L205.652 29.9576L206.174 30.1553L206.696 30.3529L207.214 30.5553L207.732 30.7671L208.249 30.9788L208.762 31.1953L209.275 31.4165L209.788 31.6424L210.301 31.8729L210.809 32.1082L211.313 32.3482L211.821 32.5929L212.325 32.8424L212.824 33.0965L213.327 33.3506L213.826 33.6141L214.32 33.8824L214.814 34.1506L215.308 34.4282L215.802 34.7059L216.292 34.9929L216.776 35.28L217.266 35.5718L217.751 35.8682L218.231 36.1694L218.711 36.4753L219.191 36.7859L219.666 37.1012L220.141 37.4212L220.616 37.7459L221.087 38.0706L221.558 38.4047L222.024 38.7388L222.489 39.0776L222.955 39.4259L223.416 39.7741L223.878 40.1271L224.334 40.48L224.791 40.8424L225.242 41.2094L225.694 41.5765L226.146 41.9529L226.593 42.3294L227.04 42.7106L227.482 43.0965L227.925 43.4871L228.367 43.8824L228.805 44.2776L229.238 44.6824L229.671 45.0871L230.104 45.4965L230.532 45.9106L230.96 46.3294L231.384 46.7482L231.807 47.1765L232.226 47.6047L232.645 48.0376L233.064 48.4753L233.478 48.9176L233.887 49.3647L234.296 49.8118L234.706 50.2635L235.111 50.72L235.511 51.1812L235.915 51.6471L236.311 52.1129L236.706 52.5835L237.101 53.0588L237.492 53.5388L237.882 54.0188L238.268 54.5082L238.654 54.9976L239.035 55.4918L239.416 55.9859L239.793 56.4894L240.169 56.9929L240.541 57.4965L240.913 58.0094L241.28 58.5224L241.642 59.04L242.009 59.5624L242.367 60.0894L242.725 60.6165L243.082 61.1482M243.082 61.1482L243.435 60.6165L243.788 60.0894L244.136 59.5624L244.48 59.04L244.824 58.5224L245.167 58.0094L245.501 57.4965L245.84 56.9929L246.174 56.4894L246.504 55.9859L246.833 55.4918L247.158 54.9976L247.482 54.5082L247.802 54.0188L248.118 53.5388L248.433 53.0588L248.748 52.5835L249.059 52.1129L249.365 51.6471L249.671 51.1812L249.972 50.72L250.273 50.2635L250.569 49.8118L250.866 49.3647L251.158 48.9176L251.445 48.4753L251.732 48.0376L252.019 47.6047L252.296 47.1765L252.574 46.7482L252.852 46.3294L253.125 45.9106L253.398 45.4965L253.666 45.0871L253.929 44.6824L254.193 44.2776L254.452 43.8824L254.706 43.4871L254.96 43.0965L255.214 42.7106L255.464 42.3294L255.708 41.9529L255.948 41.5765L256.188 41.2094L256.428 40.8424L256.664 40.48L256.894 40.1271L257.125 39.7741L257.351 39.4259L257.572 39.0776L257.793 38.7388L258.009 38.4047L258.226 38.0706L258.438 37.7459L258.649 37.4212L258.856 37.1012L259.059 36.7859L259.261 36.4753L259.459 36.1694L259.652 35.8682L259.845 35.5718L260.033 35.28L260.221 34.9929L260.405 34.7059L260.584 34.4282L260.762 34.1506L260.936 33.8824L261.106 33.6141L261.275 33.3506L261.445 33.0965L261.605 32.8424L261.765 32.5929L261.925 32.3482L262.08 32.1082L262.231 31.8729L262.376 31.6424L262.522 31.4165L262.668 31.1953L262.805 30.9788L262.941 30.7671L263.078 30.5553L263.209 30.3529L263.336 30.1553L263.459 29.9576L263.581 29.7694L263.704 29.5859L263.816 29.4024L263.929 29.2282L264.042 29.0588L264.146 28.8894L264.254 28.7294L264.353 28.5694L264.452 28.4188L264.546 28.2682L264.64 28.1271L264.729 27.9859L264.814 27.8541L264.899 27.7224L264.979 27.6L265.054 27.4776L265.129 27.36L265.2 27.2518L265.266 27.1435L265.332 27.0447L265.393 26.9459L265.454 26.8518L265.511 26.7671L265.562 26.6824L265.614 26.6071L265.661 26.5318L265.704 26.4659L265.746 26.4L265.784 26.3388L265.816 26.2871L265.849 26.2353L265.878 26.1929L265.901 26.1506L265.925 26.1176L265.944 26.0847L265.962 26.0612L265.976 26.0376L265.986 26.0235L265.995 26.0094L266 26.0047V26M243.082 230.852L243.435 231.384L243.788 231.911L244.136 232.438L244.48 232.96L244.824 233.478L245.167 233.991L245.501 234.504L245.84 235.007L246.174 235.511L246.504 236.014L246.833 236.508L247.158 237.002L247.482 237.492L247.802 237.981L248.118 238.461L248.433 238.941L248.748 239.416L249.059 239.887L249.365 240.353L249.671 240.819L249.972 241.28L250.273 241.736L250.569 242.188L250.866 242.635L251.158 243.082L251.445 243.525L251.732 243.962L252.019 244.395L252.296 244.824L252.574 245.252L252.852 245.671L253.125 246.089L253.398 246.504L253.666 246.913L253.929 247.318L254.193 247.722L254.452 248.118L254.706 248.513L254.96 248.904L255.214 249.289L255.464 249.671L255.708 250.047L255.948 250.424L256.188 250.791L256.428 251.158L256.664 251.52L256.894 251.873L257.125 252.226L257.351 252.574L257.572 252.922L257.793 253.261L258.009 253.595L258.226 253.929L258.438 254.254L258.649 254.579L258.856 254.899L259.059 255.214L259.261 255.525L259.459 255.831L259.652 256.132L259.845 256.428L260.033 256.72L260.221 257.007L260.405 257.294L260.584 257.572L260.762 257.849L260.936 258.118L261.106 258.386L261.275 258.649L261.445 258.904L261.605 259.158L261.765 259.407L261.925 259.652L262.08 259.892L262.231 260.127L262.376 260.358L262.522 260.584L262.668 260.805L262.805 261.021L262.941 261.233L263.078 261.445L263.209 261.647L263.336 261.845L263.459 262.042L263.581 262.231L263.704 262.414L263.816 262.598L263.929 262.772L264.042 262.941L264.146 263.111L264.254 263.271L264.353 263.431L264.452 263.581L264.546 263.732L264.64 263.873L264.729 264.014L264.814 264.146L264.899 264.278L264.979 264.4L265.054 264.522L265.129 264.64L265.2 264.748L265.266 264.856L265.332 264.955L265.393 265.054L265.454 265.148L265.511 265.233L265.562 265.318L265.614 265.393L265.661 265.468L265.704 265.534L265.746 265.6L265.784 265.661L265.816 265.713L265.849 265.765L265.878 265.807L265.901 265.849L265.925 265.882L265.944 265.915L265.962 265.939L265.976 265.962L265.986 265.976L265.995 265.991L266 265.995V266
            """
        case .infinity:
            return """
            M146 146L158.043 149.017L169.965 152.029L181.648 155.041L192.969 158.043L203.814 161.039L214.079 164.03L223.654 167.006L232.444 169.965L240.361 172.915L247.326 175.843L253.272 178.756L258.13 181.648L261.858 184.518L264.41 187.363L265.775 190.176L265.927 192.969L264.865 195.73L262.606 198.459L259.171 201.153L254.59 203.814L248.911 206.439L242.197 209.028L234.51 211.574L225.929 214.079L216.542 216.542L206.439 218.958L195.73 221.332L184.518 223.654L172.915 225.929L161.039 228.151L149.017 230.326L136.959 232.444L124.994 234.51L113.244 236.518L101.824 238.468L90.8475 240.361L80.4257 242.197L70.6679 243.969L61.6737 245.679L53.5318 247.326L46.3207 248.911L40.1136 250.433L34.9786 251.886L30.9678 253.272L28.1178 254.59L26.4549 255.84L26 257.021L26.7582 258.13L28.7192 259.171L31.8619 260.138L36.1604 261.032L41.5674 261.858L48.0307 262.606L55.4823 263.281L63.849 263.882L73.042 264.41L82.9723 264.865L93.5405 265.242L104.637 265.545L116.157 265.775L127.97 265.927L139.971 266H152.029L164.03 265.927L175.843 265.775L187.363 265.545L198.459 265.242L209.028 264.865L218.958 264.41L228.151 263.882L236.518 263.281L243.969 262.606L250.433 261.858L255.84 261.032L260.138 260.138L263.281 259.171L265.242 258.13L266 257.021L265.545 255.84L263.882 254.59L261.032 253.272L257.021 251.886L251.886 250.433L245.679 248.911L238.468 247.326L230.326 245.679L221.332 243.969L211.574 242.197L201.153 240.361L190.176 238.468L178.756 236.518L167.006 234.51L155.041 232.444L142.983 230.326L130.961 228.151L119.085 225.929L107.482 223.654L96.2702 221.332L85.5607 218.958L75.4579 216.542L66.0715 214.079L57.4903 211.574L49.8034 209.028L43.0891 206.439L37.4101 203.814L32.8294 201.153L29.3938 198.459L27.1347 195.73L26.0732 192.969L26.2249 190.176L27.5897 187.363L30.1415 184.518L33.87 181.648L38.7279 178.756L44.6735 175.843L51.6388 172.915L59.5559 169.965L68.3462 167.006L77.9209 164.03L88.1858 161.039L99.0312 158.043L110.352 155.041L122.035 152.029L133.957 149.017L146 146ZM146 146L158.043 142.983L169.965 139.971L181.648 136.959L192.969 133.957L203.814 130.961L214.079 127.97L223.654 124.994L232.444 122.035L240.361 119.085L247.326 116.157L253.272 113.244L258.13 110.352L261.858 107.482L264.41 104.637L265.775 101.824L265.927 99.0312L264.865 96.2702L262.606 93.5405L259.171 90.8475L254.59 88.1858L248.911 85.5607L242.197 82.9723L234.51 80.4257L225.929 77.9209L216.542 75.4579L206.439 73.042L195.73 70.6679L184.518 68.3462L172.915 66.0715L161.039 63.849L149.017 61.6737L136.959 59.5559L124.994 57.4903L113.244 55.4823L101.824 53.5318L90.8475 51.6388L80.4257 49.8034L70.6679 48.0307L61.6737 46.3207L53.5318 44.6735L46.3207 43.0891L40.1136 41.5674L34.9786 40.1136L30.9678 38.7279L28.1178 37.4101L26.4549 36.1604L26 34.9786L26.7582 33.87L28.7192 32.8294L31.8619 31.8619L36.1604 30.9678L41.5674 30.1415L48.0307 29.3938L55.4823 28.7192L63.849 28.1178L73.042 27.5897L82.9723 27.1347L93.5405 26.7582L104.637 26.4549L116.157 26.2249L127.97 26.0732L139.971 26H152.029L164.03 26.0732L175.843 26.2249L187.363 26.4549L198.459 26.7582L209.028 27.1347L218.958 27.5897L228.151 28.1178L236.518 28.7192L243.969 29.3938L250.433 30.1415L255.84 30.9678L260.138 31.8619L263.281 32.8294L265.242 33.87L266 34.9786L265.545 36.1604L263.882 37.4101L261.032 38.7279L257.021 40.1136L251.886 41.5674L245.679 43.0891L238.468 44.6735L230.326 46.3207L221.332 48.0307L211.574 49.8034L201.153 51.6388L190.176 53.5318L178.756 55.4823L167.006 57.4903L155.041 59.5559L142.983 61.6737L130.961 63.849L119.085 66.0715L107.482 68.3462L96.2702 70.6679L85.5607 73.042L75.4579 75.4579L66.0715 77.9209L57.4903 80.4257L49.8034 82.9723L43.0891 85.5607L37.4101 88.1858L32.8294 90.8475L29.3938 93.5405L27.1347 96.2702L26.0732 99.0312L26.2249 101.824L27.5897 104.637L30.1415 107.482L33.87 110.352L38.7279 113.244L44.6735 116.157L51.6388 119.085L59.5559 122.035L68.3462 124.994L77.9209 127.97L88.1858 130.961L99.0312 133.957L110.352 136.959L122.035 139.971L133.957 142.983L146 146Z
            """
        }
    }
}

private final class RunnerSVGPathCache {
    static let shared = RunnerSVGPathCache()

    private var cache: [String: Path] = [:]

    func path(for data: String) -> Path {
        if let cached = cache[data] {
            return cached
        }

        let parsed = RunnerSVGPathParser.parse(data)
        cache[data] = parsed
        return parsed
    }
}

private enum RunnerSVGPathParser {
    private static let tokenPattern = try! NSRegularExpression(
        pattern: #"[MLZmlz]|-?\d*\.?\d+(?:e[-+]?\d+)?"#
    )

    static func parse(_ data: String) -> Path {
        let nsRange = NSRange(data.startIndex..<data.endIndex, in: data)
        let tokens = tokenPattern.matches(in: data, range: nsRange).compactMap {
            Range($0.range, in: data).map { String(data[$0]) }
        }

        let path = CGMutablePath()
        var index = 0
        var command: Character = "M"
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero

        func nextNumber() -> CGFloat? {
            guard index < tokens.count else { return nil }
            let token = tokens[index]
            guard let value = Double(token) else { return nil }
            index += 1
            return CGFloat(value)
        }

        while index < tokens.count {
            let token = tokens[index]
            if token.count == 1, let letter = token.first, letter.isLetter {
                command = letter
                index += 1

                if letter == "Z" || letter == "z" {
                    path.closeSubpath()
                    current = subpathStart
                }
                continue
            }

            switch command {
            case "M", "m":
                guard let x = nextNumber(), let y = nextNumber() else {
                    index += 1
                    continue
                }
                let point = command == "m"
                    ? CGPoint(x: current.x + x, y: current.y + y)
                    : CGPoint(x: x, y: y)
                path.move(to: point)
                current = point
                subpathStart = point
                command = command == "m" ? "l" : "L"
            case "L", "l":
                guard let x = nextNumber(), let y = nextNumber() else {
                    index += 1
                    continue
                }
                let point = command == "l"
                    ? CGPoint(x: current.x + x, y: current.y + y)
                    : CGPoint(x: x, y: y)
                path.addLine(to: point)
                current = point
            default:
                index += 1
            }
        }

        return Path(path)
    }
}
