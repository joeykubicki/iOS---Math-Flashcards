import Foundation

// MARK: - Enums

enum Operation: String, CaseIterable, Codable {
    case addition = "Addition"
    case subtraction = "Subtraction"
    case multiplication = "Multiplication"
    case division = "Division"
    
    var sign: String {
        switch self {
        case .addition: return "+"
        case .subtraction: return "−"
        case .multiplication: return "×"
        case .division: return "÷"
        }
    }
    
    var color: String {
        switch self {
        case .addition: return "AdditionColor"
        case .subtraction: return "SubtractionColor"
        case .multiplication: return "MultiplicationColor"
        case .division: return "DivisionColor"
        }
    }
}

enum Difficulty: Int, CaseIterable, Codable {
    case easy = 1
    case medium = 2
    case hard = 3
    case expert = 4
    
    var label: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
}

enum MultiplicationLevel: Int, CaseIterable {
    case twos = 2, threes = 3, fours = 4, fives = 5
    case sixes = 6, sevens = 7, eights = 8, nines = 9
    case tens = 10, elevens = 11, twelves = 12, mixed = 13
    
    var label: String {
        if self == .mixed { return "Mixed" }
        return "\(rawValue)s"
    }
}

enum ChallengeMode: Int, CaseIterable {
    case squares = 0
    case percentages = 1
    case tenQuestion = 2
    case multiplicationMadness = 3
    case twoMinuteDrill = 4
    
    var title: String {
        switch self {
        case .squares: return "Squares Challenge"
        case .percentages: return "Percentages Challenge"
        case .tenQuestion: return "10 Question Challenge"
        case .multiplicationMadness: return "Multiplication Madness"
        case .twoMinuteDrill: return "Two Minute Drill"
        }
    }
    
    var description: String {
        switch self {
        case .squares:
            return "Answer as many squares and square roots as you can!"
        case .percentages:
            return "Answer as many percentage questions as you can!"
        case .tenQuestion:
            return "Answer 10 questions covering all operations as fast as possible. Your score is based on accuracy and speed."
        case .multiplicationMadness:
            return "Answer order of operations multiplication questions as fast as you can!"
        case .twoMinuteDrill:
            return "Answer as many questions as you can covering all four operations!"
        }
    }
    
    var timeLimit: TimeInterval? {
        switch self {
        case .squares: return 60
        case .percentages: return 60
        case .tenQuestion: return nil
        case .multiplicationMadness: return 60
        case .twoMinuteDrill: return 120
        }
    }
}

// MARK: - Card (Question)

class Card {
    var questionNum: Int = 0
    var firstNum: Int = 0
    var secondNum: Int = 0
    var answer: Int = 0
    var studentAnswer: String = ""
    var isViewed: Bool = false
    
    init() {}
    
    init(questionNum: Int, firstNum: Int, secondNum: Int, answer: Int) {
        self.questionNum = questionNum
        self.firstNum = firstNum
        self.secondNum = secondNum
        self.answer = answer
    }
    
    var isCorrect: Bool {
        return studentAnswer == String(answer)
    }
}

// MARK: - Test Result

struct TestResult: Identifiable, Codable {
    var id: UUID = UUID()
    var testId: Int64
    var user: String
    var date: Date
    var operation: String
    var difficulty: Int
    var timeAllotted: String
    var timeRemaining: String
    var numQuestions: Int
    var numCorrect: Int
    var quitTest: Bool
    
    var score: String {
        return "\(numCorrect)/\(numQuestions)"
    }
    
    var percentage: Double {
        guard numQuestions > 0 else { return 0 }
        return Double(numCorrect) / Double(numQuestions) * 100
    }
    
    var difficultyLabel: String {
        return Difficulty(rawValue: difficulty)?.label ?? "Unknown"
    }
}

struct QuestionResult: Identifiable, Codable {
    var id: UUID = UUID()
    var testId: Int64
    var questionNum: Int
    var firstNum: Int
    var secondNum: Int
    var answer: Int
    var studentAnswer: String
    var isCorrect: Bool
}

// MARK: - High Score

struct HighScore: Identifiable, Codable {
    var id: UUID = UUID()
    var dbId: Int64
    var mode: Int
    var score: Int
    var name: String
}
