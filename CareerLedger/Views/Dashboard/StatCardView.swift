import SwiftUI

/// StatCardView enhanced with 3D interactive perspective tilt,
/// cursor/finger following spotlight, and dark obsidian liquid metal styling.
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    var tint: Color = .blue

    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedNumericValue: Double = 0

    private var numberGradient: LinearGradient {
        colorScheme == .dark
            ? LinearGradient(
                colors: [Color.white, Color(red: 0.88, green: 0.90, blue: 0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            : LinearGradient(
                colors: [Color.primary, Color.primary.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
    }

    var body: some View {
        TiltCard(
            tiltLimit: 14,
            scale: 1.04,
            effect: .evade,
            spotlight: true,
            tint: tint,
            cornerRadius: 20
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            LinearGradient(
                                colors: [
                                    tint,
                                    tint.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundStyle(colorScheme == .dark ? Color(red: 0.55, green: 0.58, blue: 0.65) : Color.secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    if Double(value) != nil {
                        let decimals = value.contains(".") ? (value.split(separator: ".").last?.count ?? 2) : 0
                        CountingStatNumber(
                            currentValue: animatedNumericValue,
                            decimalPlaces: decimals,
                            foregroundGradient: numberGradient,
                            shadowColor: colorScheme == .dark ? Color.black.opacity(0.6) : Color.clear
                        )
                    } else {
                        Text(value)
                            .font(.system(size: 27, weight: .heavy, design: .rounded))
                            .foregroundStyle(numberGradient)
                            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.6) : Color.clear, radius: 2, x: 0, y: 1)
                    }

                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(colorScheme == .dark ? Color(red: 0.65, green: 0.68, blue: 0.75) : Color.secondary)
                        .lineLimit(1)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                ZStack {
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.95), location: 0.0),
                            .init(color: Color(white: 0.96).opacity(0.95), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(colorScheme == .dark ? 0 : 1)

                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.15, green: 0.15, blue: 0.18).opacity(0.96), location: 0.0),
                            .init(color: Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.98), location: 0.5),
                            .init(color: Color(red: 0.05, green: 0.05, blue: 0.07), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(colorScheme == .dark ? 1 : 0)
                }
            )
            .animation(.easeInOut(duration: 0.35), value: colorScheme)
        }
        .frame(height: 128)
        .onAppear {
            if let target = Double(value) {
                animatedNumericValue = 0
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedNumericValue = target
                }
            }
        }
        .onChange(of: value) { _, newValue in
            if let target = Double(newValue) {
                withAnimation(.easeOut(duration: 0.8)) {
                    animatedNumericValue = target
                }
            }
        }
    }
}

private struct CountingStatNumber: View, Animatable {
    var currentValue: Double
    let decimalPlaces: Int
    let foregroundGradient: LinearGradient
    let shadowColor: Color

    var animatableData: Double {
        get { currentValue }
        set { currentValue = newValue }
    }

    var body: some View {
        Text(formattedText)
            .font(.system(size: 27, weight: .heavy, design: .rounded))
            .foregroundStyle(foregroundGradient)
            .shadow(color: shadowColor, radius: 2, x: 0, y: 1)
    }

    private var formattedText: String {
        if decimalPlaces > 0 {
            return String(format: "%.\(decimalPlaces)f", currentValue)
        } else {
            return "\(Int(round(currentValue)))"
        }
    }
}

#Preview {
    StatCardView(
        title: "Projects",
        value: "4",
        icon: "folder.fill",
        tint: .purple
    )
    .padding()
    .background(Color.black)
}
