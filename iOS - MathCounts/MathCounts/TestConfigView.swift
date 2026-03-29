import SwiftUI

struct TestConfigView: View {
    let operation: Operation
    
    @State private var studentName: String = ""
    @State private var selectedDifficulty: Int = 0  // index into picker options
    @State private var selectedNumQuestions: Int = 2 // index
    @State private var selectedTime: Int = 0 // index (0 = unlimited)
    @State private var multiplicationLevel: Int = 0 // index for mult level picker
    @State private var navigateToTest = false
    @Environment(\.dismiss) var dismiss
    
    let timeOptions = ["Unlimited", "0:30", "1:00", "1:30", "2:00", "2:30", "3:00", "5:00"]
    let questionOptions = [5, 10, 15, 20, 25, 30, 40]
    
    var difficultyOptions: [String] {
        if operation == .multiplication || operation == .division {
            if operation == .multiplication {
                return MultiplicationLevel.allCases.map { $0.label }
            } else {
                return MultiplicationLevel.allCases.map { $0.label }
            }
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
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {                    
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Student Name (optional)", systemImage: "person")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("Enter name", text: $studentName)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Difficulty / Level
                    VStack(alignment: .leading, spacing: 8) {
                        Label(operation == .multiplication || operation == .division ? "Level" : "Difficulty",
                              systemImage: "chart.bar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Picker("Difficulty", selection: $selectedDifficulty) {
                            ForEach(0..<difficultyOptions.count, id: \.self) { i in
                                Text(difficultyOptions[i]).tag(i)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Number of Questions
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Number of Questions", systemImage: "number")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Picker("Questions", selection: $selectedNumQuestions) {
                            ForEach(0..<questionOptions.count, id: \.self) { i in
                                Text("\(questionOptions[i])").tag(i)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Time Limit
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Time Limit", systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Picker("Time", selection: $selectedTime) {
                            ForEach(0..<timeOptions.count, id: \.self) { i in
                                Text(timeOptions[i]).tag(i)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            
            // Start button pinned at bottom
            VStack {
                Spacer()
                NavigationLink(destination: TestView(
                    operation: operation,
                    difficulty: resolvedDifficulty,
                    numQuestions: questionOptions[selectedNumQuestions],
                    timeString: timeOptions[selectedTime],
                    studentName: studentName.isEmpty ? "Student" : studentName
                )) {
                    Text("Start Test")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Configure Test")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var resolvedDifficulty: Int {
        if operation == .multiplication || operation == .division {
            return MultiplicationLevel.allCases[selectedDifficulty].rawValue
        }
        return Difficulty.allCases[selectedDifficulty].rawValue
    }
}
