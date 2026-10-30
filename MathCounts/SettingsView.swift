import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    @AppStorage("default_student_name") var defaultStudentName: String = ""
}

// Tracks completed tests and decides when to ask for an App Store rating.
// iOS itself suppresses the prompt for users who already rated this version
// and caps it at 3 displays per year, so we only control *when* we ask.
enum ReviewPrompt {
    static let milestones = [1, 5, 10]

    private static let completedTestsKey = "completed_tests_count"
    private static let lastPromptedKey = "last_review_prompt_milestone"

    static func recordCompletedTest() {
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: completedTestsKey) + 1, forKey: completedTestsKey)
    }

    // The highest milestone reached that we haven't asked at yet, if any.
    // Using "reached" rather than "exactly equal" means a prompt that couldn't
    // be shown (e.g. user left the results screen early) is retried next test.
    static var dueMilestone: Int? {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: completedTestsKey)
        guard let reached = milestones.last(where: { $0 <= count }),
              reached > defaults.integer(forKey: lastPromptedKey) else { return nil }
        return reached
    }

    static func markPrompted(_ milestone: Int) {
        UserDefaults.standard.set(milestone, forKey: lastPromptedKey)
    }
}

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var showDeleteConfirm = false
    @State private var showDeletedToast = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            List {
                Section("General") {
                    HStack {
                        Label("Default Student Name", systemImage: "person")
                        Spacer()
                        TextField("Optional", text: $settings.defaultStudentName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Data") {
                    NavigationLink(destination: SavedTestsView(filterByUser: nil)) {
                        Label("View Saved Tests", systemImage: "list.bullet.clipboard")
                    }

                    Button(role: .destructive, action: { showDeleteConfirm = true }) {
                        Label("Delete All Test Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }

                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)

            if showDeletedToast {
                VStack {
                    Spacer()
                    Text("All test data deleted")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.regularMaterial)
                        .cornerRadius(20)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Delete All Test Data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete All Data", role: .destructive) {
                DatabaseManager.shared.deleteAllTests()
                withAnimation { showDeletedToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showDeletedToast = false }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all saved tests and results. This cannot be undone.")
        }
    }
}
