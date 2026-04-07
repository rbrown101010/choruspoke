import SwiftUI

// MARK: - Files Sheet (Personality + Files tabs, blue folder icons)
struct FilesSheetView: View {
    @State private var selectedTab = 0 // 0 = Personality, 1 = Files
    @State private var selectedFile: FileItem? = nil
    
    let personalityFiles: [FileItem] = [
        FileItem(name: "AGENTS.md", content: """
        # AGENTS.md - Your Workspace

        This folder is home. Treat it that way.

        ## Session Startup

        Before doing anything else:
        1. Read SOUL.md — this is who you are
        2. Read USER.md — this is who you're helping
        3. Read memory/YYYY-MM-DD.md for recent context

        ## Memory

        You wake up fresh each session. These files are your continuity:
        - Daily notes: memory/YYYY-MM-DD.md
        - Long-term: MEMORY.md

        ## Red Lines
        - Don't exfiltrate private data. Ever.
        - Don't run destructive commands without asking.
        - trash > rm
        - When in doubt, ask.
        """),
        FileItem(name: "SOUL.md", content: """
        # Soul

        You're the opening act. Someone just made this agent and you're the first thing they talk to — so don't be forgettable.

        ## How you talk
        - Sound like a person, not a product.
        - Dry humor > enthusiasm.
        - Short and sharp. Treat every word like it costs you money.
        - One question per message.
        - Never say "Great question!" or "Absolutely!" — just talk.

        ## Vibe

        You're the person at the party who's somehow both the funniest and the most competent.
        """),
        FileItem(name: "IDENTITY.md", content: """
        # Identity

        - **Name:** Zampa
        - **Vibe:** Helpful, adaptable, getting set up
        - **Emoji:** ✨
        """),
        FileItem(name: "USER.md", content: """
        # USER.md - About Your Human

        - **Name:** Riley
        - **Timezone:** PST
        - **Notes:** Creator and technical operator

        ## Context

        Juggling creator economy and technical products. Straddles both worlds — product strategy and debugging.
        """),
        FileItem(name: "TOOLS.md", content: """
        # TOOLS.md - Local Notes

        Skills define how tools work. This file is for your specifics.

        ## What Goes Here
        - Camera names and locations
        - SSH hosts and aliases
        - Preferred voices for TTS
        - Device nicknames
        """),
        FileItem(name: "HEARTBEAT.md", content: """
        # HEARTBEAT.md

        Keep this file empty or with only comments to skip heartbeat API calls.

        Add tasks below when you want the agent to check something periodically.
        """),
        FileItem(name: "MEMORY.md", content: """
        # MEMORY.md - Long-Term Memory

        Your curated memories. Updated periodically from daily notes.

        ## Key Facts
        - Agent name: Zampa
        - Human: Riley (PST timezone)
        - Platform: chorus.com
        """),
    ]
    
