import SwiftUI

private struct NewAgentTemplate: Identifiable {
    let id: String
    let title: String
    let cardColors: [Color]
    let accent: Color
    let figureStyle: RunnerLissajousStyle
    let supportsReadMore: Bool
    let requiresCustomName: Bool

    static let all: [NewAgentTemplate] = [
        NewAgentTemplate(
            id: "custom",
            title: "Create your own agent",
            cardColors: [
                Color(red: 0.16, green: 0.16, blue: 0.18),
                Color(red: 0.24, green: 0.24, blue: 0.27),
                Color(red: 0.32, green: 0.32, blue: 0.36),
            ],
            accent: Color(red: 0.78, green: 0.80, blue: 0.84),
            figureStyle: RunnerLissajousStyle(
                xFrequency: 3,
                yFrequency: 2,
                phaseShift: .pi / 2.1,
                drift: 0.88,
                amplitudeX: 0.40,
                amplitudeY: 0.33,
                rotation: .degrees(0),
                glowColors: [
                    Color.white.opacity(0.09),
                    Color.white.opacity(0.26),
                    Color(red: 0.90, green: 0.91, blue: 0.94).opacity(0.52),
                    Color(red: 0.76, green: 0.78, blue: 0.83).opacity(0.22),
                ],
                strokeColors: [
                    Color(red: 0.72, green: 0.74, blue: 0.79).opacity(0.48),
                    Color(red: 0.84, green: 0.85, blue: 0.89).opacity(0.86),
                    Color.white.opacity(0.92),
                    Color(red: 0.66, green: 0.68, blue: 0.73).opacity(0.62),
                ],
                glowLineWidth: 16,
                strokeLineWidth: 3.5
            ),
            supportsReadMore: false,
            requiresCustomName: true
        ),
        NewAgentTemplate(
            id: "ios-developer",
            title: "iOS Developer Agent",
            cardColors: [
                Color(red: 0.09, green: 0.20, blue: 0.31),
                Color(red: 0.16, green: 0.38, blue: 0.55),
                Color(red: 0.30, green: 0.63, blue: 0.76),
            ],
            accent: Color(red: 0.55, green: 0.84, blue: 0.96),
            figureStyle: RunnerLissajousStyle(
                xFrequency: 3,
                yFrequency: 2,
                phaseShift: .pi / 3,
                drift: 0.92,
                amplitudeX: 0.41,
                amplitudeY: 0.33,
                rotation: .degrees(-10),
                glowColors: [
                    Color(red: 0.32, green: 0.74, blue: 0.94).opacity(0.18),
                    Color(red: 0.40, green: 0.83, blue: 0.98).opacity(0.52),
                    Color.white.opacity(0.76),
                    Color(red: 0.58, green: 0.89, blue: 1.00).opacity(0.26),
                ],
                strokeColors: [
                    Color(red: 0.54, green: 0.84, blue: 1.00).opacity(0.58),
                    Color(red: 0.39, green: 0.70, blue: 1.00),
                    Color.white.opacity(0.94),
                    Color(red: 0.45, green: 0.87, blue: 0.98).opacity(0.74),
                ],
                glowLineWidth: 16,
                strokeLineWidth: 3.6
            ),
            supportsReadMore: true,
            requiresCustomName: false
        ),
        NewAgentTemplate(
            id: "web-developer",
            title: "Web Developer Agent",
            cardColors: [
                Color(red: 0.11, green: 0.12, blue: 0.18),
                Color(red: 0.19, green: 0.23, blue: 0.35),
                Color(red: 0.31, green: 0.47, blue: 0.67),
            ],
            accent: Color(red: 0.64, green: 0.76, blue: 0.98),
            figureStyle: RunnerLissajousStyle(
                xFrequency: 5,
                yFrequency: 4,
                phaseShift: .pi / 2.4,
                drift: 0.84,
                amplitudeX: 0.40,
                amplitudeY: 0.31,
                rotation: .degrees(12),
                glowColors: [
                    Color(red: 0.36, green: 0.52, blue: 0.98).opacity(0.16),
                    Color(red: 0.50, green: 0.62, blue: 1.00).opacity(0.46),
                    Color.white.opacity(0.70),
                    Color(red: 0.54, green: 0.80, blue: 1.00).opacity(0.24),
                ],
                strokeColors: [
                    Color(red: 0.63, green: 0.77, blue: 1.00).opacity(0.52),
                    Color(red: 0.49, green: 0.60, blue: 1.00).opacity(0.95),
                    Color.white.opacity(0.91),
                    Color(red: 0.58, green: 0.86, blue: 0.98).opacity(0.68),
                ],
                glowLineWidth: 17,
                strokeLineWidth: 3.2
            ),
            supportsReadMore: true,
            requiresCustomName: false
        ),
        NewAgentTemplate(
            id: "youtube",
            title: "YouTube Agent",
            cardColors: [
                Color(red: 0.23, green: 0.07, blue: 0.08),
                Color(red: 0.44, green: 0.09, blue: 0.12),
                Color(red: 0.76, green: 0.23, blue: 0.19),
            ],
            accent: Color(red: 0.98, green: 0.56, blue: 0.48),
            figureStyle: RunnerLissajousStyle(
                xFrequency: 4,
                yFrequency: 1,
                phaseShift: .pi / 2,
                drift: 0.72,
                amplitudeX: 0.40,
                amplitudeY: 0.28,
                rotation: .degrees(-5),
                glowColors: [
                    Color(red: 0.92, green: 0.29, blue: 0.22).opacity(0.18),
                    Color(red: 1.00, green: 0.43, blue: 0.35).opacity(0.46),
                    Color.white.opacity(0.70),
                    Color(red: 1.00, green: 0.73, blue: 0.53).opacity(0.24),
                ],
                strokeColors: [
                    Color(red: 1.00, green: 0.72, blue: 0.53).opacity(0.50),
                    Color(red: 0.98, green: 0.39, blue: 0.30).opacity(0.96),
                    Color.white.opacity(0.92),
                    Color(red: 1.00, green: 0.58, blue: 0.42).opacity(0.70),
                ],
                glowLineWidth: 15,
                strokeLineWidth: 3.4
            ),
            supportsReadMore: true,
            requiresCustomName: false
        ),
        NewAgentTemplate(
            id: "marketing",
            title: "Marketing Agent",
            cardColors: [
                Color(red: 0.22, green: 0.15, blue: 0.05),
                Color(red: 0.46, green: 0.28, blue: 0.08),
                Color(red: 0.82, green: 0.50, blue: 0.15),
            ],
            accent: Color(red: 1.00, green: 0.82, blue: 0.52),
            figureStyle: RunnerLissajousStyle(
                xFrequency: 2,
                yFrequency: 1,
                phaseShift: .pi / 2.25,
                drift: 1.24,
                phaseCoupling: 0.16,
                amplitudeX: 0.37,
                amplitudeY: 0.25,
                rotation: .degrees(10),
                glowColors: [
                    Color(red: 0.94, green: 0.68, blue: 0.22).opacity(0.14),
                    Color(red: 1.00, green: 0.79, blue: 0.36).opacity(0.38),
                    Color.white.opacity(0.70),
                    Color(red: 1.00, green: 0.88, blue: 0.64).opacity(0.18),
                ],
                strokeColors: [
                    Color(red: 1.00, green: 0.86, blue: 0.60).opacity(0.44),
                    Color(red: 0.99, green: 0.73, blue: 0.26).opacity(0.90),
                    Color.white.opacity(0.88),
                    Color(red: 1.00, green: 0.79, blue: 0.38).opacity(0.60),
                ],
                glowLineWidth: 14,
                strokeLineWidth: 2.9
            ),
            supportsReadMore: true,
            requiresCustomName: false
        ),
        NewAgentTemplate(
            id: "executive-assistant",
            title: "Executive Assistant Agent",
            cardColors: [
                Color(red: 0.10, green: 0.14, blue: 0.16),
                Color(red: 0.20, green: 0.29, blue: 0.32),
                Color(red: 0.47, green: 0.58, blue: 0.56),
            ],
            accent: Color(red: 0.82, green: 0.92, blue: 0.86),
            figureStyle: RunnerLissajousStyle(
                xFrequency: 2,
                yFrequency: 5,
                phaseShift: .pi / 2.8,
                drift: 0.78,
                amplitudeX: 0.39,
                amplitudeY: 0.33,
                rotation: .degrees(-20),
                glowColors: [
                    Color(red: 0.55, green: 0.72, blue: 0.70).opacity(0.15),
                    Color(red: 0.72, green: 0.86, blue: 0.84).opacity(0.42),
                    Color.white.opacity(0.74),
                    Color(red: 0.88, green: 0.95, blue: 0.92).opacity(0.22),
                ],
                strokeColors: [
                    Color(red: 0.84, green: 0.93, blue: 0.88).opacity(0.46),
                    Color(red: 0.66, green: 0.82, blue: 0.79).opacity(0.92),
                    Color.white.opacity(0.92),
                    Color(red: 0.80, green: 0.91, blue: 0.87).opacity(0.62),
                ],
                glowLineWidth: 16,
                strokeLineWidth: 3.3
            ),
            supportsReadMore: true,
            requiresCustomName: false
        ),
        NewAgentTemplate(
            id: "sales",
            title: "Sales Agent",
            cardColors: [
                Color(red: 0.11, green: 0.18, blue: 0.12),
                Color(red: 0.18, green: 0.34, blue: 0.20),
                Color(red: 0.30, green: 0.57, blue: 0.30),
            ],
            accent: Color(red: 0.73, green: 0.95, blue: 0.62),
            figureStyle: RunnerLissajousStyle(
                xFrequency: 3,
                yFrequency: 1,
                phaseShift: .pi / 2.1,
                drift: 1.02,
                phaseCoupling: 0.22,
                amplitudeX: 0.38,
                amplitudeY: 0.24,
                rotation: .degrees(8),
                glowColors: [
                    Color(red: 0.42, green: 0.81, blue: 0.36).opacity(0.14),
                    Color(red: 0.60, green: 0.92, blue: 0.45).opacity(0.40),
                    Color.white.opacity(0.70),
                    Color(red: 0.76, green: 0.97, blue: 0.66).opacity(0.18),
                ],
                strokeColors: [
                    Color(red: 0.77, green: 0.96, blue: 0.68).opacity(0.46),
                    Color(red: 0.48, green: 0.85, blue: 0.39).opacity(0.90),
                    Color.white.opacity(0.88),
                    Color(red: 0.67, green: 0.93, blue: 0.53).opacity(0.60),
                ],
                glowLineWidth: 14,
                strokeLineWidth: 3.0
            ),
            supportsReadMore: true,
            requiresCustomName: false
        ),
        NewAgentTemplate(
            id: "design",
            title: "Design Agent",
            cardColors: [
                Color(red: 0.20, green: 0.09, blue: 0.19),
                Color(red: 0.34, green: 0.16, blue: 0.31),
                Color(red: 0.62, green: 0.30, blue: 0.54),
            ],
            accent: Color(red: 0.98, green: 0.74, blue: 0.90),
            figureStyle: RunnerLissajousStyle(
                xFrequency: 5,
                yFrequency: 2,
                phaseShift: .pi / 1.9,
                drift: 0.88,
                phaseCoupling: 0.28,
                amplitudeX: 0.35,
                amplitudeY: 0.29,
                rotation: .degrees(-14),
                glowColors: [
                    Color(red: 0.86, green: 0.45, blue: 0.75).opacity(0.14),
                    Color(red: 0.96, green: 0.63, blue: 0.84).opacity(0.40),
                    Color.white.opacity(0.72),
                    Color(red: 0.99, green: 0.82, blue: 0.92).opacity(0.20),
                ],
                strokeColors: [
                    Color(red: 0.99, green: 0.81, blue: 0.92).opacity(0.46),
                    Color(red: 0.92, green: 0.54, blue: 0.80).opacity(0.88),
                    Color.white.opacity(0.90),
                    Color(red: 0.98, green: 0.69, blue: 0.87).opacity(0.60),
                ],
                glowLineWidth: 14,
                strokeLineWidth: 3.0
            ),
            supportsReadMore: true,
            requiresCustomName: false
        ),
        NewAgentTemplate(
            id: "research",
            title: "Research Agent",
            cardColors: [
                Color(red: 0.08, green: 0.17, blue: 0.20),
                Color(red: 0.12, green: 0.31, blue: 0.36),
                Color(red: 0.20, green: 0.53, blue: 0.58),
            ],
            accent: Color(red: 0.68, green: 0.95, blue: 0.96),
            figureStyle: RunnerLissajousStyle(
                xFrequency: 4,
                yFrequency: 3,
                phaseShift: .pi / 2.6,
                drift: 0.94,
                phaseCoupling: 0.20,
                amplitudeX: 0.34,
                amplitudeY: 0.31,
                rotation: .degrees(4),
                glowColors: [
                    Color(red: 0.34, green: 0.82, blue: 0.86).opacity(0.14),
                    Color(red: 0.53, green: 0.92, blue: 0.94).opacity(0.40),
                    Color.white.opacity(0.72),
                    Color(red: 0.74, green: 0.98, blue: 0.98).opacity(0.18),
                ],
                strokeColors: [
                    Color(red: 0.76, green: 0.98, blue: 0.98).opacity(0.46),
                    Color(red: 0.45, green: 0.88, blue: 0.91).opacity(0.90),
                    Color.white.opacity(0.88),
                    Color(red: 0.61, green: 0.95, blue: 0.96).opacity(0.58),
                ],
                glowLineWidth: 14,
                strokeLineWidth: 2.9
            ),
            supportsReadMore: true,
            requiresCustomName: false
        ),
    ]

