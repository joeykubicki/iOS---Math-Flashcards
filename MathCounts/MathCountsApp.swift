import SwiftUI

// Controls the entire navigation stack. Calling goToRoot() resets
// the NavigationStack back to HomeView from anywhere in the app.
class AppNavigationState: ObservableObject {
    @Published var rootID = UUID()

    func goToRoot() {
        rootID = UUID()
    }
}

@main
struct MathCountsApp: App {
    @StateObject private var navState = AppNavigationState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navState)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var navState: AppNavigationState

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .id(navState.rootID)
    }
}