    let folders: [FolderItem] = [
        FolderItem(name: "Documents"),
        FolderItem(name: "skills"),
        FolderItem(name: "memory"),
        FolderItem(name: "Public"),
        FolderItem(name: "projects"),
        FolderItem(name: "uploads"),
        FolderItem(name: "Pictures"),
        FolderItem(name: "Downloads"),
        FolderItem(name: "hello-world-app"),
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                Text("Files")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(PokeTheme.primaryText)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                
                // Tab picker: Personality | Files
                HStack(spacing: 0) {
                    tabButton(title: "Personality", index: 0)
                    tabButton(title: "Files", index: 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                if selectedTab == 0 {
                    // Personality — file list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(personalityFiles) { file in
                                Button {
                                    Haptics.lightTap()
                                    selectedFile = file
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "doc.text.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(PokeTheme.accent)
                                        
                                        Text(file.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(PokeTheme.primaryText)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(PokeTheme.tertiaryText)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                }
                                
                                if file.id != personalityFiles.last?.id {
                                    Rectangle()
                                        .fill(PokeTheme.separator)
                                        .frame(height: 0.5)
                                        .padding(.leading, 52)
                                }
                            }
                        }
                    }
                } else {
                    // Files — blue folder grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible(), spacing: 20),
                        ], spacing: 24) {
                            ForEach(folders) { folder in
                                VStack(spacing: 8) {
                                    blueFolderIcon
                                    
                                    Text(folder.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(PokeTheme.primaryText)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationDestination(item: $selectedFile) { file in
                MarkdownViewer(file: file)
            }
        }
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button {
            Haptics.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: selectedTab == index ? .bold : .medium, design: .rounded))
                    .foregroundStyle(selectedTab == index ? PokeTheme.primaryText : PokeTheme.tertiaryText)
                
                Rectangle()
                    .fill(selectedTab == index ? PokeTheme.accent : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // Blue solid folder icon matching the reference screenshot
    private var blueFolderIcon: some View {
        ZStack {
            // Folder tab (back flap)
            Path { path in
                let w: CGFloat = 56
                let h: CGFloat = 44
                let tabW: CGFloat = 22
                let tabH: CGFloat = 6
                let r: CGFloat = 4
                
                path.move(to: CGPoint(x: r, y: tabH))
                // top-left of tab
                path.addLine(to: CGPoint(x: r, y: r))
                path.addQuadCurve(to: CGPoint(x: r + r, y: 0), control: CGPoint(x: r, y: 0))
                // top of tab
                path.addLine(to: CGPoint(x: tabW - 2, y: 0))
                path.addQuadCurve(to: CGPoint(x: tabW + 2, y: tabH), control: CGPoint(x: tabW, y: tabH))
                // across top to right
                path.addLine(to: CGPoint(x: w - r, y: tabH))
                path.addQuadCurve(to: CGPoint(x: w, y: tabH + r), control: CGPoint(x: w, y: tabH))
                // right side down
                path.addLine(to: CGPoint(x: w, y: h - r))
                path.addQuadCurve(to: CGPoint(x: w - r, y: h), control: CGPoint(x: w, y: h))
                // bottom
                path.addLine(to: CGPoint(x: r, y: h))
                path.addQuadCurve(to: CGPoint(x: 0, y: h - r), control: CGPoint(x: 0, y: h))
                // left side up
                path.addLine(to: CGPoint(x: 0, y: tabH + r))
                path.addQuadCurve(to: CGPoint(x: r, y: tabH), control: CGPoint(x: 0, y: tabH))
            }
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.25, green: 0.45, blue: 0.95), Color(red: 0.2, green: 0.35, blue: 0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 56, height: 44)
        }
    }
}

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let content: String
}

struct FolderItem: Identifiable {
    let id = UUID()
    let name: String
}

// MARK: - Markdown Viewer
struct MarkdownViewer: View {
    let file: FileItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            PokeTheme.cardBackground
                .ignoresSafeArea()
            
            ScrollView {
                Text(file.content)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundStyle(PokeTheme.primaryText)
                    .lineSpacing(5)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Haptics.navigate()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16))
                    }
                    .foregroundStyle(PokeTheme.accent)
                }
            }
        }
    }
}

// MARK: - Skills Sheet (Installed + Marketplace tabs)
struct SkillsSheetView: View {
    @State private var selectedTab = 0 // 0 = Installed, 1 = Marketplace
    @State private var selectedSkill: SkillItem? = nil
    
