import SwiftUI
import UIKit

struct RunnerLissajousStyle {
    let xFrequency: Double
    let yFrequency: Double
    let phaseShift: Double
    let drift: Double
    let phaseCoupling: Double
    let amplitudeX: CGFloat
    let amplitudeY: CGFloat
    let rotation: Angle
    let glowColors: [Color]
    let strokeColors: [Color]
    let glowLineWidth: CGFloat
    let strokeLineWidth: CGFloat

    init(
        xFrequency: Double,
        yFrequency: Double,
        phaseShift: Double,
        drift: Double,
        phaseCoupling: Double = 0.4,
        amplitudeX: CGFloat,
        amplitudeY: CGFloat,
        rotation: Angle,
        glowColors: [Color],
        strokeColors: [Color],
        glowLineWidth: CGFloat,
        strokeLineWidth: CGFloat
    ) {
        self.xFrequency = xFrequency
        self.yFrequency = yFrequency
        self.phaseShift = phaseShift
        self.drift = drift
        self.phaseCoupling = phaseCoupling
        self.amplitudeX = amplitudeX
        self.amplitudeY = amplitudeY
        self.rotation = rotation
        self.glowColors = glowColors
        self.strokeColors = strokeColors
        self.glowLineWidth = glowLineWidth
        self.strokeLineWidth = strokeLineWidth
    }

    static let runner = RunnerLissajousStyle(
        xFrequency: 3,
        yFrequency: 2,
        phaseShift: .pi / 2,
        drift: 0.9,
        amplitudeX: 0.42,
        amplitudeY: 0.34,
        rotation: .degrees(0),
        glowColors: [
            RunnerTheme.accentBlue.opacity(0.15),
            RunnerTheme.accentBlue.opacity(0.50),
            Color.white.opacity(0.72),
            RunnerTheme.blueHalo.opacity(0.30),
        ],
        strokeColors: [
            RunnerTheme.blueHalo.opacity(0.55),
            RunnerTheme.accentBlue.opacity(0.95),
            Color.white.opacity(0.92),
            RunnerTheme.accentBlue.opacity(0.72),
        ],
        glowLineWidth: 16,
        strokeLineWidth: 3.4
    )
}

enum RunnerHomeGlyph {
    case files
    case skills
    case connections
    case cron
    case channels
}

struct RunnerHomeIconView: View {
    let glyph: RunnerHomeGlyph

    var body: some View {
        Group {
            switch glyph {
            case .files:
                Image(systemName: "folder")
                    .font(.system(size: 18, weight: .medium))
            case .skills:
                Image(systemName: "puzzlepiece.extension")
                    .font(.system(size: 18, weight: .medium))
            case .connections:
                Image(systemName: "powerplug")
                    .font(.system(size: 18, weight: .medium))
            case .channels:
                Image(systemName: "message")
                    .font(.system(size: 18, weight: .medium))
            case .cron:
                RunnerCronGlyph()
                    .frame(width: 18, height: 18)
            }
        }
    }
}

struct RunnerCronGlyph: View {
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(RunnerTheme.primaryText)
                    .frame(width: 1.8, height: index.isMultiple(of: 2) ? 5.5 : 4.25)
                    .offset(y: -6.2)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
        }
    }
}

struct RunnerFolderGlyph: View {
    var size: CGFloat = 54

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.43, green: 0.51, blue: 0.74),
                            Color(red: 0.31, green: 0.38, blue: 0.61),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size * 0.74)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.9)
                )
                .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 6)

            RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: size * 0.56, height: size * 0.10)
                .blur(radius: 5.5)
                .offset(y: -size * 0.14)
        }
        .frame(width: size, height: size * 0.78)
    }
}

struct RunnerLissajousView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var style: RunnerLissajousStyle = .runner

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 / 8 : 1 / 30)) { timeline in
            let time = reduceMotion ? 0.0 : timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size).insetBy(dx: 8, dy: 12)
                let glowPath = lissajousPath(in: rect, time: time, amplitudeScale: 1.0)
                let crispPath = lissajousPath(in: rect, time: time, amplitudeScale: 0.96)

                var glowContext = context
                glowContext.addFilter(.blur(radius: 10))
                glowContext.stroke(
                    glowPath,
                    with: .linearGradient(
                        Gradient(colors: style.glowColors),
                        startPoint: CGPoint(x: rect.minX, y: rect.midY),
                        endPoint: CGPoint(x: rect.maxX, y: rect.midY)
                    ),
                    style: StrokeStyle(lineWidth: style.glowLineWidth * 0.6, lineCap: .round, lineJoin: .round)
                )

                context.stroke(
                    crispPath,
                    with: .linearGradient(
                        Gradient(colors: style.strokeColors),
                        startPoint: CGPoint(x: rect.minX, y: rect.minY),
                        endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                    ),
                    style: StrokeStyle(lineWidth: style.strokeLineWidth * 1.6, lineCap: .round, lineJoin: .round)
                )

            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private func lissajousPath(in rect: CGRect, time: Double, amplitudeScale: CGFloat) -> Path {
        let count = 420
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let amplitudeX = rect.width * style.amplitudeX * amplitudeScale
        let amplitudeY = rect.height * style.amplitudeY * amplitudeScale
        let phase = time * style.drift
        let rotation = CGFloat(style.rotation.radians)

        var path = Path()

        for step in 0...count {
            let sample = Double(step) / Double(count)
            let theta = sample * .pi * 2

            let rawX = amplitudeX * CGFloat(sin(style.xFrequency * theta + phase))
            let rawY = amplitudeY * CGFloat(
                sin(style.yFrequency * theta + style.phaseShift + (phase * style.phaseCoupling))
            )
            let rotatedX = (rawX * cos(rotation)) - (rawY * sin(rotation))
            let rotatedY = (rawX * sin(rotation)) + (rawY * cos(rotation))
            let x = center.x + rotatedX
            let y = center.y + rotatedY

            if step == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.closeSubpath()
        return path
    }
}
