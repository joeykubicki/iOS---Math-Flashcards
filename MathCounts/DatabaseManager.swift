import Foundation
import SQLite3

// MARK: - DatabaseManager (SQLite wrapper)

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    private init() {
        openDatabase()
        createTables()
    }
    
    private func openDatabase() {
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("tests.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }
    
    private func createTables() {
        let testTable = """
            CREATE TABLE IF NOT EXISTS test (
                _id INTEGER PRIMARY KEY AUTOINCREMENT,
                user TEXT,
                test_date INTEGER,
                operation TEXT,
                difficulty INTEGER,
                time_allotted TEXT,
                time_remaining TEXT,
                num_questions INTEGER,
                num_correct INTEGER,
                quit_test INTEGER
            )
        """
        let questionTable = """
            CREATE TABLE IF NOT EXISTS question (
                _id INTEGER REFERENCES test(_id),
                question_num INTEGER,
                first_num INTEGER,
                second_num INTEGER,
                answer INTEGER,
                student_answer TEXT,
                answer_correct INTEGER
            )
        """
        let highScoreTable = """
            CREATE TABLE IF NOT EXISTS high_score (
                _id INTEGER PRIMARY KEY AUTOINCREMENT,
                mode INTEGER,
                score INTEGER,
                name TEXT
            )
        """
        execute(testTable)
        execute(questionTable)
        execute(highScoreTable)
    }
    
    private func execute(_ sql: String) {
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }
    
    // MARK: - Tests
    
    func insertTest(user: String, date: Date, operation: String, difficulty: Int,
                    timeAllotted: String, timeRemaining: String,
                    numQuestions: Int, numCorrect: Int, quitTest: Bool) -> Int64 {
        let sql = """
            INSERT INTO test (user, test_date, operation, difficulty, time_allotted, time_remaining,
            num_questions, num_correct, quit_test) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        var stmt: OpaquePointer?
        var rowId: Int64 = -1
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (user as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 2, Int64(date.timeIntervalSince1970 * 1000))
            sqlite3_bind_text(stmt, 3, (operation as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 4, Int32(difficulty))
            sqlite3_bind_text(stmt, 5, (timeAllotted as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, (timeRemaining as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 7, Int32(numQuestions))
            sqlite3_bind_int(stmt, 8, Int32(numCorrect))
            sqlite3_bind_int(stmt, 9, quitTest ? 1 : 0)
            sqlite3_step(stmt)
            rowId = sqlite3_last_insert_rowid(db)
        }
        sqlite3_finalize(stmt)
        return rowId
    }
    
    func insertQuestion(testId: Int64, questionNum: Int, firstNum: Int, secondNum: Int,
                        answer: Int, studentAnswer: String, isCorrect: Bool) {
        let sql = """
            INSERT INTO question (_id, question_num, first_num, second_num, answer, student_answer, answer_correct)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, testId)
            sqlite3_bind_int(stmt, 2, Int32(questionNum))
            sqlite3_bind_int(stmt, 3, Int32(firstNum))
            sqlite3_bind_int(stmt, 4, Int32(secondNum))
            sqlite3_bind_int(stmt, 5, Int32(answer))
            sqlite3_bind_text(stmt, 6, (studentAnswer as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 7, isCorrect ? 1 : 0)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }
    
    func fetchAllTests() -> [TestResult] {
        let sql = "SELECT * FROM test WHERE quit_test = 0 ORDER BY test_date DESC"
        return fetchTests(sql: sql, bindings: [])
    }
    
    func fetchTestsByUser(_ name: String) -> [TestResult] {
        let sql = "SELECT * FROM test WHERE user = ? AND quit_test = 0 ORDER BY test_date DESC"
        return fetchTests(sql: sql, bindings: [name])
    }
    
    func fetchTest(id: Int64) -> TestResult? {
        let sql = "SELECT * FROM test WHERE _id = ? LIMIT 1"
        return fetchTests(sql: sql, bindings: [String(id)]).first
    }
    
    private func fetchTests(sql: String, bindings: [String]) -> [TestResult] {
        var stmt: OpaquePointer?
        var results: [TestResult] = []
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            for (i, val) in bindings.enumerated() {
                sqlite3_bind_text(stmt, Int32(i + 1), (val as NSString).utf8String, -1, nil)
            }
            while sqlite3_step(stmt) == SQLITE_ROW {
                let testId = sqlite3_column_int64(stmt, 0)
                let user = String(cString: sqlite3_column_text(stmt, 1))
                let dateMs = sqlite3_column_int64(stmt, 2)
                let operation = String(cString: sqlite3_column_text(stmt, 3))
                let difficulty = Int(sqlite3_column_int(stmt, 4))
                let timeAllotted = String(cString: sqlite3_column_text(stmt, 5))
                let timeRemaining = String(cString: sqlite3_column_text(stmt, 6))
                let numQ = Int(sqlite3_column_int(stmt, 7))
                let numC = Int(sqlite3_column_int(stmt, 8))
                let quit = sqlite3_column_int(stmt, 9) == 1
                let date = Date(timeIntervalSince1970: Double(dateMs) / 1000.0)
                results.append(TestResult(testId: testId, user: user, date: date,
                    operation: operation, difficulty: difficulty,
                    timeAllotted: timeAllotted, timeRemaining: timeRemaining,
                    numQuestions: numQ, numCorrect: numC, quitTest: quit))
            }
        }
        sqlite3_finalize(stmt)
        return results
    }
    
    func fetchQuestions(testId: Int64) -> [QuestionResult] {
        let sql = "SELECT * FROM question WHERE _id = ? ORDER BY question_num ASC"
        var stmt: OpaquePointer?
        var results: [QuestionResult] = []
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, testId)
            while sqlite3_step(stmt) == SQLITE_ROW {
                let qTestId = sqlite3_column_int64(stmt, 0)
                let qNum = Int(sqlite3_column_int(stmt, 1))
                let first = Int(sqlite3_column_int(stmt, 2))
                let second = Int(sqlite3_column_int(stmt, 3))
                let answer = Int(sqlite3_column_int(stmt, 4))
                let studentAns = sqlite3_column_text(stmt, 5).map { String(cString: $0) } ?? ""
                let correct = sqlite3_column_int(stmt, 6) == 1
                results.append(QuestionResult(testId: qTestId, questionNum: qNum,
                    firstNum: first, secondNum: second, answer: answer,
                    studentAnswer: studentAns, isCorrect: correct))
            }
        }
        sqlite3_finalize(stmt)
        return results
    }
    
    func deleteTest(id: Int64) {
        // Delete associated questions first, then the test record
        var stmt: OpaquePointer?
        let deleteQ = "DELETE FROM question WHERE _id = ?"
        if sqlite3_prepare_v2(db, deleteQ, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)

        let deleteT = "DELETE FROM test WHERE _id = ?"
        if sqlite3_prepare_v2(db, deleteT, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func deleteAllTests() {
        execute("DELETE FROM test")
        execute("DELETE FROM question")
    }
    
    // MARK: - High Scores
    
    func fetchHighScores(mode: Int) -> [HighScore] {
        let sql = "SELECT * FROM high_score WHERE mode = ? ORDER BY score DESC LIMIT 10"
        var stmt: OpaquePointer?
        var results: [HighScore] = []
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(mode))
            while sqlite3_step(stmt) == SQLITE_ROW {
                let hId = sqlite3_column_int64(stmt, 0)
                let hMode = Int(sqlite3_column_int(stmt, 1))
                let hScore = Int(sqlite3_column_int(stmt, 2))
                let hName = String(cString: sqlite3_column_text(stmt, 3))
                results.append(HighScore(dbId: hId, mode: hMode, score: hScore, name: hName))
            }
        }
        sqlite3_finalize(stmt)
        return results
    }
    
    func insertHighScore(mode: Int, score: Int, name: String) -> Int64 {
        let sql = "INSERT INTO high_score (mode, score, name) VALUES (?, ?, ?)"
        var stmt: OpaquePointer?
        var rowId: Int64 = -1
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(mode))
            sqlite3_bind_int(stmt, 2, Int32(score))
            sqlite3_bind_text(stmt, 3, (name as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
            rowId = sqlite3_last_insert_rowid(db)
        }
        sqlite3_finalize(stmt)
        pruneHighScores(mode: mode)
        return rowId
    }

    func shouldInsertHighScore(mode: Int, score: Int) -> Bool {
        let scores = fetchHighScores(mode: mode)
        if scores.count < 10 { return true }
        return score > (scores.last?.score ?? 0)
    }

    private func pruneHighScores(mode: Int) {
        // Keep only the top 10 scores per mode
        let sql = """
            DELETE FROM high_score WHERE mode = ? AND _id NOT IN (
                SELECT _id FROM high_score WHERE mode = ? ORDER BY score DESC LIMIT 10
            )
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(mode))
            sqlite3_bind_int(stmt, 2, Int32(mode))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }
    
    func updateHighScoreName(id: Int64, name: String) {
        let sql = "UPDATE high_score SET name = ? WHERE _id = ?"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 2, id)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }
}
