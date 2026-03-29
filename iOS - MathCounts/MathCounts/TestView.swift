import SwiftUI
import Combine

class TestViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var currentIndex: Int = 0
    @Published var timeString: String = ""
    @Published var isTimeLow: Bool = false
    @Published var isFinished: Bool = false
    @Published var testId: Int64 = -1
    
    let operation: Operation
    let difficulty: Int
    let numQuestions: Int
    let timeAllotted: String
    let studentName: String
    
    private var timer: Timer?
    private var totalSeconds: Int = 0
    private var remainingSeconds: Int = 0
    private var elapsedSeconds: Int = 0
    private var isUnlimited: Bool = false
    
    var numCorrect: Int { cards.filter { $0.isCorrect }.count }
    var timeRemaining: String {
        isUnlimited ? secondsToString(elapsedSeconds) : timeString
    }
    
    init(operation: Operation, difficulty: Int, numQuestions: Int, timeString: String, studentName: String) {
        self.operation = operation
        self.difficulty = difficulty
        self.numQuestions = numQuestions
        self.timeAllotted = timeString
        self.studentName = studentName
        
        generateCards()
        setupTimer()
    }
    
    func generateCards() {
        let questions: [[Int]]
        switch operation {
        case .addition:
            questions = NumberGenerator.getAddition(level: Difficulty(rawValue: difficulty) ?? .easy, count: numQuestions)
        case .subtraction:
            questions = NumberGenerator.getSubtraction(level: Difficulty(rawValue: difficulty) ?? .easy, count: numQuestions)
        case .multiplication:
            questions = NumberGenerator.getMultiplication(level: difficulty, count: numQuestions)
        case .division:
            questions = NumberGenerator.getDivision(level: difficulty, count: numQuestions)
        }
        
        cards = questions.enumerated().map { i, q in
            Card(questionNum: i + 1, firstNum: q[0], secondNum: q[1], answer: q[2])
        }
    }
    
    private func setupTimer() {
        if timeAllotted == "Unlimited" {
            isUnlimited = true
            self.timeString = "0:00"
            startElapsedTimer()
        } else {
            totalSeconds = Self.parseTime(timeAllotted)
            remainingSeconds = totalSeconds
            timeString = timeAllotted
            startCountdownTimer()
        }
    }
    
    private func startCountdownTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingSeconds -= 1
            self.isTimeLow = self.remainingSeconds <= 10
            self.timeString = Self.secondsToTimeString(self.remainingSeconds)
            if self.remainingSeconds <= 0 {
                self.timeString = "0:00"
                self.finish()
            }
        }
    }
    
    private func startElapsedTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedSeconds += 1
            self.timeString = Self.secondsToTimeString(self.elapsedSeconds)
        }
    }
    
    func stopTimer() { timer?.invalidate(); timer = nil }
    
    func submitAnswer(_ answer: String) {
        guard currentIndex < cards.count else { return }
        cards[currentIndex].studentAnswer = answer
        cards[currentIndex].isViewed = true
        
        if currentIndex == cards.count - 1 {
            finish()
        } else {
            currentIndex += 1
        }
    }
    
    func navigateTo(_ index: Int) {
        guard index >= 0 && index < cards.count else { return }
        currentIndex = index
    }
    
    func finish() {
        stopTimer()
        isFinished = true
        saveToDatabase(quitTest: false)
    }
    
    func quit() {
        stopTimer()
        saveToDatabase(quitTest: true)
    }
    
    private func saveToDatabase(quitTest: Bool) {
        let timeRemStr = isUnlimited ? Self.secondsToTimeString(elapsedSeconds) : timeString
        testId = DatabaseManager.shared.insertTest(
            user: studentName,
            date: Date(),
            operation: operation.rawValue,
            difficulty: difficulty,
            timeAllotted: timeAllotted,
            timeRemaining: timeRemStr,
            numQuestions: numQuestions,
            numCorrect: numCorrect,
            quitTest: quitTest
        )
        
        for card in cards {
            DatabaseManager.shared.insertQuestion(
                testId: testId,
                questionNum: card.questionNum,
                firstNum: card.firstNum,
                secondNum: card.secondNum,
                answer: card.answer,
                studentAnswer: card.studentAnswer,
                isCorrect: card.isCorrect
            )
        }
    }
    
    static func parseTime(_ s: String) -> Int {
        let parts = s.split(separator: ":").map { Int($0) ?? 0 }
        if parts.count == 2 { return parts[0] * 60 + parts[1] }
        return 0
    }
    
    static func secondsToTimeString(_ s: Int) -> String {
        let m = s / 60, sec = s % 60
        return String(format: "%d:%02d", m, sec)
    }
    
    func secondsToString(_ s: Int) -> String { Self.secondsToTimeString(s) }
}

struct TestView: View {
    let operation: Operation
    let difficulty: Int
    let numQuestions: Int
    let timeString: String
    let studentName: String
    
    @StateObject private var vm: TestViewModel
    @State private var answerText: String = ""
    @State private var showQuit = false
    @Environment(\.dismiss) var dismiss
    
    init(operation: Operation, difficulty: Int, numQuestions: Int, timeString: String, studentName: String) {
        self.operation = operation
        self.difficulty = difficulty
        self.numQuestions = numQuestions
        self.timeString = timeString
        self.studentName = studentName
        _vm = StateObject(wrappedValue: TestViewModel(
            operation: operation, difficulty: difficulty,
            numQuestions: numQuestions, timeString: timeString, studentName: studentName))
    }
    
    var accentColor: Color {
        switch operation {
        case .addition: return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .subtraction: return Color(red: 0.2, green: 0.6, blue: 0.8)
        case .multiplication: return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .division: return Color(red: 0.6, green: 0.3, blue: 0.85)
        }
    }
    