    var detailParagraphs: [String] {
        switch id {
        case "custom":
            return [
                "Create your own agent gives you a blank naming pass first, then routes into the same sandbox provisioning flow as the prebuilt templates.",
                "Use it when you want the agent to enter your list with your own title instead of a preset role name. You can differentiate the deeper behavior later without changing the creation path today.",
                "It is the fastest route to a real agent when you know the name you want and do not need a prewritten template story on this screen.",
            ]
        case "ios-developer":
            return [
                "The iOS Developer Agent is built for product teams shipping native Apple experiences. It focuses on SwiftUI implementation, app architecture, debugging loops, and the kind of quality-control work that keeps releases stable.",
                "It is strongest when a project needs structured execution across features, polish passes, and release prep. The agent thinks in screens, states, performance, and how small implementation details affect the feel of the app.",
                "Use it when you want an operator that can translate product intent into a clean native build rhythm. It is optimized for momentum, code quality, and keeping the app feeling intentional from prototype to launch.",
            ]
        case "web-developer":
            return [
                "The Web Developer Agent is designed for modern product surfaces across frontend and backend boundaries. It can reason through responsive UI, API integrations, application structure, and delivery workflows.",
                "This template is useful when the work spans implementation and system thinking at the same time. It keeps a strong bias toward production-ready decisions rather than one-off hacks that fall apart later.",
                "Use it when you need an agent that can move between interface, logic, and deployment concerns without losing cohesion. It is meant to keep the whole web surface moving as one system.",
            ]
        case "youtube":
            return [
                "The YouTube Agent is tuned for channel building, content operations, and repeatable publishing systems. It thinks about pacing, titles, packaging, scripting, and the workflow around getting videos out consistently.",
                "It is useful when the goal is not only to create one strong video, but to operate the channel like a machine. The template balances creative ideation with production discipline and distribution awareness.",
                "Use it when you want an agent that behaves like a sharp content operator rather than just a copy assistant. It is designed to help shape a channel identity and sustain audience momentum over time.",
            ]
        case "marketing":
            return [
                "The Marketing Agent is oriented around campaigns, messaging systems, and launch coordination. It is best used where positioning, copy, content, and execution all need to feel aligned.",
                "This template works well for founders and teams that want a consistent voice across announcements, outbound pushes, and ongoing growth loops. It is built to keep narrative and operations working together.",
                "Use it when you need an agent that can translate product value into clear market-facing execution. It is optimized for clarity, repetition, and the discipline required to keep campaigns moving.",
            ]
        case "executive-assistant":
            return [
                "The Executive Assistant Agent is built for operational leverage. It helps structure follow-ups, summarize context, triage incoming information, and reduce the drag created by daily coordination work.",
                "It is useful when the problem is not insight but load. The template is designed to create order across scheduling, notes, inbox flow, and the many small decisions that interrupt higher-level work.",
                "Use it when you want an agent that behaves like a disciplined operator in the background. It is optimized for reliability, context retention, and keeping the principal focused on the highest-value tasks.",
            ]
        case "sales":
            return [
                "The Sales Agent is made for pipeline execution, follow-up discipline, and outbound clarity. It helps keep deals moving by organizing messaging, next steps, and account context with less friction.",
                "This template is strongest when consistency matters more than bursts of activity. It works well for qualifying opportunities, drafting tailored outreach, and maintaining momentum across active conversations.",
                "Use it when you need an agent that can support revenue motion with structure and speed. It is tuned to feel proactive, concise, and commercially aware without sounding generic.",
            ]
        case "design":
            return [
                "The Design Agent is focused on taste, interface clarity, and creative systems thinking. It helps shape the visual and experiential side of a product with a bias toward strong, intentional decisions.",
                "It is useful when a team needs more than surface-level inspiration. The template is built to reason about hierarchy, interaction, consistency, and the emotional quality of the product as a whole.",
                "Use it when you want an agent that can support concept development, refinement, and critique in a way that still feels grounded in execution. It is designed to keep work sharp rather than decorative.",
            ]
        case "research":
            return [
                "The Research Agent is tuned for synthesis, pattern finding, and structured exploration. It is useful when information needs to be gathered, organized, and turned into something that can drive decisions.",
                "This template is best when the work demands signal over noise. It can hold multiple threads at once, compare sources, and surface what matters without burying the output in raw material.",
                "Use it when you want an agent that feels analytical but still readable. It is optimized for concise briefs, directional insight, and making complexity easier to act on.",
            ]
        default:
            return [
                "This agent template is designed to provide a strong starting point with a clear operational bias.",
                "It combines a focused personality with a practical working rhythm suited to its domain.",
                "Use it when you want a faster path to a specialized OpenClaw setup without starting from zero.",
            ]
        }
    }
}

