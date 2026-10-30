import Foundation

struct NumberGenerator {
    
    // MARK: - Addition
    
    static func getAddition(level: Difficulty, count: Int) -> [[Int]] {
        switch level {
        case .easy: return getEasyAddition(count)
        case .medium: return getMediumAddition(count)
        case .hard: return getHardAddition(count)
        case .expert: return getExpertAddition(count)
        }
    }
    
    private static func getEasyAddition(_ n: Int) -> [[Int]] {
        var questions = Array(repeating: [0, 0, 0], count: n)
        for i in 0..<n {
            repeat {
                if Int.random(in: 0..<2) == 0 {
                    questions[i][0] = Int.random(in: 1...10)
                    questions[i][1] = Int.random(in: 1...10)
                } else {
                    questions[i][0] = Int.random(in: 0...10)
                    questions[i][1] = Int.random(in: 0...10)
                }
            } while checkExists(questions, i, n/10)
            questions[i][2] = questions[i][0] + questions[i][1]
        }
        return questions
    }
    
    private static func getMediumAddition(_ n: Int) -> [[Int]] {
        var questions = Array(repeating: [0, 0, 0], count: n)
        for i in 0..<n {
            repeat {
                if Int.random(in: 0..<10) > 3 {
                    repeat { questions[i][0] = weightedRandom(mean: 15, std: 6) }
                    while questions[i][0] > 15 || questions[i][0] < 5
                } else {
                    repeat { questions[i][0] = weightedRandom(mean: 15, std: 4) }
                    while questions[i][0] <= 15 || questions[i][0] > 25
                }
                if Int.random(in: 0..<10) > 3 {
                    repeat { questions[i][1] = weightedRandom(mean: 15, std: 6) }
                    while questions[i][1] > 15 || questions[i][1] < 5
                } else {
                    repeat { questions[i][1] = weightedRandom(mean: 15, std: 4) }
                    while questions[i][1] <= 15 || questions[i][1] > 25
                }
            } while checkExists(questions, i, n/10)
            questions[i][2] = questions[i][0] + questions[i][1]
        }
        return questions
    }
    
    private static func getHardAddition(_ n: Int) -> [[Int]] {
        var questions = Array(repeating: [0, 0, 0], count: n)
        for i in 0..<n {
            repeat {
                if Int.random(in: 0..<10) > 3 {
                    repeat { questions[i][0] = weightedRandom(mean: 40, std: 40) }
                    while questions[i][0] > 40 || questions[i][0] < 5
                } else {
                    repeat { questions[i][0] = weightedRandom(mean: 40, std: 15) }
                    while questions[i][0] <= 40
                }
                if Int.random(in: 0..<10) > 3 {
                    repeat { questions[i][1] = weightedRandom(mean: 40, std: 40) }
                    while questions[i][1] > 40 || questions[i][1] < 5
                } else {
                    repeat { questions[i][1] = weightedRandom(mean: 40, std: 15) }
                    while questions[i][1] <= 40
                }
            } while checkExists(questions, i, n/10)
            questions[i][2] = questions[i][0] + questions[i][1]
        }
        return questions
    }
    
    static func getExpertAddition(_ n: Int) -> [[Int]] {
        let mean = 750
        var questions = Array(repeating: [0, 0, 0], count: n)
        for i in 0..<n {
            repeat {
                if Int.random(in: 0..<1000) > 1 {
                    repeat { questions[i][0] = weightedRandom(mean: mean, std: 500) }
                    while questions[i][0] > mean || questions[i][0] < 50
                } else {
                    repeat { questions[i][0] = weightedRandom(mean: mean, std: 40) }
                    while questions[i][0] <= mean
                }
                if Int.random(in: 0..<1000) > 1 {
                    repeat { questions[i][1] = weightedRandom(mean: mean, std: 500) }
                    while questions[i][1] > mean || questions[i][1] < 50
                } else {
                    repeat { questions[i][1] = weightedRandom(mean: mean, std: 40) }
                    while questions[i][1] <= mean
                }
            } while checkExistsPair(questions, i, questions[i][0], questions[i][1], 0) || (questions[i][0] + questions[i][1] > 999)
            questions[i][2] = questions[i][0] + questions[i][1]
        }
        return questions
    }
    
