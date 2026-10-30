import SwiftUI

struct SavedTestsView: View {
    let filterByUser: String?
    
    @State private var tests: [TestResult] = []
    @State private var showDeleteConfirm = false
    @State private var searchText: String = ""
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var isIPad: Bool { horizontalSizeClass == .regular }
    
    var filteredTests: [TestResult] {
        if searchText.isEmpty { return tests }
        return tests.filter {
            $0.user.localizedCaseInsensitiveContains(searchText) ||
            $0.operation.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            if tests.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: isIPad ? 80 : 56))
                        .foregroundStyle(.tertiary)
                    Text("No Saved Tests")
                        .font(isIPad ? .title : .title3)
                        .fontWeight(.semibold)
                    Text("Complete a test to see it here.")
                        .font(isIPad ? .title3 : .subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                List {
                    ForEach(filteredTests) { test in
                        NavigationLink(destination: SavedTestDetailView(test: test)) {
                            SavedTestRow(test: test)
                        }
                    }
                    .onDelete(perform: deleteTests)
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search by name or operation")
                .overlay {
                    if filteredTests.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(.tertiary)
                            Text("No results for \"\(searchText)\"")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                    }
                }
            }
        }
        .navigationTitle(filterByUser != nil ? "\(filterByUser!)'s Tests" : "Saved Tests")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !tests.isEmpty {
                    Button(role: .destructive, action: { showDeleteConfirm = true }) {
                        Label("Delete All", systemImage: "trash")
                    }
                }
            }
        }
        .confirmationDialog("Delete all saved tests?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete All Tests", role: .destructive) {
                DatabaseManager.shared.deleteAllTests()
                loadTests()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
        .onAppear(perform: loadTests)
    }
    
    func loadTests() {
        if let name = filterByUser {
            tests = DatabaseManager.shared.fetchTestsByUser(name)
        } else {
            tests = DatabaseManager.shared.fetchAllTests()
        }
    }
    
    func deleteTests(at offsets: IndexSet) {
        for offset in offsets {
            let test = filteredTests[offset]
            DatabaseManager.shared.deleteTest(id: test.testId)
        }
        loadTests()
    }
}

struct SavedTestRow: View {
    let test: TestResult
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var isIPad: Bool { horizontalSizeClass == .regular }

    var operationColor: Color {
        switch test.operation {
        case "Addition": return Color(red: 0.9, green: 0.3, blue: 0.3)
        case "Subtraction": return Color(red: 0.2, green: 0.6, blue: 0.8)
        case "Multiplication": return Color(red: 0.2, green: 0.7, blue: 0.3)
        case "Division": return Color(red: 0.6, green: 0.3, blue: 0.85)
        default: return .gray
        }
    }
    
    var operationSign: String {
        switch test.operation {
        case "Addition": return "+"
        case "Subtraction": return "−"
        case "Multiplication": return "×"
        case "Division": return "÷"
        default: return "?"
        }
    }
    