struct NewAgentPageView: View {
    @EnvironmentObject private var appModel: RunnerAppModel
    @Environment(\.dismiss) private var dismiss
    @Namespace private var cardTransition
    @State private var selectedTemplateID: String? = NewAgentTemplate.all.first?.id
    @State private var readMoreReadyTemplateID: String? = NewAgentTemplate.all.first?.id
    @State private var customNamingTemplate: NewAgentTemplate?
    @State private var provisioningTemplate: NewAgentTemplate?
    @State private var detailTemplate: NewAgentTemplate?
    @State private var launchTask: Task<Void, Never>?
    @State private var settleTask: Task<Void, Never>?
    @State private var agentCreationTask: Task<Void, Never>?
    @State private var creationError: String?
    @State private var customAgentName = ""
    @State private var provisioningTitle = ""
    @State private var isAgentCreationFinished = false
    @State private var pendingProvisioningDismiss = false

    private let templates = NewAgentTemplate.all

    private var selectedTemplate: NewAgentTemplate {
        guard let selectedTemplateID else { return templates[0] }
        return templates.first(where: { $0.id == selectedTemplateID }) ?? templates[0]
    }

    private var selectedIndex: Int {
        templates.firstIndex(where: { $0.id == selectedTemplate.id }) ?? 0
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
                    .offset(y: -56)

                if let creationError {
                    RunnerInlineNotice(text: creationError)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                }

                carouselSection
                    .padding(.bottom, 24)
            }
            .allowsHitTesting(provisioningTemplate == nil && detailTemplate == nil && customNamingTemplate == nil)

