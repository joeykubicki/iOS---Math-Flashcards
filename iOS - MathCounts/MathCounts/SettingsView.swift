import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("settings_password_enabled") var passwordEnabled: Bool = false
    @AppStorage("settings_password") var password: String = ""
    @AppStorage("default_student_name") var defaultStudentName: String = ""
    
    func verifyPassword(_ input: String) -> Bool {
        return input == password
    }
}

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var showCreatePassword = false
    @State private var showChangePassword = false
    @State private var showVerifyPassword = false
    @State private var showDeleteConfirm = false
    @State private var showDeletedToast = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            List {
                // General
                Section("General") {
                    HStack {
                        Label("Default Student Name", systemImage: "person")
                        Spacer()
                        TextField("Optional", text: $settings.defaultStudentName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Security
                Section("Security") {
                    Toggle(isOn: $settings.passwordEnabled) {
                        Label("Settings Password", systemImage: "lock")
                    }
                    .onChange(of: settings.passwordEnabled) { _, enabled in
                        if enabled && settings.password.isEmpty {
                            showCreatePassword = true
                        } else if !enabled {
                            settings.password = ""
                        }
                    }
                    
                    if settings.passwordEnabled && !settings.password.isEmpty {
                        Button(action: { showChangePassword = true }) {
                            Label("Change Password", systemImage: "key")
                        }
                    }
                }
                
                // Data
                Section("Data") {
                    NavigationLink(destination: SavedTestsView(filterByUser: nil)) {
                        Label("View Saved Tests", systemImage: "list.bullet.clipboard")
                    }
                    
                    Button(role: .destructive, action: { showDeleteConfirm = true }) {
                        Label("Delete All Test Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("2.2")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://apps.apple.com")!) {
                        Label("Rate This App", systemImage: "star")
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            // Toast
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
        .sheet(isPresented: $showCreatePassword) {
            CreatePasswordSheet(isPresented: $showCreatePassword) { newPass in
                settings.password = newPass
                if newPass.isEmpty { settings.passwordEnabled = false }
            }
        }
        .sheet(isPresented: $showChangePassword) {
            CreatePasswordSheet(isPresented: $showChangePassword, isChange: true) { newPass in
                settings.password = newPass
            }
        }
        .confirmationDialog("Delete All Test Data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete All Data", role: .destructive) {
                DatabaseManager.shared.deleteAllTests()
                withAnimation {
                    showDeletedToast = true
                }
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

struct CreatePasswordSheet: View {
    @Binding var isPresented: Bool
    var isChange: Bool = false
    let onSave: (String) -> Void
    
    @State private var password1: String = ""
    @State private var password2: String = ""
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Password", text: $password1)
                    SecureField("Confirm Password", text: $password2)
                } header: {
                    Text(isChange ? "Enter new password" : "Create a password for Settings")
                } footer: {
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isChange ? "Change Password" : "Create Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !password1.isEmpty else {
                            errorMessage = "Password cannot be empty."; return
                        }
                        guard password1 == password2 else {
                            errorMessage = "Passwords do not match."; return
                        }
                        onSave(password1)
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct PasswordGateView: View {
    let onUnlock: () -> Void
    @State private var input: String = ""
    @State private var shake: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Enter Password")
                .font(.title2)
                .fontWeight(.semibold)
            
            SecureField("Password", text: $input)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
                .offset(x: shake ? -10 : 0)
                .animation(shake ? .default.repeatCount(3, autoreverses: true) : .default, value: shake)
            
            Button("Unlock") {
                if SettingsManager.shared.verifyPassword(input) {
                    onUnlock()
                } else {
                    shake = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = false }
                    input = ""
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
