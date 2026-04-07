import SwiftUI

struct HomeView: View {
    @State private var showFiles = false
    @State private var showSkills = false
    @State private var showConnections = false
    @State private var showCronjobs = false
    @State private var showChat = false
    @State private var showSettings = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Dark gradient background - no blue, pure greys
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(white: 0.06), Color(white: 0.11)]
                    : [Color(white: 0.955), Color(white: 0.975)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar — just the profile avatar on the right
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                Spacer()
                
                // Agent info right above buttons
                agentInfo
                    .padding(.bottom, 28)
                
                // Bottom tab grid: 2 on top, 3 on bottom
                bottomTabs
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showFiles) {
            FilesSheetView()
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
                .presentationBackground(PokeTheme.cardBackground)
                .onAppear { Haptics.sheetOpen() }
        }
        .sheet(isPresented: $showSkills) {
            SkillsSheetView()
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
                .presentationBackground(PokeTheme.cardBackground)
                .onAppear { Haptics.sheetOpen() }
        }
        .sheet(isPresented: $showConnections) {
            ConnectionsSheetView()
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
                .presentationBackground(PokeTheme.cardBackground)
                .onAppear { Haptics.sheetOpen() }
        }
        .sheet(isPresented: $showCronjobs) {
            CronJobsSheetView()
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
                .presentationBackground(PokeTheme.cardBackground)
                .onAppear { Haptics.sheetOpen() }
        }
        .sheet(isPresented: $showChat) {
            ChatSheetView()
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
                .presentationBackground(PokeTheme.cardBackground)
                .onAppear { Haptics.sheetOpen() }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
                .presentationBackground(PokeTheme.cardBackground)
                .onAppear { Haptics.sheetOpen() }
        }
    }
    
    // MARK: - Top Bar (cleaned: no "OpenClaw", no date)
    private var topBar: some View {
        HStack {
            Spacer()
            
            Button {
                Haptics.tap()
                showSettings = true
            } label: {
                ZStack {
                    Circle()
                        .fill(PokeTheme.accent)
                        .frame(width: 34, height: 34)
                    
                    Text("R")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    // MARK: - Agent Info
    private var agentInfo: some View {
        VStack(spacing: 6) {
            Text("Zampa")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(PokeTheme.primaryText)
            
            Text("Your chorus.com agent")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(PokeTheme.secondaryText)
        }
    }
    
    // MARK: - Bottom Tabs
    private var bottomTabs: some View {
        VStack(spacing: 10) {
            // Row 1: 2 wider buttons
            HStack(spacing: 10) {
                ActionButton(icon: "clock", label: "Cron Jobs") {
                    showCronjobs = true
                }
                
                ActionButton(icon: "link", label: "Connections") {
                    showConnections = true
                }
            }
            
            // Row 2: 3 buttons
            HStack(spacing: 10) {
                ActionButton(icon: "folder.fill", label: "Files") {
                    showFiles = true
                }
                
                ActionButton(icon: "dumbbell.fill", label: "Skills") {
                    showSkills = true
                }
                
                ActionButton(icon: "message.fill", label: "Chat") {
                    showChat = true
                }
            }
        }
    }
}