    // MARK: - Subtraction
    
    static func getSubtraction(level: Difficulty, count: Int) -> [[Int]] {
        switch level {
        case .easy: return getEasySubtraction(count)
        case .medium: return getMediumSubtraction(count)
        case .hard: return getHardSubtraction(count)
        case .expert: return getExpertSubtraction(count)
        }
    }
    
    private static func getEasySubtraction(_ n: Int) -> [[Int]] {
        var questions = Array(repeating: [0, 0, 0], count: n)
        for i in 0..<n {
            var a, b: Int
            repeat {
                if Int.random(in: 0..<2) == 0 {
                    a = Int.random(in: 1...10); b = Int.random(in: 1...10)
                } else {
                    a = Int.random(in: 0...10); b = Int.random(in: 0...10)
                }
            } while checkExistsPair(questions, i, a, b, n/10)
            questions[i][0] = a + b; questions[i][1] = a; questions[i][2] = b
        }
        return questions
    }
    
    private static func getMediumSubtraction(_ n: Int) -> [[Int]] {
        var questions = Array(repeating: [0, 0, 0], count: n)
        for i in 0..<n {
            var a, b: Int
            repeat {
                if Int.random(in: 0..<10) > 2 {
                    repeat { a = weightedRandom(mean: 15, std: 6) } while a > 15 || a < 5
                } else {
                    repeat { a = weightedRandom(mean: 15, std: 4) } while a <= 15
                }
                if Int.random(in: 0..<10) > 2 {
                    repeat { b = weightedRandom(mean: 15, std: 6) } while b > 15 || b < 5
                } else {
                    repeat { b = weightedRandom(mean: 15, std: 4) } while b <= 15
                }
            } while checkExistsPair(questions, i, a, b, n/10)
            questions[i][0] = a + b; questions[i][1] = a; questions[i][2] = b
        }
        return questions
    }
    
    private static func getHardSubtraction(_ n: Int) -> [[Int]] {
        var questions = Array(repeating: [0, 0, 0], count: n)
        for i in 0..<n {
            var a, b: Int
            repeat {
                if Int.random(in: 0..<10) > 2 {
                    repeat { a = weightedRandom(mean: 50, std: 35) } while a > 50 || a < 5
                } else {
                    repeat { a = weightedRandom(mean: 50, std: 10) } while a <= 50
                }
                if Int.random(in: 0..<10) > 2 {
                    repeat { b = weightedRandom(mean: 50, std: 35) } while b > 50 || b < 5
                } else {
                    repeat { b = weightedRandom(mean: 50, std: 10) } while b <= 50
                }
            } while checkExistsPair(questions, i, a, b, n/10)
            questions[i][0] = a + b; questions[i][1] = a; questions[i][2] = b
        }
        return questions
    }
    
    static func getExpertSubtraction(_ n: Int) -> [[Int]] {
        let mean = 750
        var questions = Array(repeating: [0, 0, 0], count: n)
        for i in 0..<n {
            var a, b: Int
            repeat {
                if Int.random(in: 0..<1000) > 1 {
                    repeat { a = weightedRandom(mean: mean, std: 500) } while a > mean || a < 50
                } else {
                    repeat { a = weightedRandom(mean: mean, std: 40) } while a <= mean
                }
                if Int.random(in: 0..<1000) > 1 {
                    repeat { b = weightedRandom(mean: mean, std: 500) } while b > mean || b < 50
                } else {
                    repeat { b = weightedRandom(mean: mean, std: 40) } while b <= mean
                }
            } while checkExistsPair(questions, i, a, b, 0) || (a + b > 999)
            questions[i][0] = a + b; questions[i][1] = a; questions[i][2] = b
        }
        return questions
    }
    
    // MARK: - Multiplication
    
