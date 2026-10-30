import SwiftUI

struct HomeView: View {
    @State private var selectedOperation: Operation? = nil
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        GeometryReader { geo in
            // Compact height = small iPhone (SE etc.), where vertical space is tight
            let compact = geo.size.height < 700
            let btnSpacing: CGFloat  = compact ? 8  : 14
            let signFont: CGFloat    = compact ? 80 : (isIPad ? 168 : 128)
            let vertPad: CGFloat     = compact ? 8  : (isIPad ? 40 : 14)
            // Large iPad = 13" iPad Pro/Air (min dimension >= 1000pt, excludes smaller iPads)
            let isLargeIPad = min(geo.size.width, geo.size.height) >= 1000
            let largeIPadGridWidth: CGFloat = geo.size.width * 0.80
            let largeIPadBtnSize: CGFloat   = (largeIPadGridWidth - btnSpacing) / 2
            let headerFontSize: CGFloat = compact ? 28 : (isLargeIPad ? 76 : (isIPad ? 52 : 34))
            let subtitleFont: Font = isLargeIPad ? .title : (isIPad ? .title3 : .subheadline)
            let startButtonFont: Font = isLargeIPad ? .title : (isIPad ? .title3 : .body)
            let startButtonVerticalPadding: CGFloat = isLargeIPad ? 44 : (isIPad ? 22 : 16)
            let navIconFont: Font = isLargeIPad ? .system(size: 44, weight: .semibold) : (isIPad ? .largeTitle : .title2)
            let navTextFont: Font = isLargeIPad ? .title3 : (isIPad ? .callout : .caption2)

            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Header ────────────────────────────────────────
                    VStack(spacing: 4) {
                        Text("Welcome!")
                            .font(.system(size: headerFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Text("Select an operation to begin")
                            .font(subtitleFont)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, compact ? 12 : (isLargeIPad ? 32 : 20))
                    .padding(.bottom, compact ? 14 : (isLargeIPad ? 40 : 28))

                    // ── Operation Buttons ──────────────────────────────
                    VStack(spacing: btnSpacing) {
                        HStack(spacing: btnSpacing) {
                            OperationButton(op: .addition,
                                            isSelected: selectedOperation == .addition,
                                            fontSize: signFont, vertPad: vertPad,
                                            squareSize: isLargeIPad ? largeIPadBtnSize : nil) {
                                selectedOperation = selectedOperation == .addition ? nil : .addition
                            }
                            OperationButton(op: .subtraction,
                                            isSelected: selectedOperation == .subtraction,
                                            fontSize: signFont, vertPad: vertPad,
                                            squareSize: isLargeIPad ? largeIPadBtnSize : nil) {
                                selectedOperation = selectedOperation == .subtraction ? nil : .subtraction
                            }
                        }
                        HStack(spacing: btnSpacing) {
                            OperationButton(op: .multiplication,
                                            isSelected: selectedOperation == .multiplication,
                                            fontSize: signFont, vertPad: vertPad,
                                            squareSize: isLargeIPad ? largeIPadBtnSize : nil) {
                                selectedOperation = selectedOperation == .multiplication ? nil : .multiplication
                            }
                            OperationButton(op: .division,
                                            isSelected: selectedOperation == .division,
                                            fontSize: signFont, vertPad: vertPad,
                                            squareSize: isLargeIPad ? largeIPadBtnSize : nil) {
                                selectedOperation = selectedOperation == .division ? nil : .division
                            }
                        }
                    }
                    .frame(maxWidth: isLargeIPad ? largeIPadGridWidth : (isIPad ? 500 : .infinity))
                    // Expand to fill parent width so VStack centers the fixed-size grid
                    .frame(maxWidth: isLargeIPad ? .infinity : nil, alignment: .center)
                    .padding(.horizontal, isLargeIPad ? 0 : 20)

                    Spacer(minLength: 12)

                    // ── Start Test Button ──────────────────────────────
                    Group {
                        if let op = selectedOperation {
                            NavigationLink(destination: TestConfigView(operation: op)) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Start \(op.rawValue) Test")
                                        .font(startButtonFont)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, startButtonVerticalPadding)
                                .background(operationColor(op))
                                .foregroundStyle(.white)
                                .cornerRadius(16)
                                .padding(.horizontal, 20)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 14)

                    // ── Bottom Nav ─────────────────────────────────────
                    HStack(spacing: 0) {
                        NavigationLink(destination: ChallengeMenuView()) {
                            VStack(spacing: 4) {
                                Image(systemName: "star").font(navIconFont)
                                Text("Challenge").font(navTextFont)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isIPad ? 22 : 12)
                        }
                        NavigationLink(destination: SavedTestsView(filterByUser: nil)) {
                            VStack(spacing: 4) {
                                Image(systemName: "list.bullet.clipboard").font(navIconFont)
                                Text("Saved Tests").font(navTextFont)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isIPad ? 22 : 12)
                        }
                        NavigationLink(destination: SettingsView()) {
                            VStack(spacing: 4) {
                                Image(systemName: "gearshape").font(navIconFont)
                                Text("Settings").font(navTextFont)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isIPad ? 22 : 12)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                }
                // Center content column on iPad (large iPad widened to accommodate 80% button grid)
                .frame(maxWidth: isLargeIPad ? geo.size.width * 0.85 : (isIPad ? geo.size.width * 0.70 : .infinity))
            }
        }
        .navigationBarHidden(true)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedOperation)
    }

    func operationColor(_ op: Operation) -> Color {
        switch op {
        case .addition:       return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .subtraction:    return Color(red: 0.2, green: 0.6, blue: 0.8)
        case .multiplication: return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .division:       return Color(red: 0.6, green: 0.3, blue: 0.85)
        }
    }
}

// MARK: - Operation Button

struct OperationButton: View {
    let op: Operation
    let isSelected: Bool
    var fontSize: CGFloat = 128   // caller can shrink for compact screens
    var vertPad: CGFloat  = 14
    var squareSize: CGFloat? = nil // when set, renders as a fixed square (large iPad layout)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if let size = squareSize {
                squareContent(size: size)
            } else {
                expandableContent
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }

    // Fixed square layout for large iPads
    // Font size * 1.0: SF Pro cap height is ~72% of point size, so 1.0 * 0.72 ≈ 72% visual fill
    @ViewBuilder
    private func squareContent(size: CGFloat) -> some View {
        Image(systemName: symbolName)
            .font(.system(size: size * 0.72, weight: .bold))
            .foregroundStyle(isSelected ? .white : bgColor)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(isSelected ? bgColor : Color(.secondarySystemGroupedBackground))
                    .shadow(color: isSelected ? bgColor.opacity(0.4) : .clear, radius: 14, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(isSelected ? .clear : Color(.separator).opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }

    // Expanding layout for standard screens
    @ViewBuilder
    private var expandableContent: some View {
        Text(op.sign)
            .font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .foregroundStyle(isSelected ? .white : bgColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, vertPad)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? bgColor : Color(.secondarySystemGroupedBackground))
                    .shadow(color: isSelected ? bgColor.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? .clear : Color(.separator).opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }

    var bgColor: Color {
        switch op {
        case .addition:       return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .subtraction:    return Color(red: 0.2, green: 0.6, blue: 0.8)
        case .multiplication: return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .division:       return Color(red: 0.6, green: 0.3, blue: 0.85)
        }
    }

    var symbolName: String {
        switch op {
        case .addition:       return "plus"
        case .subtraction:    return "minus"
        case .multiplication: return "multiply"
        case .division:       return "divide"
        }
    }
}

// MARK: - Corner radius helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
