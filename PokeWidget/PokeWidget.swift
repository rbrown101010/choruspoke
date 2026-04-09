import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct AgentEntry: TimelineEntry {
    let date: Date
    let agentName: String
    let status: String
    let colorScheme: AgentWidgetColor
}

enum AgentWidgetColor: String {
    case blue, green, purple, teal
    
    var gradient: [Color] {
        switch self {
        case .blue: return [Color(red: 0.09, green: 0.40, blue: 0.99), Color(red: 0.01, green: 0.09, blue: 0.24)]
        case .green: return [Color(red: 0.32, green: 0.69, blue: 0.21), Color(red: 0.07, green: 0.14, blue: 0.04)]
        case .purple: return [Color(red: 0.53, green: 0.27, blue: 0.82), Color(red: 0.09, green: 0.04, blue: 0.15)]
        case .teal: return [Color(red: 0.17, green: 0.84, blue: 0.66), Color(red: 0.02, green: 0.11, blue: 0.08)]
        }
    }
    
    var accent: Color {
        switch self {
        case .blue: return Color(red: 0.40, green: 0.70, blue: 1.0)
        case .green: return Color(red: 0.50, green: 0.85, blue: 0.35)
        case .purple: return Color(red: 0.72, green: 0.55, blue: 0.95)
        case .teal: return Color(red: 0.40, green: 0.95, blue: 0.80)
        }
    }
}

struct AgentTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> AgentEntry {
        AgentEntry(date: .now, agentName: "My Agent", status: "Ready", colorScheme: .blue)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AgentEntry) -> Void) {
        let entry = AgentEntry(date: .now, agentName: "Chorus Agent", status: "Ready", colorScheme: .blue)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AgentEntry>) -> Void) {
        // Read from shared UserDefaults (app group) if available
        let defaults = UserDefaults(suiteName: "group.com.poke.app") ?? .standard
        let name = defaults.string(forKey: "widget_agent_name") ?? "Chorus Agent"
        let status = defaults.string(forKey: "widget_agent_status") ?? "Ready"
        let colorRaw = defaults.string(forKey: "widget_agent_color") ?? "blue"
        let color = AgentWidgetColor(rawValue: colorRaw) ?? .blue
        
        let entry = AgentEntry(date: .now, agentName: name, status: status, colorScheme: color)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Lissajous Shape

struct LissajousShape: Shape {
    var xFreq: Double = 3
    var yFreq: Double = 2
    var phase: Double = .pi / 2
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = 300
        let cx = rect.midX
        let cy = rect.midY
        let ax = rect.width * 0.38
        let ay = rect.height * 0.34
        
        for i in 0...steps {
            let t = Double(i) / Double(steps) * 2 * .pi
            let x = cx + ax * sin(xFreq * t + phase)
            let y = cy + ay * sin(yFreq * t)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Widget Views

struct PokeWidgetSmallView: View {
    let entry: AgentEntry
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: entry.colorScheme.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle ambient glow
            Circle()
                .fill(entry.colorScheme.accent.opacity(0.15))
                .frame(width: 120, height: 120)
                .blur(radius: 30)
                .offset(x: 30, y: -20)
            
            VStack(alignment: .leading, spacing: 0) {
                // Lissajous figure
                ZStack {
                    LissajousShape(xFreq: 3, yFreq: 2, phase: .pi / 2.1)
                        .stroke(
                            entry.colorScheme.accent.opacity(0.2),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .blur(radius: 4)
                    
                    LissajousShape(xFreq: 3, yFreq: 2, phase: .pi / 2.1)
                        .stroke(
                            LinearGradient(
                                colors: [entry.colorScheme.accent, .white.opacity(0.9), entry.colorScheme.accent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2.8, lineCap: .round)
                        )
                }
                .frame(height: 58)
                .padding(.top, 2)
                
                Spacer()
                
                // Status dot + label
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    
                    Text(entry.status)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                }
                
                // Agent name
                Text(entry.agentName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

struct PokeWidgetMediumView: View {
    let entry: AgentEntry
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: entry.colorScheme.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Circle()
                .fill(entry.colorScheme.accent.opacity(0.12))
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .offset(x: 80, y: -30)
            
            HStack(spacing: 16) {
                // Left: Lissajous
                ZStack {
                    LissajousShape(xFreq: 3, yFreq: 2, phase: .pi / 2.1)
                        .stroke(
                            entry.colorScheme.accent.opacity(0.18),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .blur(radius: 5)
                    
                    LissajousShape(xFreq: 3, yFreq: 2, phase: .pi / 2.1)
                        .stroke(
                            LinearGradient(
                                colors: [entry.colorScheme.accent, .white.opacity(0.9), entry.colorScheme.accent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3.2, lineCap: .round)
                        )
                }
                .frame(width: 110, height: 90)
                
                // Right: Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.agentName)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text(entry.status)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    
                    Spacer()
                    
                    Text("chorus.com")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
    }
}

// MARK: - Widget Configuration

struct PokeAgentWidget: Widget {
    let kind: String = "PokeAgentWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AgentTimelineProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                PokeWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color.clear
                    }
            } else {
                PokeWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Agent Status")
        .description("See your active Chorus agent at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PokeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: AgentEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            PokeWidgetSmallView(entry: entry)
        case .systemMedium:
            PokeWidgetMediumView(entry: entry)
        default:
            PokeWidgetSmallView(entry: entry)
        }
    }
}