    static func getMultiplication(level: Int, count: Int) -> [[Int]] {
        var questions = Array(repeating: [0, 0, 0], count: count)
        let repeats = count / 10
        if level == 13 {
            for i in 0..<count {
                var a, b: Int
                repeat {
                    a = Int.random(in: 2...12)
                    b = Int.random(in: 2...12)
                } while checkExistsPair(questions, i, a, b, repeats)
                questions[i] = [a, b, a * b]
            }
        } else {
            for i in 0..<count {
                var a, b: Int
                repeat {
                    if Int.random(in: 0..<2) == 0 {
                        a = level
                        b = Int.random(in: 0..<10) > 1 ? Int.random(in: 2...12) : Int.random(in: 0..<13)
                    } else {
                        a = Int.random(in: 0..<10) > 1 ? Int.random(in: 2...12) : Int.random(in: 0..<13)
                        b = level
                    }
                } while checkExistsPair(questions, i, a, b, repeats)
                questions[i] = [a, b, a * b]
            }
        }
        return questions
    }
    
    static func getChallengeMultiplication(_ n: Int) -> [[Int]] {
        var questions = Array(repeating: [0, 0, 0], count: n)
        let repeats = n / 10
        for i in 0..<n {
            var a = 0, b = 0, ans = 0
            repeat {
                a = Int.random(in: 3...25)
                b = Int.random(in: 3...25)
                ans = a * b
            } while ans > 200 || ans < 50 || checkExistsPair(questions, i, a, b, repeats)
            questions[i] = [a, b, ans]
        }
        return questions
    }
    
    // MARK: - Division
    
    static func getDivision(level: Int, count: Int) -> [[Int]] {
        var questions = Array(repeating: [0, 0, 0], count: count)
        let repeats = count / 12
        if level == 13 {
            for i in 0..<count {
                var a, b: Int
                repeat {
                    a = Int.random(in: 2...12)
                    b = Int.random(in: 2...12)
                } while checkExistsPair(questions, i, a * b, b, repeats)
                questions[i] = [a * b, b, a]
            }
        } else {
            for i in 0..<count {
                var a: Int
                let b = level
                repeat {
                    a = Int.random(in: 0..<10) > 1 ? Int.random(in: 2...12) : Int.random(in: 1...12)
                } while checkExistsPair(questions, i, a * b, b, repeats)
                questions[i] = [a * b, b, a]
            }
        }
        return questions
    }
    
    static func getChallengeDivision(_ n: Int) -> [[Int]] {
        let mult = getChallengeMultiplication(n)
        return mult.map { q in [q[2], q[1], q[0]] }
    }
    
    // MARK: - Challenge Modes
    
    static func getSquareRoot() -> [Int] {
        let answer = Int.random(in: 1...20)
        return [answer * answer, answer]
    }

    static func getSquare() -> [Int] {
        let q = Int.random(in: 1...20)
        return [q, q * q]
    }
    
    static func getPercentage() -> [Int] {
        var amount: Int
        if Int.random(in: 0..<28) < 10 {
            amount = Int.random(in: 1...10)
        } else {
            amount = (Int.random(in: 3...20)) * 5
        }
        var percentage: Int
        if (amount / 5) % 2 == 0 {
            percentage = (Int.random(in: 1...18)) * 5
        } else {
            percentage = (Int.random(in: 1...9)) * 10
        }
        let ans = Double(amount) * Double(percentage) / 100.0
        if ans.truncatingRemainder(dividingBy: 1) != 0 { return getPercentage() }
        return [amount, percentage, Int(ans)]
    }
    
    static func getTwoMinuteDrillQuestion(position: Int) -> [Int] {
        let op = position % 4
        switch op {
        case 0:
            let q = getMediumAddition(1)
            return q[0]
        case 1:
            let q = getMediumSubtraction(1)
            return q[0]
        case 2:
            let q = getMultiplication(level: 13, count: 1)
            return q[0]
        case 3:
            let q = getDivision(level: 13, count: 1)
            return q[0]
        default:
            return [0, 0, 0]
        }
    }
    