    var gradeColor: Color {
        if test.percentage >= 90 { return .green }
        if test.percentage >= 70 { return .orange }
        return .red
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Operation badge
            ZStack {
                Circle()
                    .fill(operationColor.opacity(0.15))
                    .frame(width: isIPad ? 60 : 44, height: isIPad ? 60 : 44)
                Text(operationSign)
                    .font(.system(size: isIPad ? 28 : 20, weight: .light))
                    .foregroundStyle(operationColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(test.user)
                    .font(isIPad ? .title3 : .subheadline)
                    .fontWeight(.semibold)
                Text("\(test.operation) · \(test.difficultyLabel)")
                    .font(isIPad ? .subheadline : .caption)
                    .foregroundStyle(.secondary)
                Text(test.date, style: .date)
                    .font(isIPad ? .caption : .caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text(test.score)
                    .font(isIPad ? .title3 : .subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(gradeColor)
                Text(String(format: "%.0f%%", test.percentage))
                    .font(isIPad ? .subheadline : .caption)
                    .foregroundStyle(gradeColor.opacity(0.7))
            }
        }
        .padding(.vertical, isIPad ? 10 : 4)
    }
}

// MARK: - Saved Test Detail

struct SavedTestDetailView: View {
    let test: TestResult
    
    @State private var questions: [QuestionResult] = []
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var isIPad: Bool { horizontalSizeClass == .regular }
    
    var operationColor: Color {
        switch test.operation {
        case "Addition": return Color(red: 0.9, green: 0.3, blue: 0.3)
        case "Subtraction": return Color(red: 0.2, green: 0.6, blue: 0.8)
        case "Multiplication": return Color(red: 0.2, green: 0.7, blue: 0.3)
        case "Division": return Color(red: 0.6, green: 0.3, blue: 0.85)
        default: return .gray
        }
    }
    
    var operationSign: String {
        switch test.operation {
        case "Addition": return "+"
        case "Subtraction": return "−"
        case "Multiplication": return "×"
        case "Division": return "÷"
        default: return "?"
        }
    }
    
    var gradeColor: Color {
        if test.percentage >= 90 { return .green }
        if test.percentage >= 70 { return .orange }
        return .red
    }
    
    var gradeLetter: String {
        if test.percentage >= 90 { return "A" }
        if test.percentage >= 80 { return "B" }
        if test.percentage >= 70 { return "C" }
        if test.percentage >= 60 { return "D" }
        return "F"
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header card
                    VStack(spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(test.user)
                                    .font(isIPad ? .largeTitle : .title2)
                                    .fontWeight(.bold)
                                Text(test.date, style: .date)
                                    .font(isIPad ? .title3 : .subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .stroke(gradeColor.opacity(0.25), lineWidth: 8)
                                    .frame(width: isIPad ? 100 : 70, height: isIPad ? 100 : 70)
                                Circle()
                                    .trim(from: 0, to: CGFloat(test.percentage / 100))
                                    .stroke(gradeColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: isIPad ? 100 : 70, height: isIPad ? 100 : 70)
                                    .rotationEffect(.degrees(-90))
                                VStack(spacing: 1) {
                                    Text(gradeLetter)
                                        .font(isIPad ? .title2 : .title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(gradeColor)
                                    Text(String(format: "%.0f%%", test.percentage))
                                        .font(isIPad ? .caption : .caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        Divider()
                        
                        HStack(spacing: 0) {
                            DetailStat(label: "Operation", value: test.operation, color: operationColor)
                            DetailStat(label: "Difficulty", value: test.difficultyLabel, color: .primary)
                            DetailStat(label: "Score", value: test.score, color: gradeColor)
                        }
                        
                        HStack(spacing: 0) {
                            DetailStat(label: "Time Given", value: test.timeAllotted, color: .primary)
                            DetailStat(label: "Time Left", value: test.timeRemaining, color: .blue)
                            DetailStat(label: "Questions", value: "\(test.numQuestions)", color: .primary)
                        }
                    }
                    .padding(18)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Questions list
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Questions")
                            .font(isIPad ? .title2 : .headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 1) {
                            ForEach(questions) { q in
                                HStack {
                                    Text("#\(q.questionNum)")
                                        .font(isIPad ? .subheadline : .caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: isIPad ? 40 : 28, alignment: .leading)
                                    
                                    Text("\(q.firstNum) \(operationSign) \(q.secondNum) = \(q.answer)")
                                        .font(.system(isIPad ? .title3 : .body, design: .monospaced))
                                    
                                    Spacer()
                                    
                                    if q.isCorrect {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else {
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.red)
                                            if !q.studentAnswer.isEmpty {
                                                Text(q.studentAnswer)
                                                    .font(isIPad ? .caption : .caption2)
                                                    .foregroundStyle(.red)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, isIPad ? 14 : 10)
                                .background(Color(.secondarySystemGroupedBackground))
                            }
                        }
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("\(test.user)'s Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            questions = DatabaseManager.shared.fetchQuestions(testId: test.testId)
        }
    }
}

struct DetailStat: View {
    let label: String
    let value: String
    let color: Color
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(isIPad ? .title3 : .subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(isIPad ? .caption : .caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