    let installedSkills: [SkillItem] = [
        SkillItem(name: "ACP Router", desc: "Route requests to coding agents", content: """
        # ACP Router
        
        Route requests to coding agents like Codex, Claude Code, Cursor, and Gemini.
        
        ## Usage
        When the user asks to "do this in codex" or similar, treat it as ACP harness intent and spawn via sessions_spawn with runtime: "acp".
        
        ## Supported Agents
        - OpenAI Codex
        - Claude Code
        - Cursor
        - Gemini
        """),
        SkillItem(name: "Cloud Storage", desc: "Upload & host files via CDN", content: """
        # Cloud Storage
        
        Upload, store, list, or delete files in the cloud. Files are served from a global CDN at staticfiles.net.
        
        ## Capabilities
        - Upload any file type
        - Global CDN distribution
        - Permanent or temporary hosting
        - Direct download links
        """),
        SkillItem(name: "Edit Link", desc: "Shareable markdown edit links", content: """
        # Edit Link
        
        Generate a shareable link that lets the user edit a markdown file in their browser.
        
        ## When to Use
        - User asks for a link to edit a file
        - Platforms that don't support inline editing (Telegram, iMessage, SMS)
        """),
        SkillItem(name: "Environment", desc: "Container & OS reference", content: """
        # Environment
        
        Reference for your operating system and computer environment.
        
        ## Details
        - How the container works
        - What persists across restarts
        - Package management (Homebrew, npm, bun)
        - API cloud proxy for third-party services
        """),
        SkillItem(name: "Masterclaw", desc: "Agent setup & configuration", content: """
        # Masterclaw
        
        Agent setup, capability configuration, skill installation, and provider connection setup.
        
        ## Setup Flow
        1. Check setup status
        2. Activate if pending
        3. Guide through configuration
        """),
        SkillItem(name: "Public Files", desc: "Share files via public URLs", content: """
        # Public Files
        
        Share files publicly via the Public directory.
        
        ## Usage
        Make files accessible via URL, serve HTML pages, or share generated content.
        """),
        SkillItem(name: "SupaData", desc: "Video transcripts & web scraping", content: """
        # SupaData
        
        Pull transcripts, metadata, and structured data from YouTube, TikTok, Instagram, X/Twitter, and Facebook videos. Also scrapes and crawls websites to markdown.
        """),
        SkillItem(name: "App Screenshots", desc: "App Store mockup generator", content: """
        # App Screenshots
        
        Generate App Store-ready screenshot mockups from iOS app source code.
        
        ## Process
        1. Read SwiftUI views
        2. Create HTML screen recreations
        3. Render at App Store resolution (1290x2796)
        4. Wrap in iPhone frames
        """),
        SkillItem(name: "Build Android", desc: "Build & distribute Android apps", content: """
        # Build Android
        
        Build and distribute Android apps using the Vibecode Android build service.
        
        ## Capabilities
        - Generate APKs
        - Install on devices
        - OTA distribution
        """),
        SkillItem(name: "Build iOS", desc: "Build, sign & install iOS apps", content: """
        # Build iOS
        
        Build, sign, and install iOS apps on real devices using the Vibecode signing service.
        
        ## Flow
        1. Build from Swift/SwiftUI source
        2. Sign with developer certificate
        3. Generate install link
        4. OTA install on device
        """),
        SkillItem(name: "ElevenLabs", desc: "Text-to-speech & voice AI", content: """
        # ElevenLabs
        
        Text-to-speech, multi-voice dialogue, voice conversion, sound effects, music generation, audio isolation, speech-to-text, dubbing, and voice cloning.
        """),
        SkillItem(name: "Exa Search", desc: "Web search & content extraction", content: """
        # Exa Search
        
        Web search, content extraction, similar link discovery, AI-powered answers, and multi-step research via the Exa API.
        """),
        SkillItem(name: "fal.ai", desc: "600+ generative media models", content: """
        # fal.ai
        
        Access 600+ generative media models — image, video, audio, LLMs — via HTTP.
        
        ## Supported Models
        - FLUX, SDXL (image)
        - Video generation
        - Speech-to-text / TTS
        - LLMs
        """),
        SkillItem(name: "Firecrawl", desc: "Web scraping & crawling", content: """
        # Firecrawl
        
        Scrape, search, crawl, and automate browsers via the Firecrawl API.
        """),
        SkillItem(name: "Gemini Image", desc: "Google image generation", content: """
        # Gemini Image
        
        Google's Gemini image generation API (Nano Banana).
        
        ## Capabilities
        - Text-to-image generation
        - Image editing with text instructions
        - Custom aspect ratios
        - Multi-reference image prompts
        """),
        SkillItem(name: "Readwise", desc: "Highlights & reading data", content: """
        # Readwise
        
        Access books, highlights, Reader documents, and exports from your Readwise library.
        """),
        SkillItem(name: "Skill Creator", desc: "Build & test custom skills", content: """
        # Skill Creator
        
        Create new skills, modify existing ones, run evals, and benchmark performance.
        """),
        SkillItem(name: "Google Integration", desc: "Gmail, Calendar, Drive, Docs", content: """
        # Google Integration
        
        Full Google Workspace integration — Gmail, Calendar, Drive, Docs, Sheets, Slides, Forms.
        """),
        SkillItem(name: "Notion", desc: "Pages, databases & workspace", content: """
        # Notion
        
        Manage Notion pages, databases, blocks, and workspace content via the Notion API.
        """),
        SkillItem(name: "ECharts", desc: "Data visualization charts", content: """
        # ECharts
        
        Generate rich data visualizations and interactive charts using Apache ECharts.
        """),
        SkillItem(name: "Excalidraw", desc: "Diagram generation", content: """
        # Excalidraw
        
        Create diagrams, wireframes, and visual sketches using Excalidraw.
        """),
    ]
    
