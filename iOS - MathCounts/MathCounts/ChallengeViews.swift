import SwiftUI

struct ChallengeMenuView: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(ChallengeMode.allCases, id: \.rawValue) { mode in
                        NavigationLink(destination: ChallengeTestView(mode: mode)) {
                            ChallengeCard(mode: mode)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Challenge Mode")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ChallengeCard: View {
    let mode: ChallengeMode
    
    var icon: String {
        switch mode {
        case .squares: return "square.on.square"
        case .percentages: return "percent"
        case .tenQuestion: return "10.circle"
        case .multiplicationMadness: return "xmark.circle"
        case .twoMinuteDrill: return "timer"
        }
    }
    
    var color: Color {
        switch mode {
        case .squares: return Color(red: 0.9, green: 0.45, blue: 0.1)
        case .percentages: return Color(red: 0.2, green: 0.6, blue: 0.8)
        case .tenQuestion: return Color(red: 0.2, green: 0.7, blue: 0.4)
        case .multiplicationMadness: return Color(red: 0.7, green: 0.2, blue: 0.6)
        case .twoMinuteDrill: return Color(red: 0.85, green: 0.25, blue: 0.25)
        }
    }
    
    var timeLabel: String {
        if let t = mode.timeLimit {
            return t == 60 ? "1 minute" : "2 minutes"
        }
        return "Unlimited"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title)
                    .font(.headline)
                Text(mode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(timeLabel)
                        .font(.caption)
                }
                .foregroundStyle(color)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Challenge Test View

class ChallengeViewModel: ObservableObject {
    let mode: ChallengeMode
    @Published var currentQuestionText: String = ""
    @Published var currentAnswer: Int = 0
    @Published var currentOperation: String = ""
    @Published var timeString: String = "0:00"
    @Published var score: Int = 0
    @Published var numCorrect: Int = 0
    @Published var questionCount: Int = 0
    @Published var isFinished: Bool = false
    @Published var isTimeLow: Bool = false
    @Published var checkmarks: [Bool] = Array(repeating: false, count: 10) // for 10Q challenge
    
    @Published var tenQIndex: Int = 0

    private var timer: Timer?
    private var remainingSeconds: Int = 0
    private var elapsedSeconds: Int = 0
    private var tenQuestionSet: [(question: String, answer: Int, operation: String)] = []
    private var startTime: Date = Date()
    
    init(mode: ChallengeMode) {
        self.mode = mode
        setup()
    }
    
    func setup() {
        switch mode {
        case .squares, .percentages, .multiplicationMadness, .twoMinuteDrill:
            nextQuestion()
            if let limit = mode.timeLimit {
                remainingSeconds = Int(limit)
                timeString = mode == .twoMinuteDrill ? "2:00" : "1:00"
                startCountdown()
            }
        case .tenQuestion:
            tenQuestionSet = NumberGenerator.getTenQuestionChallenge()
            tenQIndex = 0
            startTime = Date()
            loadTenQuestion()
            // No time limit - stopwatch
            startStopwatch()
        }
    }
    
    func nextQuestion() {
        switch mode {
        case .squares:
            if questionCount % 2 == 0 {
                let q = NumberGenerator.getSquare()
                currentQuestionText = "\(q[0])² ="
                currentAnswer = q[1]
            } else {
                let q = NumberGenerator.getSquareRoot()
                currentQuestionText = "√\(q[0]) ="
                currentAnswer = q[1]
            }
            currentOperation = "^"
        case .percentages:
            let q = NumberGenerator.getPercentage()
            currentQuestionText = "\(q[1])% of \(q[0]) ="
            currentAnswer = q[2]
            currentOperation = "%"
        case .multiplicationMadness:
            let q = NumberGenerator.getMultiplicationMadness()
            currentQuestionText = q.question
            currentAnswer = q.answer
            currentOperation = "×"
        case .twoMinuteDrill:
            let q = NumberGenerator.getTwoMinuteDrillQuestion(position: questionCount)
            let ops = ["+", "−", "×", "÷"]
            let opIdx = questionCount % 4
            let op = ops[opIdx]
            if opIdx == 0 { currentQuestionText = "\(q[0]) + \(q[1]) =" }
            else if opIdx == 1 { currentQuestionText = "\(q[0]) − \(q[1]) =" }
            else if opIdx == 2 { currentQuestionText = "\(q[0]) × \(q[1]) =" }
            else { currentQuestionText = "\(q[0]) ÷ \(q[1]) =" }
            currentAnswer = q[2]
            currentOperation = op
        case .tenQuestion:
            break
        }
    }
    
    func loadTenQuestion() {
        guard tenQIndex < tenQuestionSet.count else {
            finishTenQuestion()
            return
        }
        let q = tenQuestionSet[tenQIndex]
        currentQuestionText = q.question
        currentAnswer = q.answer
        currentOperation = q.operation
    }
    
    func submitAnswer(_ text: String) {
        let correct = text == String(currentAnswer)
        if correct { numCorrect += 1 }
        questionCount += 1
        
        switch mode {
        case .tenQuestion:
            if tenQIndex < 10 {
                checkmarks[tenQIndex] = correct
            }
            tenQIndex += 1
            if tenQIndex >= tenQuestionSet.count {
                finishTenQuestion()
            } else {
                loadTenQuestion()
            }
        case .squares, .percentages, .multiplicationMadness:
            // Timed - score based on correct answers
            if correct {
                score += 1
                objectWillChange.send()
            }
            nextQuestion()
        case .twoMinuteDrill:
            if correct { score += 1 }
            nextQuestion()
        }
    }
    
    private func finishTenQuestion() {
        stopTimer()
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let seconds = elapsed
        let computed = numCorrect * 1000 - seconds * 20
        score = max(0, computed)
        isFinished = true
    }
    
    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingSeconds -= 1
            self.isTimeLow = self.remainingSeconds <= 10
            self.timeString = TestViewModel.secondsToTimeString(self.remainingSeconds)
            if self.remainingSeconds <= 0 {
                self.timeString = "0:00"
                self.stopTimer()
                self.isFinished = true
            }
        }
    }
    
