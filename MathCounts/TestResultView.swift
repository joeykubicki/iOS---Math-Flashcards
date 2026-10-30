import SwiftUI
import StoreKit

struct TestResultView: View {
    let testId: Int64
    let cards: [Card]
    let operation: Operation
    let studentName: String
    let timeAllotted: String
    let timeRemaining: String
    let isFromTest: Bool
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var isIPad: Bool { horizontalSizeClass == .regular }
    
    var numCorrect: Int { cards.filter { $0.isCorrect }.count }
    var percentage: Double { cards.isEmpty ? 0 : Double(numCorrect) / Double(cards.count) * 100 }
    
    var accentColor: Color {
        switch operation {
        case .addition: return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .subtraction: return Color(red: 0.2, green: 0.6, blue: 0.8)
        case .multiplication: return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .division: return Color(red: 0.6, green: 0.3, blue: 0.85)
        }
    }
    
    var gradeColor: Color {
        if percentage >= 90 { return .green }
        if percentage >= 70 { return .orange }
        return .red
    }
    
    var gradeLetter: String {
        if percentage >= 90 { return "A" }
        if percentage >= 80 { return "B" }
        if percentage >= 70 { return "C" }
        if percentage >= 60 { return "D" }
        return "F"
    }
    
    var body: some View {
        GeometryReader { geo in
        let contentMaxWidth: CGFloat = isIPad ? geo.size.width * 0.70 : .infinity
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Score header
                    VStack(spacing: 12) {
                        Text(studentName)
                            .font(isIPad ? .largeTitle : .title2)
                            .fontWeight(.bold)
                        
                        ZStack {
                            Circle()
                                .stroke(gradeColor.opacity(0.2), lineWidth: 12)
                                .frame(width: isIPad ? 170 : 120, height: isIPad ? 170 : 120)
                            Circle()
                                .trim(from: 0, to: CGFloat(percentage / 100))
                                .stroke(gradeColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .frame(width: isIPad ? 170 : 120, height: isIPad ? 170 : 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.0), value: percentage)
                            
                            VStack(spacing: 2) {
                                Text(gradeLetter)
                                    .font(.system(size: isIPad ? 52 : 36, weight: .bold))
                                    .foregroundStyle(gradeColor)
                                Text(String(format: "%.0f%%", percentage))
                                    .font(isIPad ? .subheadline : .caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Text("\(numCorrect) out of \(cards.count) correct")
                            .font(isIPad ? .title2 : .headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Stats row
                    HStack(spacing: 12) {
                        StatBadge(icon: "function", label: "Operation", value: operation.rawValue, color: accentColor)
                        StatBadge(icon: "clock", label: "Time Remaining", value: timeRemaining, color: .blue)
                    }
                    .padding(.horizontal, 20)
                    
                    // Question breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Question Breakdown")
                            .font(isIPad ? .title2 : .headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 1) {
                            ForEach(cards, id: \.questionNum) { card in
                                QuestionResultRow(card: card, operation: operation)
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Done button
                    Button {
                        navState.goToRoot()
                    } label: {
                        Text("Done")
                            .font(isIPad ? .title2 : .headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                    }
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Home") { navState.goToRoot() }
            }
        }
        .task {
            guard isFromTest, let milestone = ReviewPrompt.dueMilestone else { return }
            // Let the results screen settle before the system prompt appears.
            guard (try? await Task.sleep(for: .seconds(1.5))) != nil else { return }
            // Pass the scene explicitly; the SwiftUI requestReview environment
            // action failed here with "Could not get scene to request a review".
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
            ReviewPrompt.markPrompted(milestone)
            AppStore.requestReview(in: scene)
        }
    }
}

struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(isIPad ? .largeTitle : .title2)
                .foregroundStyle(color)
            Text(value)
                .font(isIPad ? .title3 : .subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(isIPad ? .subheadline : .caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isIPad ? 24 : 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct QuestionResultRow: View {
    let card: Card
    let operation: Operation
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        HStack {
            Text("#\(card.questionNum)")
                .font(isIPad ? .subheadline : .caption)
                .foregroundStyle(.secondary)
                .frame(width: isIPad ? 40 : 28, alignment: .leading)
            
            Text("\(card.firstNum) \(operation.sign) \(card.secondNum) = \(card.answer)")
                .font(.system(isIPad ? .title3 : .body, design: .monospaced))
            
            Spacer()
            
            if card.isViewed {
                if card.isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(card.studentAnswer.isEmpty ? "—" : card.studentAnswer)
                            .font(isIPad ? .caption : .caption2)
                            .foregroundStyle(.red)
                    }
                }
            } else {
                Text("—")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, isIPad ? 14 : 10)
        .background(Color(.secondarySystemGroupedBackground))
    }
}
