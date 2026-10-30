import SwiftUI

struct ChallengeMenuView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        GeometryReader { geo in
        let contentMaxWidth: CGFloat = isIPad ? geo.size.width * 0.70 : .infinity
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                let columns = isIPad
                    ? [GridItem(.flexible()), GridItem(.flexible())]
                    : [GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 14) {
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
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        }
        .navigationTitle("Challenge Mode")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ChallengeCard: View {
    let mode: ChallengeMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var isIPad: Bool { horizontalSizeClass == .regular }

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
        if isIPad {
            // Square tile matching the home-page operation button size
            VStack(spacing: 14) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(color.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: icon)
                        .font(.system(size: 36))
                        .foregroundStyle(color)
                }
                Text(mode.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text(mode.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.callout)
                    Text(timeLabel)
                        .font(.callout)
                }
                .foregroundStyle(color)
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(18)
        } else {
            // Compact horizontal tile for iPhone
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
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
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
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func startStopwatch() {
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedSeconds += 1
            self.timeString = TestViewModel.secondsToTimeString(self.elapsedSeconds)
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stopTimer() { timer?.invalidate(); timer = nil }

    var finalTimeString: String { timeString }
}

struct ChallengeTestView: View {
    let mode: ChallengeMode
    @StateObject private var vm: ChallengeViewModel
    @State private var answerText: String = ""
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

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
        GeometryReader { geo in
            let isIPad      = horizontalSizeClass == .regular
            let compactH    = geo.size.height < 700
            let cardMaxWidth: CGFloat   = isIPad ? geo.size.width * 0.45 : (compactH ? 220 : 280)
            let portraitFontSize: CGFloat = isIPad ? min(geo.size.width * 0.12, 120) : (compactH ? 62 : 84)
            let squareFontSize: CGFloat  = isIPad ? min(geo.size.width * 0.065, 70) : (compactH ? 32 : 42)
            let keyHeight: CGFloat      = isIPad ? min(geo.size.width * 0.085, 85) : (compactH ? 52 : 60)
            let numpadMaxWidth: CGFloat  = isIPad ? geo.size.width * 0.60 : .infinity
            let isPortrait = (mode == .tenQuestion || mode == .twoMinuteDrill)
            let (challengeCard, questionLabel) = makeChallengeCard()

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
                    .padding(.vertical, compactH ? 8 : 14)

                    // 10Q progress dots
                    if mode == .tenQuestion {
                        HStack(spacing: 8) {
                            ForEach(0..<10, id: \.self) { i in
                                Circle()
                                    .fill(i < vm.tenQIndex
                                          ? (vm.checkmarks[i] ? Color.green : Color.red)
                                          : Color(.systemFill))
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .padding(.bottom, 8)
                    }

                    Spacer(minLength: compactH ? 4 : 12)

                    // Question — reuse the same flashcard
                    // 10Q challenge and 2-min drill: same portrait ratio as main test
                    // Other modes: square with smaller text so expression fits one line
                    QuestionCardView(
                        card: challengeCard,
                        operation: challengeOperation(),
                        accentColor: color,
                        answerText: answerText,
                        questionLabel: questionLabel,
                        aspectRatio: isPortrait ? 3.0/4.0 : 1.0,
                        fontSize: isPortrait ? portraitFontSize : squareFontSize,
                        maxWidth: cardMaxWidth
                    )
                    .padding(.horizontal, 40)
                    .id(vm.questionCount)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.15), value: vm.questionCount)

                    Spacer(minLength: compactH ? 4 : 12)

                    NumpadView(accentColor: color, keyHeight: keyHeight, maxWidth: numpadMaxWidth, topSpacing: isIPad ? keyHeight / 2 : 0) { key in
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

    @State private var highScores: [HighScore] = []
    @State private var isHighScore: Bool = false
    @State private var didEvaluateHighScore: Bool = false
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var isIPad: Bool { horizontalSizeClass == .regular }

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
        GeometryReader { geo in
        let contentMaxWidth: CGFloat = isIPad ? geo.size.width * 0.70 : .infinity
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
                            if isHighScore {
                                Text("New high score saved")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(color)
                                    .frame(maxWidth: .infinity, alignment: .leading)
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

                        Button {
                            navState.goToRoot()
                        } label: {
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
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            saveHighScoreIfNeeded()
        }
    }

    private func saveHighScoreIfNeeded() {
        guard !didEvaluateHighScore else {
            highScores = DatabaseManager.shared.fetchHighScores(mode: mode.rawValue)
            return
        }

        didEvaluateHighScore = true
        isHighScore = DatabaseManager.shared.shouldInsertHighScore(mode: mode.rawValue, score: score)
        if isHighScore {
            DatabaseManager.shared.insertHighScore(mode: mode.rawValue, score: score, name: "Anonymous")
        }
        highScores = DatabaseManager.shared.fetchHighScores(mode: mode.rawValue)
    }
}
