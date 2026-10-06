import SwiftUI

/// Animated rolling counter component inspired by slot-machine / odometer tumbling counters.
/// Supports discrete place arrays (e.g. `[100, 10, 1]`), auto-detected digits, floating-point decimals (e.g. CGPA 8.95),
/// custom fonts, colors, and stagger animations.
public struct Counter: View {
    public let value: Double
    public let places: [Int]?
    public let decimalPlaces: Int
    public let fontSize: CGFloat
    public let padding: CGFloat
    public let gap: CGFloat
    public let textColor: Color
    public let fontWeight: Font.Weight
    public let fontDesign: Font.Design
    public let prefix: String
    public let suffix: String
    public let gradient: LinearGradient?

    @State private var animatedValue: Double = 0
    @State private var hasAppeared = false

    /// Initializer matching exact React / React Bits specification:
    /// ```swift
    /// Counter(
    ///   value: 1,
    ///   places: [100, 10, 1],
    ///   fontSize: 80,
    ///   padding: 5,
    ///   gap: 10,
    ///   textColor: .white,
    ///   fontWeight: .black
    /// )
    /// ```
    public init(
        value: Int,
        places: [Int]? = nil,
        fontSize: CGFloat = 80,
        padding: CGFloat = 5,
        gap: CGFloat = 10,
        textColor: Color = .white,
        fontWeight: Font.Weight = .black,
        fontDesign: Font.Design = .rounded,
        prefix: String = "",
        suffix: String = "",
        gradient: LinearGradient? = nil
    ) {
        self.value = Double(value)
        self.places = places
        self.decimalPlaces = 0
        self.fontSize = fontSize
        self.padding = padding
        self.gap = gap
        self.textColor = textColor
        self.fontWeight = fontWeight
        self.fontDesign = fontDesign
        self.prefix = prefix
        self.suffix = suffix
        self.gradient = gradient
    }

    /// Initializer for floating point numbers (e.g., CGPA 8.95 or percentages)
    public init(
        value: Double,
        decimalPlaces: Int = 2,
        places: [Int]? = nil,
        fontSize: CGFloat = 28,
        padding: CGFloat = 2,
        gap: CGFloat = 2,
        textColor: Color = .white,
        fontWeight: Font.Weight = .heavy,
        fontDesign: Font.Design = .rounded,
        prefix: String = "",
        suffix: String = "",
        gradient: LinearGradient? = nil
    ) {
        self.value = value
        self.places = places
        self.decimalPlaces = decimalPlaces
        self.fontSize = fontSize
        self.padding = padding
        self.gap = gap
        self.textColor = textColor
        self.fontWeight = fontWeight
        self.fontDesign = fontDesign
        self.prefix = prefix
        self.suffix = suffix
        self.gradient = gradient
    }

    public var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: gap) {
            if !prefix.isEmpty {
                Text(prefix)
                    .font(.system(size: fontSize * 0.75, weight: fontWeight, design: fontDesign))
                    .foregroundStyle(textColor)
            }

            if let explicitPlaces = places, !explicitPlaces.isEmpty {
                // Fixed place value columns, e.g. [100, 10, 1]
                HStack(spacing: gap) {
                    ForEach(Array(explicitPlaces.enumerated()), id: \.offset) { index, place in
                        let digit = digitForPlace(value: animatedValue, place: place)
                        SingleDigitColumn(
                            digit: digit,
                            fontSize: fontSize,
                            padding: padding,
                            textColor: textColor,
                            fontWeight: fontWeight,
                            fontDesign: fontDesign,
                            gradient: gradient,
                            staggerDelay: Double(index) * 0.06
                        )
                    }
                }
            } else {
                // Auto-formatted number columns (supports integers & decimals like 8.95)
                HStack(alignment: .lastTextBaseline, spacing: gap) {
                    let formattedString = formatValue(animatedValue)
                    ForEach(Array(formattedString.enumerated()), id: \.offset) { index, char in
                        if let digit = char.wholeNumberValue {
                            SingleDigitColumn(
                                digit: digit,
                                fontSize: fontSize,
                                padding: padding,
                                textColor: textColor,
                                fontWeight: fontWeight,
                                fontDesign: fontDesign,
                                gradient: gradient,
                                staggerDelay: Double(index) * 0.05
                            )
                        } else {
                            // Separator like "." or ","
                            Text(String(char))
                                .font(.system(size: fontSize, weight: fontWeight, design: fontDesign))
                                .foregroundStyle(textColor)
                                .frame(height: digitHeight)
                                .padding(.horizontal, gap * 0.2)
                        }
                    }
                }
            }

            if !suffix.isEmpty {
                Text(suffix)
                    .font(.system(size: fontSize * 0.75, weight: fontWeight, design: fontDesign))
                    .foregroundStyle(textColor)
            }
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                // Start from 0 and animate to target value
                withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                    animatedValue = value
                }
            } else {
                animatedValue = value
            }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                animatedValue = newValue
            }
        }
    }

    private var digitHeight: CGFloat {
        fontSize * 1.22
    }

    private func digitForPlace(value: Double, place: Int) -> Int {
        guard place > 0 else { return 0 }
        let intVal = max(0, Int(value.rounded(.down)))
        return (intVal / place) % 10
    }

    private func formatValue(_ val: Double) -> String {
        if decimalPlaces > 0 {
            return String(format: "%.\(decimalPlaces)f", val)
        } else {
            return "\(Int(val.rounded()))"
        }
    }
}

/// A vertical column that contains numbers 0 through 9 and rolls to the target digit.
public struct SingleDigitColumn: View {
    public let digit: Int
    public let fontSize: CGFloat
    public let padding: CGFloat
    public let textColor: Color
    public let fontWeight: Font.Weight
    public let fontDesign: Font.Design
    public let gradient: LinearGradient?
    public let staggerDelay: Double

    @State private var renderedDigit: Int = 0

    private var digitHeight: CGFloat {
        fontSize * 1.22
    }

    private var digitWidth: CGFloat {
        fontSize * 0.64
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<10, id: \.self) { num in
                Text("\(num)")
                    .font(.system(size: fontSize, weight: fontWeight, design: fontDesign))
                    .foregroundStyle(
                        gradient != nil
                            ? AnyShapeStyle(gradient!)
                            : AnyShapeStyle(textColor)
                    )
                    .frame(width: digitWidth, height: digitHeight)
            }
        }
        .offset(y: -CGFloat(renderedDigit) * digitHeight)
        .frame(width: digitWidth, height: digitHeight, alignment: .top)
        .clipped()
        .padding(.vertical, padding)
        .onAppear {
            renderedDigit = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + staggerDelay) {
                withAnimation(.spring(response: 0.75, dampingFraction: 0.72)) {
                    renderedDigit = max(0, min(9, digit))
                }
            }
        }
        .onChange(of: digit) { _, newDigit in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.74)) {
                renderedDigit = max(0, min(9, newDigit))
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 36) {
            Text("Places: [100, 10, 1]")
                .font(.caption)
                .foregroundStyle(.gray)

            Counter(
                value: 1,
                places: [100, 10, 1],
                fontSize: 80,
                padding: 5,
                gap: 10,
                textColor: .white,
                fontWeight: .black
            )

            Text("CGPA Counter (8.95)")
                .font(.caption)
                .foregroundStyle(.gray)

            Counter(
                value: 8.95,
                decimalPlaces: 2,
                fontSize: 48,
                padding: 3,
                gap: 4,
                textColor: Color(red: 0.45, green: 0.75, blue: 1.0),
                fontWeight: .heavy
            )
        }
    }
}