            if let detailTemplate {
                NewAgentDetailOverlay(
                    template: detailTemplate,
                    namespace: cardTransition
                ) {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        self.detailTemplate = nil
                    }
                }
                .transition(.opacity)
                .zIndex(6)
            }

            if let customNamingTemplate {
                NewCustomAgentSetupView(
                    template: customNamingTemplate,
                    agentName: $customAgentName
                ) {
                    Haptics.navigate()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                        self.customNamingTemplate = nil
                    }
                } onContinue: {
                    confirmCustomAgentCreation(for: customNamingTemplate)
                }
                .transition(.opacity)
                .zIndex(8)
            }

            if let provisioningTemplate {
                NewAgentProvisioningView(template: provisioningTemplate, title: provisioningTitle) {
                    pendingProvisioningDismiss = true
                    if isAgentCreationFinished {
                        dismissProvisioningFlow()
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: selectedTemplateID) { _, _ in
            guard provisioningTemplate == nil, customNamingTemplate == nil else { return }
            Haptics.carouselSnap()
            scheduleReadMoreUnlock()
        }
        .onDisappear {
            launchTask?.cancel()
            settleTask?.cancel()
            agentCreationTask?.cancel()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RunnerTheme.primaryText)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(RunnerTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(RunnerTheme.borderStrong, lineWidth: 1)
                    )
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
    }

    private var hero: some View {
        VStack(spacing: 0) {
            RunnerLissajousView(style: selectedTemplate.figureStyle)
                .frame(width: 360, height: 280)
                .offset(y: -16)
                .padding(.bottom, 4)
                .id(selectedTemplate.id)
                .transition(.opacity)

            Text("Select new agent")
                .font(RunnerTypography.sans(28, weight: .semibold))
                .foregroundStyle(RunnerTheme.primaryText)
                .tracking(-0.4)
                .padding(.top, 18)
        }
        .offset(y: -8)
        .animation(.interactiveSpring(response: 0.48, dampingFraction: 0.84, blendDuration: 0.16), value: selectedTemplate.id)
    }

    private var carouselSection: some View {
        VStack(spacing: 12) {
            GeometryReader { proxy in
                let cardSize = min(proxy.size.width * 0.56, 188)
                let slotWidth = cardSize * 1.08
                let sideInset = (proxy.size.width - slotWidth) / 2
                let viewportMidX = proxy.frame(in: .global).midX

                ScrollView(.horizontal) {
                    LazyHStack(spacing: 16) {
                        ForEach(templates) { template in
                            GeometryReader { cardProxy in
                                let cardMidX = cardProxy.frame(in: .global).midX
                                let distance = abs(cardMidX - viewportMidX)
                                let normalized = min(distance / (cardSize * 1.18), 1)
                                let prominence = 1 - normalized
                                let direction = cardMidX < viewportMidX ? -1.0 : 1.0
                                let activeBoost: CGFloat = template.id == selectedTemplate.id ? 0.08 : 0
                                let scale = 0.78 + (prominence * 0.26) + activeBoost
                                let lift = (1 - prominence) * 28

                                NewAgentTemplateCard(
                                    template: template,
                                    prominence: prominence,
                                    tilt: direction * normalized * 5.5,
                                    isSelected: template.id == selectedTemplate.id,
                                    showReadMore: template.id == readMoreReadyTemplateID,
                                    isHiddenForDetail: detailTemplate?.id == template.id,
                                    namespace: cardTransition
                                ) {
                                    showDetail(for: template)
                                }
                                .frame(width: cardSize, height: cardSize)
                                .scaleEffect(scale)
                                .offset(y: lift)
                                .rotationEffect(.degrees(direction * normalized * 5.5))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                .zIndex(prominence)
                                .contentShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                                .onTapGesture {
                                    beginProvisioning(for: template)
                                }
                            }
                            .frame(width: slotWidth, height: cardSize + 34)
                            .id(template.id)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, sideInset)
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $selectedTemplateID, anchor: .center)
                .scrollClipDisabled()
            }
            .frame(height: 250)

            HStack(spacing: 8) {
                ForEach(templates.indices, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index == selectedIndex ? AnyShapeStyle(selectedTemplate.accent) : AnyShapeStyle(RunnerTheme.borderStrong))
                        .frame(width: index == selectedIndex ? 24 : 7, height: 7)
                        .animation(.spring(duration: 0.22), value: selectedIndex)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func beginProvisioning(for template: NewAgentTemplate) {
        guard provisioningTemplate == nil, detailTemplate == nil, customNamingTemplate == nil else { return }
        launchTask?.cancel()
        settleTask?.cancel()
        agentCreationTask?.cancel()

        creationError = nil
        pendingProvisioningDismiss = false
        isAgentCreationFinished = false

        Haptics.mainButton()

        withAnimation(.interactiveSpring(response: 0.36, dampingFraction: 0.82, blendDuration: 0.14)) {
            selectedTemplateID = template.id
        }

        if template.requiresCustomName {
            customAgentName = ""
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                customNamingTemplate = template
            }
            return
        }

        startProvisioning(for: template, agentName: template.title)
    }

    private func confirmCustomAgentCreation(for template: NewAgentTemplate) {
        let trimmedName = customAgentName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        Haptics.mainButton()

        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
            customNamingTemplate = nil
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            guard customNamingTemplate == nil else { return }
            startProvisioning(for: template, agentName: trimmedName)
        }
    }

    private func startProvisioning(for template: NewAgentTemplate, agentName: String) {
        provisioningTitle = agentName

        agentCreationTask = Task { @MainActor in
            do {
                _ = try await appModel.createAgent(name: agentName)
                guard !Task.isCancelled else { return }

                isAgentCreationFinished = true
                if pendingProvisioningDismiss {
                    dismissProvisioningFlow()
                }
            } catch {
                guard !Task.isCancelled else { return }

                creationError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                isAgentCreationFinished = true
                launchTask?.cancel()

                withAnimation(.easeInOut(duration: 0.22)) {
                    provisioningTemplate = nil
                }
            }
        }

        launchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: 0.24)) {
                provisioningTemplate = template
            }
        }
    }

    @MainActor
    private func dismissProvisioningFlow() {
        withAnimation(.easeInOut(duration: 0.26)) {
            provisioningTemplate = nil
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            dismiss()
        }
    }

    private func showDetail(for template: NewAgentTemplate) {
        guard template.supportsReadMore else { return }
        guard provisioningTemplate == nil, detailTemplate == nil, customNamingTemplate == nil else { return }
        launchTask?.cancel()
        settleTask?.cancel()
        Haptics.navigate()

        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            selectedTemplateID = template.id
            detailTemplate = template
        }
    }

    private func scheduleReadMoreUnlock() {
        settleTask?.cancel()
        readMoreReadyTemplateID = nil

        let candidateID = selectedTemplateID
        settleTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            guard !Task.isCancelled, candidateID == selectedTemplateID, detailTemplate == nil, provisioningTemplate == nil else {
                return
            }

            withAnimation(.easeInOut(duration: 0.16)) {
                readMoreReadyTemplateID = candidateID
            }
        }
    }
}

