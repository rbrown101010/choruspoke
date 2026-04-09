import SwiftUI

@main
struct PokeApp: App {
    @StateObject private var appModel = RunnerAppModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .preferredColorScheme(.dark)
            .environmentObject(appModel)
            .task {
                await appModel.bootstrapApp()
            }
        }
    }
}