    var bgColor: Color {
        switch operation {
        case .addition: return Color(red: 1.0, green: 0.88, blue: 0.88)
        case .subtraction: return Color(red: 0.87, green: 0.94, blue: 0.99)
        case .multiplication: return Color(red: 0.88, green: 0.98, blue: 0.88)
        case .division: return Color(red: 0.94, green: 0.88, blue: 1.0)
        }
    }
    
    var currentCard: Card? {
        guard vm.currentIndex < vm.cards.count else { return nil }
        return vm.cards[vm.currentIndex]
    }
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { showQuit = true }) {
                        Text("Quit")
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Timer
                    Text(vm.timeString)
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundStyle(vm.isTimeLow ? .red : accentColor)
                        .animation(.easeInOut, value: vm.isTimeLow)
                    
                    Spacer()
                    
                    // Progress
                    Text("\(vm.currentIndex + 1)/\(vm.numQuestions)")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemFill))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accentColor)
                            .frame(width: geo.size.width * CGFloat(vm.currentIndex) / CGFloat(max(vm.numQuestions, 1)), height: 4)
                            .animation(.linear(duration: 0.2), value: vm.currentIndex)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
                
                .padding(.bottom, 20)
                
                Spacer()

                // Question card with embedded answer
                if let card = currentCard {
                    QuestionCardView(
                        card: card,
                        operation: operation,
                        accentColor: accentColor,
                        answerText: answerText
                    )
                    .padding(.horizontal, 40)
                    .id(vm.currentIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
                
                Spacer()
                
                // Numpad only (answer display is now on the card)
                NumpadView(
                    accentColor: accentColor,
                    onKey: { key in
                        switch key {
                        case "⌫":
                            if !answerText.isEmpty { answerText.removeLast() }
                        case "✓":
                            withAnimation(.spring(response: 0.3)) {
                                vm.submitAnswer(answerText)
                                answerText = ""
                            }
                        default:
                            if answerText.count < 4 { answerText += key }
                        }
                    }
                )
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $vm.isFinished) {
            TestResultView(
                testId: vm.testId,
                cards: vm.cards,
                operation: operation,
                studentName: studentName,
                timeAllotted: timeString,
                timeRemaining: vm.timeRemaining,
                isFromTest: true
            )
        }
        .confirmationDialog("Quit Test?", isPresented: $showQuit, titleVisibility: .visible) {
            Button("Quit", role: .destructive) { vm.quit(); dismiss() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your progress will be saved but marked as incomplete.")
        }
    }
    
}

struct QuestionCardView: View {
    let card: Card
    let operation: Operation
    let accentColor: Color
    let answerText: String
    var questionLabel: String? = nil
    var aspectRatio: CGFloat = 3.0/4.0
    var fontSize: CGFloat = 84

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {

                // ── Card background ─────────────────────────────────
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black, lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)

                // ── Question number — top left with corner padding ──
                Text("#\(card.questionNum)")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 14)
                    .padding(.leading, 16)

                // ── Arithmetic block — centered in card ─────────────
                VStack(alignment: .trailing, spacing: 0) {

                    if let label = questionLabel {
                        Text(label)
                            .font(.system(size: fontSize, weight: .light, design: .rounded))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    } else {
                        // Extra space above the top number
                        Spacer().frame(height: 16)

                        // First number — operator placeholder on left keeps columns aligned
                        HStack(alignment: .center, spacing: 0) {
                            Color.clear.frame(width: 52)
                            Text("\(card.firstNum)")
                                .font(.system(size: fontSize, weight: .light, design: .rounded))
                                .monospacedDigit()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.bottom, 2)   // minimal gap between the two numbers

                        // Second number with operator on left
                        HStack(alignment: .center, spacing: 0) {
                            Text(operation.sign)
                                .font(.system(size: fontSize * 0.8, weight: .light))
                                .foregroundStyle(.black)
                                .frame(width: 52, alignment: .leading)
                            Text("\(card.secondNum)")
                                .font(.system(size: fontSize, weight: .light, design: .rounded))
                                .monospacedDigit()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }

                    // Dividing line
                    Rectangle()
                        .fill(Color.black.opacity(0.6))
                        .frame(height: 2)
                        .padding(.top, 10)

                    // Answer row — extra padding above/below the digits
                    HStack(spacing: 0) {
                        Color.clear.frame(width: 52)
                        Text(answerText.isEmpty ? "" : answerText)
                            .font(.system(size: fontSize, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .frame(height: fontSize + 28)

                }
                .padding(.horizontal, 24)
                .frame(width: geo.size.width)
                .frame(height: geo.size.height)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(maxWidth: 280)
    }
}

struct NumpadView: View {
    let accentColor: Color
    let onKey: (String) -> Void

    let rows = [["7","8","9"], ["4","5","6"], ["1","2","3"], ["⌫","0","✓"]]

    var body: some View {
        VStack(spacing: 2) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(row, id: \.self) { key in
                        Button(action: { onKey(key) }) {
                            Text(key)
                                .font(.system(size: 26, weight: .regular, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(keyColor(key))
                                .foregroundStyle(keyForeground(key))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .background(Color(.systemFill))
    }

    func keyColor(_ key: String) -> Color {
        switch key {
        case "✓": return Color(red: 0.18, green: 0.72, blue: 0.35)   // green
        case "⌫": return Color(.systemGray4)
        default:  return Color(.secondarySystemGroupedBackground)
        }
    }

    func keyForeground(_ key: String) -> Color {
        key == "✓" ? .white : .primary
    }
}