private struct NewAgentTemplateCard: View {
    let template: NewAgentTemplate
    let prominence: CGFloat
    let tilt: Double
    let isSelected: Bool
    let showReadMore: Bool
    let isHiddenForDetail: Bool
    let namespace: Namespace.ID
    let onReadMore: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: template.cardColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .matchedGeometryEffect(id: "card-\(template.id)", in: namespace)

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color.black.opacity(0.12 - (prominence * 0.04)))

            Circle()
                .fill(template.accent.opacity(0.22 + (prominence * 0.10)))
                .frame(width: 172, height: 172)
                .blur(radius: 30 - (prominence * 4))
                .offset(x: 120 - (prominence * 12), y: -18 + (prominence * 8))

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 114, height: 114)
                .blur(radius: 20)
                .offset(x: -20 + (prominence * 8), y: 102 - (prominence * 10))

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(Color.white.opacity(0.06 + (prominence * 0.10)), lineWidth: 1)

            Text(template.title)
                .font(RunnerTypography.sans(23, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
                .frame(maxWidth: .infinity, minHeight: 88, alignment: .bottomLeading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isSelected ? 0.28 : 0.14),
                            Color.white.opacity(0.06),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isSelected ? 1.2 : 1
                )
        )
        .shadow(color: Color.black.opacity(0.24 + (prominence * 0.20)), radius: 22 + (prominence * 12), x: 0, y: 20)
        .background(alignment: .bottom) {
            Ellipse()
                .fill(Color.black.opacity(0.24 + (prominence * 0.10)))
                .frame(width: 126 + (prominence * 28), height: 26 + (prominence * 8))
                .blur(radius: 18)
                .offset(y: 28)
        }
        .overlay(alignment: .topTrailing) {
            if template.supportsReadMore && showReadMore && !isHiddenForDetail {
                Button(action: onReadMore) {
                    Text("Read More")
                        .font(RunnerTypography.sans(11.5, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.black.opacity(0.16), in: Capsule(style: .continuous))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(14)
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .opacity(isHiddenForDetail ? 0.001 : 1)
        .allowsHitTesting(!isHiddenForDetail)
        .animation(.spring(response: 0.30, dampingFraction: 0.84), value: isSelected)
    }
}

private struct NewAgentDetailOverlay: View {
    let template: NewAgentTemplate
    let namespace: Namespace.ID
    let onClose: () -> Void

    @State private var contentVisible = false
    @State private var panelTilt = -10.0
    @State private var dragOffset: CGFloat = 0

    private var dismissProgress: CGFloat {
        min(max(dragOffset / 260, 0), 1)
    }

    private var overlayOpacity: Double {
        let baseOpacity = contentVisible ? 0.52 : 0.0
        return baseOpacity * (1 - (Double(dismissProgress) * 0.82))
    }

    var body: some View {
        ZStack {
            RunnerBackgroundView()
                .ignoresSafeArea()

            Color.black.opacity(overlayOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: 18) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(RunnerTheme.primaryText)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(RunnerTheme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(RunnerTheme.borderStrong, lineWidth: 1)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: template.cardColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .matchedGeometryEffect(id: "card-\(template.id)", in: namespace)

                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(Color.black.opacity(0.12))

                    Circle()
                        .fill(template.accent.opacity(0.20))
                        .frame(width: 230, height: 230)
                        .blur(radius: 34)
                        .offset(x: 118, y: -32)

                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 150, height: 150)
                        .blur(radius: 24)
                        .offset(x: -18, y: 124)

                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)

                    Text(template.title)
                        .font(RunnerTypography.sans(31, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        .opacity(contentVisible ? 1 : 0)
                        .offset(y: contentVisible ? 0 : 10)
                        .animation(.easeInOut(duration: 0.18).delay(0.06), value: contentVisible)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                .rotation3DEffect(.degrees(contentVisible ? 0 : panelTilt), axis: (x: 0, y: 1, z: 0))
                .shadow(color: Color.black.opacity(0.30), radius: 24, x: 0, y: 22)
                .padding(.horizontal, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(Array(template.detailParagraphs.enumerated()), id: \.offset) { index, paragraph in
                            Text(paragraph)
                                .font(RunnerTypography.sans(16, weight: .medium))
                                .foregroundStyle(RunnerTheme.primaryText.opacity(0.88))
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .opacity(contentVisible ? 1 : 0)
                                .offset(y: contentVisible ? 0 : 18)
                                .animation(
                                    .spring(response: 0.48, dampingFraction: 0.88).delay(0.05 * Double(index)),
                                    value: contentVisible
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 34)
                }
                .opacity(contentVisible ? 1 : 0)
            }
            .offset(y: dragOffset)
            .scaleEffect(1 - (dismissProgress * 0.06), anchor: .top)
            .simultaneousGesture(pullToDismissGesture)
        }
        .task {
            withAnimation(.spring(response: 0.46, dampingFraction: 0.88)) {
                contentVisible = true
                panelTilt = 0
            }
        }
    }

    private func dismiss() {
        Haptics.navigate()

        withAnimation(.easeInOut(duration: 0.22)) {
            contentVisible = false
            panelTilt = -8
            dragOffset = 0
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            onClose()
        }
    }

    private var pullToDismissGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard contentVisible else { return }
                guard value.translation.height > 0 else { return }
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                dragOffset = value.translation.height
            }
            .onEnded { value in
                guard contentVisible else { return }
                let travel = max(value.translation.height, 0)
                let projected = max(value.predictedEndTranslation.height, 0)

                if travel > 110 || projected > 180 {
                    dismiss()
                } else {
                    withAnimation(.interactiveSpring(response: 0.34, dampingFraction: 0.82)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

private struct NewCustomAgentSetupView: View {
    let template: NewAgentTemplate
    @Binding var agentName: String
    let onClose: () -> Void
    let onContinue: () -> Void

    @FocusState private var nameFieldFocused: Bool

    private var trimmedName: String {
        agentName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canContinue: Bool {
        !trimmedName.isEmpty
    }

    private var clampedNameBinding: Binding<String> {
        Binding(
            get: { agentName },
            set: { newValue in
                agentName = String(newValue.prefix(100))
            }
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = min(proxy.size.width - 48, 360)

            ZStack {
                Color.black.opacity(0.58)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onClose()
                    }

                VStack {
                    Spacer()

                    VStack(spacing: 24) {
                        Text("Name your agent")
                            .font(RunnerTypography.sans(30, weight: .semibold))
                            .foregroundStyle(RunnerTheme.primaryText)

                        VStack(spacing: 10) {
                            TextField("", text: clampedNameBinding, prompt: Text("OpenClaw Agent").foregroundStyle(RunnerTheme.tertiaryText))
                                .font(RunnerTypography.sans(24, weight: .medium))
                                .foregroundStyle(RunnerTheme.primaryText)
                                .multilineTextAlignment(.center)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .focused($nameFieldFocused)
                                .onSubmit {
                                    guard canContinue else { return }
                                    onContinue()
                                }

                            Rectangle()
                                .fill(
                                    nameFieldFocused
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: [RunnerTheme.accentBlue, template.accent],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        : AnyShapeStyle(RunnerTheme.borderStrong)
                                )
                                .frame(height: nameFieldFocused ? 2 : 1)
                        }
                        .frame(width: contentWidth)

                        Button {
                            guard canContinue else { return }
                            onContinue()
                        } label: {
                            Text("Enter")
                                .font(RunnerTypography.sans(16, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(canContinue ? 0.96 : 0.62))
                                .frame(width: contentWidth)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: canContinue
                                                    ? [RunnerTheme.accentBlue, template.accent]
                                                    : [RunnerTheme.surface, RunnerTheme.surface],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(!canContinue)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea(.keyboard)
        .task {
            try? await Task.sleep(for: .milliseconds(260))
            guard !Task.isCancelled else { return }
            nameFieldFocused = true
        }
    }
}

private struct NewAgentProvisioningView: View {
    let template: NewAgentTemplate
    let title: String
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var heroScale: CGFloat = 0.84
    @State private var heroYOffset: CGFloat = 24
    @State private var contentOpacity = 0.0
    @State private var pulse = false
    @State private var progress: CGFloat = 0
    @State private var sequenceTask: Task<Void, Never>?

    private let steps = [
        "Installing OpenClaw",
        "Configuring Skills",
        "Building Personality",
        "Preconfiguring Connections",
    ]
    private let loadingItems: [ProvisioningLoadingItem] = [
        .init(label: "soul.md", kind: .file),
        .init(label: "Documents", kind: .folder),
        .init(label: "user.md", kind: .file),
        .init(label: "Projects", kind: .folder),
        .init(label: "identity.md", kind: .file),
        .init(label: ".openclaw", kind: .folder),
        .init(label: "agents.md", kind: .file),
        .init(label: "Pictures", kind: .folder),
        .init(label: "tools.md", kind: .file),
        .init(label: "Downloads", kind: .folder),
        .init(label: "heartbeat.md", kind: .file),
        .init(label: "Desktop", kind: .folder),
        .init(label: "bootstrap.md", kind: .file),
        .init(label: "Archives", kind: .folder),
        .init(label: "Workflows", kind: .folder),
    ]

    private var loadingFigureStyle: RunnerLissajousStyle {
        RunnerLissajousStyle(
            xFrequency: template.figureStyle.xFrequency,
            yFrequency: template.figureStyle.yFrequency,
            phaseShift: template.figureStyle.phaseShift,
            drift: template.figureStyle.drift,
            phaseCoupling: template.figureStyle.phaseCoupling,
            amplitudeX: template.figureStyle.amplitudeX,
            amplitudeY: template.figureStyle.amplitudeY,
            rotation: template.figureStyle.rotation,
            glowColors: template.figureStyle.glowColors,
            strokeColors: template.figureStyle.strokeColors,
            glowLineWidth: template.figureStyle.glowLineWidth * 1.5,
            strokeLineWidth: template.figureStyle.strokeLineWidth * 1.5
        )
    }

    var body: some View {
        ZStack {
            RunnerBackgroundView()

            Color.black.opacity(0.34)
                .ignoresSafeArea()

            Circle()
                .fill(template.accent.opacity(0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 90)
                .offset(y: -112)

            VStack(spacing: 0) {
                Spacer(minLength: 46)

                RunnerLissajousView(style: loadingFigureStyle)
                    .frame(width: 388, height: 304)
                    .scaleEffect(heroScale * (pulse ? 1.015 : 1.0))
                    .offset(y: heroYOffset)
                    .opacity(contentOpacity)
                    .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: pulse)

                Text(title)
                    .font(RunnerTypography.sans(26, weight: .semibold))
                    .foregroundStyle(RunnerTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 30)
                    .padding(.top, 8)
                    .opacity(contentOpacity)

                VStack(spacing: 0) {
                    ProvisioningLoadingStrip(items: loadingItems, speed: 26)
                        .opacity(contentOpacity * 0.82)
                        .padding(.horizontal, 6)

                    VStack(spacing: 14) {
                        loadingBar

                        Text(steps[currentStep])
                            .id(currentStep)
                            .font(RunnerTypography.sans(18, weight: .medium))
                            .foregroundStyle(RunnerTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    .padding(.top, 28)
                }
                .padding(.top, 14)

                Spacer(minLength: 86)
            }
        }
        .ignoresSafeArea()
        .task {
            startSequence()
        }
        .onDisappear {
            sequenceTask?.cancel()
        }
    }

    private var loadingBar: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: template.cardColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(width * progress, 10))
                    .shadow(color: template.accent.opacity(0.42), radius: 14, x: 0, y: 0)
            }
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .frame(width: 264, height: 9)
        .opacity(contentOpacity)
    }

    @MainActor
    private func startSequence() {
        sequenceTask?.cancel()
        currentStep = 0
        progress = 0

        withAnimation(.interactiveSpring(response: 0.72, dampingFraction: 0.76, blendDuration: 0.18)) {
            heroScale = 1.0
            heroYOffset = 2
            contentOpacity = 1
        }

        withAnimation(.linear(duration: 20.0)) {
            progress = 1
        }

        pulse = true
        Haptics.mainButton()

        sequenceTask = Task { @MainActor in
            for index in steps.indices {
                if index > 0 {
                    withAnimation(.easeInOut(duration: 0.42)) {
                        currentStep = index
                    }
                    Haptics.buttonPress()
                }

                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
            }

            Haptics.success()

            withAnimation(.easeInOut(duration: 0.34)) {
                contentOpacity = 0
                heroScale = 1.04
            }

            try? await Task.sleep(for: .milliseconds(340))
            guard !Task.isCancelled else { return }
            onComplete()
        }
    }
}

private struct ProvisioningLoadingItem: Identifiable {
    let label: String
    let kind: ProvisioningChipKind

    var id: String { "\(kind.rawValue)-\(label)" }
}

private enum ProvisioningChipKind: String {
    case file
    case folder
}

private struct ProvisioningLoadingStrip: View {
    let items: [ProvisioningLoadingItem]
    let speed: Double

    @State private var settledOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0

    private let spacing: CGFloat = 14
    private let rowHeight: CGFloat = 68

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let widths = items.map(tileWidth(for:))
            let rowWidth = widths.reduce(0, +) + (CGFloat(max(items.count - 1, 0)) * spacing)
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let travel = CGFloat(elapsed * speed) - settledOffset - dragOffset
            let wrapped = wrappedOffset(for: travel, rowWidth: rowWidth)

            GeometryReader { proxy in
                HStack(spacing: spacing) {
                    ForEach(0..<4, id: \.self) { _ in
                        HStack(spacing: spacing) {
                            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                                ProvisioningChip(item: item)
                                    .frame(width: widths[index], height: rowHeight)
                            }
                        }
                    }
                }
                .offset(x: -wrapped)
                .frame(width: proxy.size.width + rowWidth * 2, alignment: .leading)
                .mask(edgeFadeMask)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            settledOffset += value.translation.width
                            dragOffset = 0
                        }
                )
            }
        }
        .frame(height: rowHeight)
    }

    private func tileWidth(for item: ProvisioningLoadingItem) -> CGFloat {
        switch item.kind {
        case .file:
            return min(max(CGFloat(item.label.count) * 7.3 + 40, 104), 132)
        case .folder:
            return min(max(CGFloat(item.label.count) * 7.4 + 44, 112), 138)
        }
    }

    private func wrappedOffset(for travel: CGFloat, rowWidth: CGFloat) -> CGFloat {
        guard rowWidth > 0 else { return 0 }
        var wrapped = travel.truncatingRemainder(dividingBy: rowWidth)
        if wrapped < 0 { wrapped += rowWidth }
        return wrapped
    }

    private var edgeFadeMask: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .white, location: 0.08),
                .init(color: .white, location: 0.92),
                .init(color: .clear, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

private struct ProvisioningChip: View {
    let item: ProvisioningLoadingItem

    var body: some View {
        Group {
            switch item.kind {
            case .file:
                fileTile
            case .folder:
                folderTile
            }
        }
    }

    private var fileTile: some View {
        ZStack(alignment: .bottomLeading) {
            tileSurface(cornerRadius: 18)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.045))
                .frame(width: 54, height: 18)
                .blur(radius: 12)
                .offset(x: 10, y: -24)

            Text(item.label)
                .font(RunnerTypography.sans(11.5, weight: .medium))
                .foregroundStyle(RunnerTheme.secondaryText.opacity(0.88))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .bottomLeading)
        }
        .shadow(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 10)
    }

    private var folderTile: some View {
        ZStack(alignment: .bottomLeading) {
            tileSurface(cornerRadius: 14)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .frame(width: 48, height: 16)
                .blur(radius: 10)
                .offset(x: 10, y: -22)

            Text(item.label)
                .font(RunnerTypography.sans(11.5, weight: .medium))
                .foregroundStyle(RunnerTheme.secondaryText.opacity(0.88))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .bottomLeading)
        }
        .shadow(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 10)
    }

    private func tileSurface(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.085),
                        Color.white.opacity(0.035),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
            )
    }
}