    private func startStopwatch() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedSeconds += 1
            self.timeString = TestViewModel.secondsToTimeString(self.elapsedSeconds)
        }
    }
    
    func stopTimer() { timer?.invalidate(); timer = nil }
    
    var finalTimeString: String { timeString }
}

struct ChallengeTestView: View {
    let mode: ChallengeMode
    @StateObject private var vm: ChallengeViewModel
    @State private var answerText: String = ""
    @Environment(\.dismiss) var dismiss
    
    init(mode: ChallengeMode) {
        self.mode = mode
        _vm = StateObject(wrappedValue: ChallengeViewModel(mode: mode))
    }
    
    var color: Color {
        switch mode {
        case .squares: return Color(red: 0.9, green: 0.45, blue: 0.1)
        case .percentages: return Color(red: 0.2, green: 0.6, blue: 0.8)
        case .tenQuestion: return Color(red: 0.2, green: 0.7, blue: 0.4)
        case .multiplicationMadness: return Color(red: 0.7, green: 0.2, blue: 0.6)
        case .twoMinuteDrill: return Color(red: 0.85, green: 0.25, blue: 0.25)
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { vm.stopTimer(); dismiss() }) {
                        Text("Quit")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(vm.timeString)
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundStyle(vm.isTimeLow ? .red : color)
                    Spacer()
                    if mode != .tenQuestion {
                        Text("Score: \(vm.score)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(vm.tenQIndex)/10")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                
                // 10Q progress dots
                if mode == .tenQuestion {
                    HStack(spacing: 8) {
                        ForEach(0..<10, id: \.self) { i in
                            Circle()
                                .fill(i < vm.tenQIndex ? (vm.checkmarks[i] ? Color.green : Color.red) : Color(.systemFill))
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.bottom, 8)
                }
                
                Spacer()
                
                // Question — reuse the same flashcard
                // 10Q challenge and 2-min drill: same portrait ratio as main test
                // Other modes: square with smaller text so expression fits one line
                let isPortrait = (mode == .tenQuestion || mode == .twoMinuteDrill)
                QuestionCardView(
                        card: makeChallengeCard().card,
                        operation: challengeOperation(),
                        accentColor: color,
                        answerText: answerText,
                        questionLabel: makeChallengeCard().label,
                        aspectRatio: isPortrait ? 3.0/4.0 : 1.0,
                        fontSize: isPortrait ? 84 : 42
                    )
                .padding(.horizontal, 40)
                .id(vm.questionCount)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.15), value: vm.questionCount)
                
                Spacer()
                
                NumpadView(accentColor: color) { key in
                    switch key {
                    case "⌫":
                        if !answerText.isEmpty { answerText.removeLast() }
                    case "✓":
                        vm.submitAnswer(answerText)
                        answerText = ""
                    default:
                        if answerText.count < 6 { answerText += key }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $vm.isFinished) {
            ChallengeResultsView(
                mode: mode,
                score: vm.score,
                numCorrect: vm.numCorrect,
                timeUsed: vm.finalTimeString
            )
        }
    }

    // Build a Card + optional free-form label for QuestionCardView
    func makeChallengeCard() -> (card: Card, label: String?) {
        let card = Card()
        card.questionNum = vm.questionCount + 1
        card.answer = vm.currentAnswer

        let text = vm.currentQuestionText
            .replacingOccurrences(of: " =", with: "")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)

        let separators = [" + ", " − ", " × ", " ÷ "]
        for sep in separators {
            if text.contains(sep) {
                let parts = text.components(separatedBy: sep)
                if parts.count == 2,
                   let a = Int(parts[0].trimmingCharacters(in: .whitespaces)),
                   let b = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                    card.firstNum = a
                    card.secondNum = b
                    return (card, nil)   // standard two-number layout, no label needed
                }
            }
        }

        // Free-form expression (√64, 30% of 75, (6+4)×3, etc.) — show as label
        return (card, vm.currentQuestionText)
    }

