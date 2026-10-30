import SwiftUI

struct TestConfigView: View {
    let operation: Operation
    
    @StateObject private var settings = SettingsManager.shared
    @State private var studentName: String = ""
    @State private var selectedDifficulty: Int = 0  // index into picker options
    @State private var selectedNumQuestions: Int = 3 // index (3 = 20 questions)
    @State private var selectedTime: Int = 0 // index (0 = unlimited)
    @State private var multiplicationLevel: Int = 0 // index for mult level picker
    @State private var navigateToTest = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isIPad: Bool { horizontalSizeClass == .regular }
    var pickerHeight: CGFloat { verticalSizeClass == .compact ? 80 : (isIPad ? 180 : 120) }
    
    let timeOptions = ["Unlimited", "0:30", "1:00", "1:30", "2:00", "2:30", "3:00", "5:00"]
    let questionOptions = [5, 10, 15, 20, 25, 30, 40, 50]
    
    var difficultyOptions: [String] {
        if operation == .multiplication || operation == .division {
            return MultiplicationLevel.allCases.map { $0.label }
        }
        return Difficulty.allCases.map { $0.label }
    }
    
    var accentColor: Color {
        switch operation {
        case .addition: return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .subtraction: return Color(red: 0.2, green: 0.6, blue: 0.8)
        case .multiplication: return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .division: return Color(red: 0.6, green: 0.3, blue: 0.85)
        }
    }
    
    var body: some View {
        GeometryReader { geo in
        let isLargeIPad = min(geo.size.width, geo.size.height) >= 1000
        let contentMaxWidth: CGFloat = isIPad ? geo.size.width * 0.70 : .infinity
        let labelFont: Font = isLargeIPad ? .title2 : (isIPad ? .title3 : .subheadline)
        let fieldFont: Font = isLargeIPad ? .title2 : (isIPad ? .title3 : .body)
        let pickerFont: Font = isLargeIPad ? .title2 : .body
        let startButtonFont: Font = isLargeIPad ? .title : (isIPad ? .title2 : .headline)
        let startButtonVerticalPadding: CGFloat = isLargeIPad ? 44 : (isIPad ? 22 : 16)
        let compactHeight = geo.size.height < 700 || verticalSizeClass == .compact
        let contentTopPadding: CGFloat = compactHeight ? 12 : (isLargeIPad ? 80 : (isIPad ? 45 : 28))
        let contentBottomPadding: CGFloat = compactHeight ? 16 : 24
        let settingsTilePadding: CGFloat = compactHeight ? 16 : (isLargeIPad ? 28 : 20)
        let settingsSpacing: CGFloat = compactHeight ? 14 : 20
        let effectivePickerHeight: CGFloat = compactHeight ? 92 : pickerHeight
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: settingsSpacing) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Student Name (optional)", systemImage: "person")
                            .font(labelFont)
                            .foregroundStyle(.secondary)
                        TextField("Enter name", text: $studentName)
                            .font(fieldFont)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                    }
                    
                    // Difficulty / Level
                    VStack(alignment: .leading, spacing: 8) {
                        Label(operation == .multiplication || operation == .division ? "Level" : "Difficulty",
                              systemImage: "chart.bar")
                            .font(labelFont)
                            .foregroundStyle(.secondary)
                        
                        Picker("Difficulty", selection: $selectedDifficulty) {
                            ForEach(0..<difficultyOptions.count, id: \.self) { i in
                                Text(difficultyOptions[i])
                                    .font(pickerFont)
                                    .tag(i)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: effectivePickerHeight)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                    
                    // Number of Questions
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Number of Questions", systemImage: "number")
                            .font(labelFont)
                            .foregroundStyle(.secondary)
                        
                        Picker("Questions", selection: $selectedNumQuestions) {
                            ForEach(0..<questionOptions.count, id: \.self) { i in
                                Text("\(questionOptions[i])")
                                    .font(pickerFont)
                                    .tag(i)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: effectivePickerHeight)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                    
                    // Time Limit
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Time Limit", systemImage: "clock")
                            .font(labelFont)
                            .foregroundStyle(.secondary)
                        
                        Picker("Time", selection: $selectedTime) {
                            ForEach(0..<timeOptions.count, id: \.self) { i in
                                Text(timeOptions[i])
                                    .font(pickerFont)
                                    .tag(i)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: effectivePickerHeight)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                }
                .padding(settingsTilePadding)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 8)
                )
                .padding(.horizontal, 20)
                .padding(.top, contentTopPadding)
                .padding(.bottom, contentBottomPadding)
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                NavigationLink(destination: TestView(
                    operation: operation,
                    difficulty: resolvedDifficulty,
                    numQuestions: questionOptions[selectedNumQuestions],
                    timeString: timeOptions[selectedTime],
                    studentName: studentName.isEmpty ? "Student" : studentName
                )) {
                    Text("Start Test")
                        .font(startButtonFont)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, startButtonVerticalPadding)
                        .background(accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
            }
        }
        }
        .navigationTitle("Configure Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if studentName.isEmpty {
                studentName = settings.defaultStudentName
            }
        }
    }
    
    var resolvedDifficulty: Int {
        if operation == .multiplication || operation == .division {
            return MultiplicationLevel.allCases[selectedDifficulty].rawValue
        }
        return Difficulty.allCases[selectedDifficulty].rawValue
    }
}