    let marketplaceSkills: [SkillItem] = [
        SkillItem(name: "Stripe", desc: "Payment processing & billing", content: "# Stripe\n\nManage payments, subscriptions, invoices, and billing via the Stripe API."),
        SkillItem(name: "GitHub", desc: "Repos, issues, PRs & actions", content: "# GitHub\n\nManage repositories, issues, pull requests, and GitHub Actions workflows."),
        SkillItem(name: "Slack", desc: "Messaging & workspace automation", content: "# Slack\n\nSend messages, manage channels, and automate workflows in Slack workspaces."),
        SkillItem(name: "Spotify", desc: "Music playback & playlists", content: "# Spotify\n\nControl playback, manage playlists, and search the Spotify catalog."),
        SkillItem(name: "Linear", desc: "Project & issue tracking", content: "# Linear\n\nCreate and manage issues, projects, and cycles in Linear."),
        SkillItem(name: "Figma", desc: "Design file access & inspection", content: "# Figma\n\nRead design files, inspect components, and extract design tokens from Figma."),
        SkillItem(name: "Vercel", desc: "Deploy & manage web apps", content: "# Vercel\n\nDeploy, manage, and monitor web applications on Vercel."),
        SkillItem(name: "Supabase", desc: "Database & auth management", content: "# Supabase\n\nManage Postgres databases, authentication, storage, and edge functions."),
        SkillItem(name: "Twilio", desc: "SMS, voice & video comms", content: "# Twilio\n\nSend SMS, make calls, and manage communication workflows via Twilio."),
        SkillItem(name: "Airtable", desc: "Spreadsheet-database hybrid", content: "# Airtable\n\nCreate, read, and update records in Airtable bases and tables."),
        SkillItem(name: "Midjourney", desc: "AI image generation", content: "# Midjourney\n\nGenerate high-quality images using Midjourney's diffusion models."),
        SkillItem(name: "Resend", desc: "Transactional email API", content: "# Resend\n\nSend transactional and marketing emails via the Resend API."),
        SkillItem(name: "Pinecone", desc: "Vector database & search", content: "# Pinecone\n\nStore, index, and query vector embeddings for semantic search and RAG."),
        SkillItem(name: "Posthog", desc: "Product analytics & tracking", content: "# Posthog\n\nTrack events, analyze funnels, and manage feature flags with Posthog."),
        SkillItem(name: "Replicate", desc: "Run open-source ML models", content: "# Replicate\n\nRun open-source machine learning models in the cloud via Replicate."),
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                Text("Skills")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(PokeTheme.primaryText)
                    .padding(.top, 24)
                    .padding(.bottom, 4)
                
                Text(selectedTab == 0 ? "\(installedSkills.count) installed" : "\(marketplaceSkills.count) available")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(PokeTheme.secondaryText)
                    .padding(.bottom, 12)
                
                // Tab picker: Installed | Marketplace
                HStack(spacing: 0) {
                    skillTabButton(title: "Installed", index: 0)
                    skillTabButton(title: "Marketplace", index: 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 0) {
                        let currentSkills = selectedTab == 0 ? installedSkills : marketplaceSkills
                        ForEach(Array(currentSkills.enumerated()), id: \.element.id) { index, skill in
                            Button {
                                Haptics.lightTap()
                                selectedSkill = skill
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(skill.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(PokeTheme.primaryText)
                                        
                                        Text(skill.desc)
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundStyle(PokeTheme.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedTab == 1 {
                                        Text("Install")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule().fill(PokeTheme.accent)
                                            )
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(PokeTheme.tertiaryText)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                            }
                            
                            if index < currentSkills.count - 1 {
                                Rectangle()
                                    .fill(PokeTheme.separator)
                                    .frame(height: 0.5)
                                    .padding(.leading, 20)
                            }
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedSkill) { skill in
                SkillDetailViewer(skill: skill)
            }
        }
    }
    
    private func skillTabButton(title: String, index: Int) -> some View {
        Button {
            Haptics.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: selectedTab == index ? .bold : .medium, design: .rounded))
                    .foregroundStyle(selectedTab == index ? PokeTheme.primaryText : PokeTheme.tertiaryText)
                
                Rectangle()
                    .fill(selectedTab == index ? PokeTheme.accent : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct SkillItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let desc: String
    let content: String
}

// MARK: - Skill Detail Viewer
struct SkillDetailViewer: View {
    let skill: SkillItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            PokeTheme.cardBackground
                .ignoresSafeArea()
            
            ScrollView {
                Text(skill.content)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundStyle(PokeTheme.primaryText)
                    .lineSpacing(5)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(skill.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Haptics.navigate()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Skills")
                            .font(.system(size: 16))
                    }
                    .foregroundStyle(PokeTheme.accent)
                }
            }
        }
    }
}

// MARK: - Connections Sheet
struct ConnectionsSheetView: View {
    let connections: [(name: String, status: String)] = [
        ("Gmail", "Connected"),
        ("Google Calendar", "Connected"),
        ("Google Drive", "Connected"),
        ("Google Docs", "Connected"),
        ("Google Sheets", "Connected"),
        ("Google Slides", "Connected"),
        ("Google Forms", "Connected"),
        ("Granola", "Connected"),
        ("Notion", "Connected"),
        ("Telegram", "Connected"),
        ("Texting", "Connected"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Connections")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(PokeTheme.primaryText)
                .padding(.top, 24)
                .padding(.bottom, 4)
            
            Text("\(connections.count) connected")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(PokeTheme.secondaryText)
                .padding(.bottom, 16)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(connections.enumerated()), id: \.offset) { index, conn in
                        HStack {
                            Text(conn.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(PokeTheme.primaryText)
                            
                            Spacer()
                            
                            Text(conn.status)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        
                        if index < connections.count - 1 {
                            Rectangle()
                                .fill(PokeTheme.separator)
                                .frame(height: 0.5)
                                .padding(.leading, 20)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Cron Jobs Sheet
struct CronJobsSheetView: View {
    let jobs: [(name: String, schedule: String)] = [
        ("Email Check", "Every 30 min · 9 AM – 9 PM"),
        ("Calendar Scan", "Every 2 hours · 8 AM – 10 PM"),
        ("Metrics Report", "Daily · 9:00 AM"),
        ("Memory Maintenance", "Weekly · Sunday 3 AM"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Cron Jobs")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(PokeTheme.primaryText)
                .padding(.top, 24)
                .padding(.bottom, 4)
            
            Text("\(jobs.count) active")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(PokeTheme.secondaryText)
                .padding(.bottom, 16)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(jobs.enumerated()), id: \.offset) { index, job in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(job.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(PokeTheme.primaryText)
                                
                                Text(job.schedule)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(PokeTheme.secondaryText)
                            }
                            
                            Spacer()
                            
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        
                        if index < jobs.count - 1 {
                            Rectangle()
                                .fill(PokeTheme.separator)
                                .frame(height: 0.5)
                                .padding(.leading, 20)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Chat Sheet (Telegram + iMessage with app icons)
struct ChatSheetView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Chat")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(PokeTheme.primaryText)
                .padding(.top, 24)
                .padding(.bottom, 24)
            
            VStack(spacing: 12) {
                // iMessage
                Button {
                    Haptics.heavyTap()
                    if let url = URL(string: "sms:") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 14) {
                        // iMessage icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.34, green: 0.85, blue: 0.37), Color(red: 0.2, green: 0.72, blue: 0.25)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 42, height: 42)
                            
                            Image(systemName: "message.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("iMessage")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(PokeTheme.primaryText)
                            
                            Text("Open in Messages")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(PokeTheme.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(PokeTheme.tertiaryText)
                    }
                    .padding(16)
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Telegram
                Button {
                    Haptics.heavyTap()
                    if let url = URL(string: "tg://") {
                        UIApplication.shared.open(url)
                    } else if let url = URL(string: "https://t.me/") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 14) {
                        // Telegram icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.25, green: 0.65, blue: 0.96), Color(red: 0.15, green: 0.52, blue: 0.88)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 42, height: 42)
                            
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Telegram")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(PokeTheme.primaryText)
                            
                            Text("Open in Telegram")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(PokeTheme.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(PokeTheme.tertiaryText)
                    }
                    .padding(16)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

// MARK: - Settings
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Profile header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(PokeTheme.accent)
                        .frame(width: 72, height: 72)
                    
                    Text("R")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Text("Riley")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(PokeTheme.primaryText)
                
                Text("chorus.com")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(PokeTheme.secondaryText)
            }
            .padding(.top, 28)
            .padding(.bottom, 24)
            
            // Settings items
            ScrollView {
                VStack(spacing: 0) {
                    settingsRow(title: "Agent Name", value: "Zampa")
                    settingsRow(title: "Model", value: "Claude Opus 4")
                    settingsRow(title: "Heartbeat", value: "Every 30 min")
                    settingsRow(title: "Skills", value: "21 installed")
                    settingsRow(title: "Connections", value: "11 connected")
                    
                    Rectangle()
                        .fill(PokeTheme.separator)
                        .frame(height: 0.5)
                        .padding(.vertical, 8)
                    
                    settingsRow(title: "Appearance", value: "System")
                    settingsRow(title: "Notifications", value: "On")
                    settingsRow(title: "Version", value: "1.0.0")
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func settingsRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(PokeTheme.primaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(PokeTheme.secondaryText)
        }
        .padding(.vertical, 13)
    }
}