    // Resolve the Operation enum from the current question's operator symbol
    func challengeOperation() -> Operation {
        let text = vm.currentQuestionText
        if text.contains(" + ") { return .addition }
        if text.contains(" − ") { return .subtraction }
        if text.contains(" × ") || text.contains(" x ") { return .multiplication }
        if text.contains(" ÷ ") || text.contains(" / ") { return .division }
        // For squares/percentages/madness use a neutral fallback
        return .multiplication
    }
}

// MARK: - Challenge Results

struct ChallengeResultsView: View {
    let mode: ChallengeMode
    let score: Int
    let numCorrect: Int
    let timeUsed: String
    
    @State private var playerName: String = ""
    @State private var highScores: [HighScore] = []
    @State private var savedHighScoreId: Int64? = nil
    @State private var isNameSaved: Bool = false
    
    var scoreMultiplier = 1000
    
    var color: Color {
        switch mode {
        case .squares: return Color(red: 0.9, green: 0.45, blue: 0.1)
        case .percentages: return Color(red: 0.2, green: 0.6, blue: 0.8)
        case .tenQuestion: return Color(red: 0.2, green: 0.7, blue: 0.4)
        case .multiplicationMadness: return Color(red: 0.7, green: 0.2, blue: 0.6)
        case .twoMinuteDrill: return Color(red: 0.85, green: 0.25, blue: 0.25)
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Score
                    VStack(spacing: 12) {
                        Text(mode.title)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("\(score)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(color)
                        
                        Text("Score")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(numCorrect)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("Correct")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Divider().frame(height: 40)
                            VStack {
                                Text(timeUsed)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("Time")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // High Scores
                    VStack(alignment: .leading, spacing: 12) {
                        Text("High Scores")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 1) {
                            if DatabaseManager.shared.shouldInsertHighScore(mode: mode.rawValue, score: score) && !isNameSaved {
                                // Enter name for new high score
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("🎉 New High Score!")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(color)
                                    TextField("Enter your name", text: $playerName)
                                        .padding(10)
                                        .background(Color(.systemFill))
                                        .cornerRadius(8)
                                    Button("Save Score") {
                                        let insertedId = DatabaseManager.shared.insertHighScore(
                                            mode: mode.rawValue, score: score, name: playerName.isEmpty ? "Anonymous" : playerName)
                                        savedHighScoreId = insertedId
                                        isNameSaved = true
                                        highScores = DatabaseManager.shared.fetchHighScores(mode: mode.rawValue)
                                    }
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(color)
                                    .foregroundStyle(.white)
                                    .cornerRadius(8)
                                }
                                .padding(14)
                                .background(Color(.secondarySystemGroupedBackground))
                            }
                            
                            ForEach(Array(highScores.enumerated()), id: \.element.id) { i, hs in
                                HStack {
                                    Text("\(i + 1).")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                    Text(hs.name.isEmpty ? "—" : hs.name)
                                    Spacer()
                                    Text("\(hs.score)")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(color)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemGroupedBackground))
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Buttons
                    VStack(spacing: 12) {
                        NavigationLink(destination: ChallengeTestView(mode: mode)) {
                            Text("Try Again")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(color)
                                .foregroundStyle(.white)
                                .cornerRadius(16)
                        }
                        
                        NavigationLink(destination: HomeView()) {
                            Text("Home")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(.secondarySystemGroupedBackground))
                                .foregroundStyle(.primary)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            highScores = DatabaseManager.shared.fetchHighScores(mode: mode.rawValue)
        }
    }
}
