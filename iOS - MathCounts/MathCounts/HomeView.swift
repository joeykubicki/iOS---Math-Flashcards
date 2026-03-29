import SwiftUI

struct HomeView: View {
    @State private var selectedOperation: Operation? = nil
    @State private var showTestConfig = false
    @State private var showChallenge = false
    @State private var showSavedTests = false
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text("Welcome!")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                    Text("Select an operation to begin")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 28)
                
                // Operation Buttons
                VStack(spacing: 14) {
                    HStack(spacing: 14) {
                        OperationButton(op: .addition, isSelected: selectedOperation == .addition) {
                            selectedOperation = selectedOperation == .addition ? nil : .addition
                        }
                        OperationButton(op: .subtraction, isSelected: selectedOperation == .subtraction) {
                            selectedOperation = selectedOperation == .subtraction ? nil : .subtraction
                        }
                    }
                    HStack(spacing: 14) {
                        OperationButton(op: .multiplication, isSelected: selectedOperation == .multiplication) {
                            selectedOperation = selectedOperation == .multiplication ? nil : .multiplication
                        }
                        OperationButton(op: .division, isSelected: selectedOperation == .division) {
                            selectedOperation = selectedOperation == .division ? nil : .division
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Start Test Button
                if let op = selectedOperation {
                    NavigationLink(destination: TestConfigView(operation: op)) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start \(op.rawValue) Test")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(operationColor(op))
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.top, 20)
                }
                
                Spacer()
                
                // Challenge Button
                NavigationLink(destination: ChallengeMenuView()) {
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Challenge Mode")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Test your skills in special challenges")
                                .font(.caption)
                                .opacity(0.85)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [Color(red: 0.9, green: 0.6, blue: 0.1), Color(red: 1.0, green: 0.75, blue: 0.2)],
                                      startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 14)
                
                // Bottom nav
                HStack(spacing: 0) {
                    NavigationLink(destination: SavedTestsView(filterByUser: nil)) {
                        VStack(spacing: 4) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.title2)
                            Text("Saved Tests")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    NavigationLink(destination: SettingsView()) {
                        VStack(spacing: 4) {
                            Image(systemName: "gearshape")
                                .font(.title2)
                            Text("Settings")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
                .foregroundStyle(.secondary)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16, corners: [.topLeft, .topRight])
            }
        }
        .navigationBarHidden(true)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedOperation)
    }
    
    func operationColor(_ op: Operation) -> Color {
        switch op {
        case .addition: return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .subtraction: return Color(red: 0.2, green: 0.6, blue: 0.8)
        case .multiplication: return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .division: return Color(red: 0.6, green: 0.3, blue: 0.85)
        }
    }
}

struct OperationButton: View {
    let op: Operation
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(op.sign)
                .font(.system(size: 128, weight: .heavy, design: .rounded))
                .foregroundStyle(isSelected ? .white : bgColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? bgColor : Color(.secondarySystemGroupedBackground))
                    .shadow(color: isSelected ? bgColor.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? .clear : Color(.separator).opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
    
    var bgColor: Color {
        switch op {
        case .addition: return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .subtraction: return Color(red: 0.2, green: 0.6, blue: 0.8)
        case .multiplication: return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .division: return Color(red: 0.6, green: 0.3, blue: 0.85)
        }
    }
}

// Corner radius helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