    static func getMultiplicationMadness() -> (question: String, answer: Int) {
        let type = Int.random(in: 0..<4)
        var a, b, c, ans: Int
        switch type {
        case 0:
            repeat {
                a = Int.random(in: 5...20); b = Int.random(in: 5...20); c = Int.random(in: 3...15)
                ans = (a + b) * c
            } while ans < 50 || ans > 200
            return ("(\(a) + \(b)) × \(c) =", ans)
        case 1:
            repeat {
                a = Int.random(in: 10...30)
                let temp = Int.random(in: 3...15)
                b = a - temp
                c = Int.random(in: 3...15)
                ans = (a - b) * c
            } while ans < 50 || ans > 200 || b < 1
            return ("(\(a) − \(b)) × \(c) =", ans)
        case 2:
            repeat {
                a = Int.random(in: 5...20); b = Int.random(in: 5...20); c = Int.random(in: 3...15)
                ans = c * (a + b)
            } while ans < 50 || ans > 200
            return ("\(c) × (\(a) + \(b)) =", ans)
        default:
            repeat {
                a = Int.random(in: 10...30)
                let temp = Int.random(in: 3...15)
                b = a - temp
                c = Int.random(in: 3...15)
                ans = c * (a - b)
            } while ans < 50 || ans > 200 || b < 1
            return ("\(c) × (\(a) − \(b)) =", ans)
        }
    }
    
    static func getTenQuestionChallenge() -> [(question: String, answer: Int, operation: String)] {
        var questions: [(String, Int, String)] = []
        // 4 operations: addition, subtraction, multiplication, division
        let addQ = getExpertAddition(1)[0]
        questions.append(("\(addQ[0]) + \(addQ[1]) =", addQ[2], "+"))
        let subQ = getExpertSubtraction(1)[0]
        questions.append(("\(subQ[0]) − \(subQ[1]) =", subQ[2], "−"))
        let mulQ = getChallengeMultiplication(1)[0]
        questions.append(("\(mulQ[0]) × \(mulQ[1]) =", mulQ[2], "×"))
        let divQ = getChallengeDivision(1)[0]
        questions.append(("\(divQ[0]) ÷ \(divQ[1]) =", divQ[2], "÷"))
        // Fill remaining 6 with mixed
        for i in 4..<10 {
            let q = getTwoMinuteDrillQuestion(position: i)
            let op = i % 4
            let opStr = ["+", "−", "×", "÷"][op]
            let displayQ: String
            if op == 0 { displayQ = "\(q[0]) + \(q[1]) =" }
            else if op == 1 { displayQ = "\(q[0]) − \(q[1]) =" }
            else if op == 2 { displayQ = "\(q[0]) × \(q[1]) =" }
            else { displayQ = "\(q[0]) ÷ \(q[1]) =" }
            questions.append((displayQ, q[2], opStr))
        }
        return questions
    }
    
    // MARK: - Helpers
    
    private static func checkExists(_ q: [[Int]], _ i: Int, _ repeats: Int) -> Bool {
        let a = q[i][0], b = q[i][1]
        var count = 0
        for j in 0..<i {
            if q[j][0] == a || q[j][1] == b { count += 1 }
        }
        return count > repeats
    }
    
    private static func checkExistsPair(_ q: [[Int]], _ i: Int, _ a: Int, _ b: Int, _ repeats: Int) -> Bool {
        var count = 0
        for j in 0..<i {
            if q[j][0] == a && q[j][1] == b {
                if j == i - 1 { return true }
                count += 1
            }
            if count > repeats { return true }
        }
        return false
    }
    
    private static func weightedRandom(mean: Int, std: Int) -> Int {
        return Int((normalDist() * Double(std) + Double(mean)).rounded())
    }
    
    private static func normalDist() -> Double {
        return (Double.random(in: 0..<1) * 2 - 1)
            + (Double.random(in: 0..<1) * 2 - 1)
            + (Double.random(in: 0..<1) * 2 - 1)
    }
}
