import SwiftUI

/// A native SwiftUI reproduction of the high-end 3D Liquid Metal Shader Button
/// Inspired by @paper-design/shaders liquid metal fragment shader with chromatic shifts,
/// multi-depth 3D perspective plates, inner gradient pills, dynamic speed bursts, and expanding touch ripples.
public struct LiquidMetalButton: View {
    public let label: String
    public var icon: String? = "sparkles"
    public var width: CGFloat? = nil
    public var height: CGFloat = 52
    public var action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var ripples: [Ripple] = []
    @State private var rippleCounter = 0
    @State private var speedMultiplier: Double = 1.0
    @State private var speedDecayTask: Task<Void, Never>? = nil

    public init(
        label: String = "Login",
        icon: String? = "sparkles",
        width: CGFloat? = nil,
        height: CGFloat = 52,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.icon = icon
        self.width = width
        self.height = height
        self.action = action
    }

    public var body: some View {
        GeometryReader { proxy in
            let effectiveWidth = width ?? proxy.size.width

            ZStack {
                // Outer 3D perspective layer (Z: 0) - Molten Liquid Metal Shader Flow
                LiquidMetalShaderCanvas(speedMultiplier: speedMultiplier)
                    .frame(width: effectiveWidth, height: height)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.25),
                                        Color.black.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    }
                    .shadow(
                        color: Color.black.opacity(isPressed ? 0.3 : 0.5),
                        radius: isPressed ? 4 : 12,
                        x: 0,
                        y: isPressed ? 2 : 6
                    )
                    .shadow(
                        color: Color(red: 0.3, green: 0.4, blue: 0.7).opacity(isHovered ? 0.35 : 0.15),
                        radius: isHovered ? 20 : 10,
                        x: 0,
                        y: 0
                    )

                // Middle 3D Inset Plate (Z: 10) - Dark Obsidian Metallic Pill
                Capsule()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.14, green: 0.14, blue: 0.16), location: 0.0),
                                .init(color: Color(red: 0.08, green: 0.08, blue: 0.09), location: 0.4),
                                .init(color: Color.black, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(effectiveWidth - 4, 10), height: max(height - 4, 10))
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.18),
                                        Color.white.opacity(0.04),
                                        Color.black.opacity(0.6)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.8
                            )
                    }
                    .scaleEffect(isPressed ? 0.985 : 1.0)
                    .offset(y: isPressed ? 1 : 0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)

                // Top Content Layer (Z: 20) - Sparkles & Label
                HStack(spacing: 8) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color(red: 0.82, green: 0.84, blue: 0.92)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                    }

                    Text(label)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.85, green: 0.86, blue: 0.90)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                }
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .offset(y: isPressed ? 1 : 0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
                .allowsHitTesting(false)

                // Ripple effects container (Z: 25)
                ForEach(ripples) { ripple in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.45),
                                    Color(red: 0.6, green: 0.8, blue: 1.0).opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 70, height: 70)
                        .position(x: ripple.x, y: ripple.y)
                        .scaleEffect(ripple.scale)
                        .opacity(ripple.opacity)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: effectiveWidth, height: height)
            .contentShape(Capsule())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isPressed {
                            isPressed = true
                            triggerRipple(at: value.location)
                        }
                    }
                    .onEnded { value in
                        isPressed = false
                        let buttonRect = CGRect(x: 0, y: 0, width: effectiveWidth, height: height)
                        if buttonRect.contains(value.location) {
                            action()
                        }
                    }
            )
            #if os(macOS)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isHovered = hovering
                    speedMultiplier = hovering ? 1.5 : 1.0
                }
            }
            #endif
        }
        .frame(height: height)
        .frame(maxWidth: width != nil ? width : .infinity)
    }

    private func triggerRipple(at point: CGPoint) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        // Accelerate shader flow speed to 2.4x on press (matching Paper Design shader burst)
        withAnimation(.easeOut(duration: 0.15)) {
            speedMultiplier = 2.4
        }

        speedDecayTask?.cancel()
        speedDecayTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.4)) {
                        speedMultiplier = isHovered ? 1.4 : 1.0
                    }
                }
            }
        }

        let newRipple = Ripple(id: rippleCounter, x: point.x, y: point.y, scale: 0.1, opacity: 0.7)
        rippleCounter += 1
        ripples.append(newRipple)

        withAnimation(.easeOut(duration: 0.6)) {
            if let index = ripples.firstIndex(where: { $0.id == newRipple.id }) {
                ripples[index].scale = 3.5
                ripples[index].opacity = 0.0
            }
        }

        Task {
            try? await Task.sleep(nanoseconds: 650_000_000)
            await MainActor.run {
                ripples.removeAll { $0.id == newRipple.id }
            }
        }
    }
}

private struct Ripple: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    var scale: CGFloat
    var opacity: Double
}

/// Dynamic molten liquid metal procedural canvas shader with chromatic aberration
/// Simulates u_shiftRed (0.3), u_shiftBlue (0.3), 45-degree reflection angle, and molten chrome ripples
private struct LiquidMetalShaderCanvas: View {
    let speedMultiplier: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate * speedMultiplier

            Canvas { context, size in
                let w = size.width
                let h = size.height
                guard w > 0, h > 0 else { return }

                // 1. Dark graphite metallic molten background
                let bgGradient = Gradient(stops: [
                    .init(color: Color(red: 0.10, green: 0.10, blue: 0.12), location: 0.0),
                    .init(color: Color(red: 0.18, green: 0.18, blue: 0.20), location: 0.35),
                    .init(color: Color(red: 0.06, green: 0.06, blue: 0.07), location: 0.7),
                    .init(color: Color(red: 0.15, green: 0.15, blue: 0.17), location: 1.0)
                ])

                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        bgGradient,
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: w, y: h)
                    )
                )

                // 2. Liquid metal dynamic ripples & iridescent chromatic shifts
                // Angle 45 degrees wave flow
                let cycle1 = sin(time * 1.8)
                let cycle2 = cos(time * 1.4 + 1.2)
                let cycle3 = sin(time * 2.2 + 2.5)

                // Wave 1: Shift Blue chromatic sheen
                var bluePath = Path()
                let blueStartX = w * (0.2 + 0.35 * CGFloat(cycle1))
                bluePath.move(to: CGPoint(x: blueStartX - 60, y: 0))
                bluePath.addLine(to: CGPoint(x: blueStartX + 40, y: 0))
                bluePath.addLine(to: CGPoint(x: blueStartX + 100, y: h))
                bluePath.addLine(to: CGPoint(x: blueStartX, y: h))
                bluePath.closeSubpath()

                let blueGradient = Gradient(colors: [
                    Color(red: 0.20, green: 0.45, blue: 0.95).opacity(0.35),
                    Color(red: 0.35, green: 0.65, blue: 1.00).opacity(0.55),
                    Color.clear
                ])
                context.fill(
                    bluePath,
                    with: .linearGradient(
                        blueGradient,
                        startPoint: CGPoint(x: blueStartX, y: 0),
                        endPoint: CGPoint(x: blueStartX + 60, y: h)
                    )
                )

                // Wave 2: Shift Red/Magenta subtle chromatic aberration
                var redPath = Path()
                let redStartX = w * (0.7 + 0.3 * CGFloat(cycle2))
                redPath.move(to: CGPoint(x: redStartX - 40, y: 0))
                redPath.addLine(to: CGPoint(x: redStartX + 30, y: 0))
                redPath.addLine(to: CGPoint(x: redStartX + 80, y: h))
                redPath.addLine(to: CGPoint(x: redStartX + 10, y: h))
                redPath.closeSubpath()

                let redGradient = Gradient(colors: [
                    Color(red: 0.90, green: 0.25, blue: 0.45).opacity(0.28),
                    Color(red: 0.85, green: 0.30, blue: 0.70).opacity(0.40),
                    Color.clear
                ])
                context.fill(
                    redPath,
                    with: .linearGradient(
                        redGradient,
                        startPoint: CGPoint(x: redStartX, y: 0),
                        endPoint: CGPoint(x: redStartX + 50, y: h)
                    )
                )

                // Wave 3: Ultra-bright Liquid Chrome Specular Highlight
                var chromePath = Path()
                let chromeStartX = w * (0.5 + 0.45 * CGFloat(cycle3))
                chromePath.move(to: CGPoint(x: chromeStartX - 30, y: 0))
                chromePath.addLine(to: CGPoint(x: chromeStartX + 25, y: 0))
                chromePath.addLine(to: CGPoint(x: chromeStartX + 65, y: h))
                chromePath.addLine(to: CGPoint(x: chromeStartX + 10, y: h))
                chromePath.closeSubpath()

                let chromeGradient = Gradient(stops: [
                    .init(color: Color.clear, location: 0.0),
                    .init(color: Color.white.opacity(0.85), location: 0.5),
                    .init(color: Color.clear, location: 1.0)
                ])
                context.fill(
                    chromePath,
                    with: .linearGradient(
                        chromeGradient,
                        startPoint: CGPoint(x: chromeStartX - 20, y: 0),
                        endPoint: CGPoint(x: chromeStartX + 50, y: h)
                    )
                )

                // Secondary soft fluid metallic sweep
                let sweepGradient = Gradient(stops: [
                    .init(color: Color.white.opacity(0.15), location: 0.0),
                    .init(color: Color.clear, location: 0.4),
                    .init(color: Color.white.opacity(0.12), location: 0.8),
                    .init(color: Color.clear, location: 1.0)
                ])
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .radialGradient(
                        sweepGradient,
                        center: CGPoint(x: w * 0.5 + CGFloat(cycle1) * 30, y: h * 0.5),
                        startRadius: 5,
                        endRadius: w * 0.7
                    )
                )
            }
        }
    }
}

/// Full-bleed Ambient Liquid Metal Shader background matching the Paper Design liquid metal aesthetic
public struct LiquidMetalBackgroundView: View {
    public var showFluidWaves: Bool

    public init(showFluidWaves: Bool = true) {
        self.showFluidWaves = showFluidWaves
    }

    public var body: some View {
        ZStack {
            // 1. Base deep obsidian graphite gradient
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.05, green: 0.05, blue: 0.07), location: 0.0),
                    .init(color: Color(red: 0.08, green: 0.08, blue: 0.10), location: 0.35),
                    .init(color: Color(red: 0.03, green: 0.03, blue: 0.04), location: 0.7),
                    .init(color: Color(red: 0.06, green: 0.06, blue: 0.08), location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if showFluidWaves {
                // 2. Dynamic molten liquid metal chromatic ribbons at 45 degree angle
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate * 0.35

                    Canvas { context, size in
                        let w = size.width
                        let h = size.height
                        guard w > 0, h > 0 else { return }

                        let cycle1 = sin(time * 0.7)
                        let cycle2 = cos(time * 0.5 + 1.5)
                        let cycle3 = sin(time * 0.8 + 2.4)

                        // Fluid blue ribbon (shiftBlue: 0.3)
                        var bluePath = Path()
                        let blueX = w * (0.3 + 0.35 * CGFloat(cycle1))
                        bluePath.move(to: CGPoint(x: blueX - 160, y: -60))
                        bluePath.addLine(to: CGPoint(x: blueX + 100, y: -60))
                        bluePath.addLine(to: CGPoint(x: blueX + 260, y: h + 60))
                        bluePath.addLine(to: CGPoint(x: blueX, y: h + 60))
                        bluePath.closeSubpath()

                        context.fill(
                            bluePath,
                            with: .linearGradient(
                                Gradient(colors: [
                                    Color(red: 0.18, green: 0.38, blue: 0.90).opacity(0.18),
                                    Color(red: 0.28, green: 0.58, blue: 0.98).opacity(0.12),
                                    Color.clear
                                ]),
                                startPoint: CGPoint(x: blueX - 60, y: 0),
                                endPoint: CGPoint(x: blueX + 160, y: h)
                            )
                        )

                        // Fluid red/magenta ribbon (shiftRed: 0.3)
                        var redPath = Path()
                        let redX = w * (0.7 + 0.25 * CGFloat(cycle2))
                        redPath.move(to: CGPoint(x: redX - 130, y: -60))
                        redPath.addLine(to: CGPoint(x: redX + 80, y: -60))
                        redPath.addLine(to: CGPoint(x: redX + 210, y: h + 60))
                        redPath.addLine(to: CGPoint(x: redX, y: h + 60))
                        redPath.closeSubpath()

                        context.fill(
                            redPath,
                            with: .linearGradient(
                                Gradient(colors: [
                                    Color(red: 0.90, green: 0.22, blue: 0.45).opacity(0.14),
                                    Color(red: 0.78, green: 0.28, blue: 0.65).opacity(0.10),
                                    Color.clear
                                ]),
                                startPoint: CGPoint(x: redX - 50, y: 0),
                                endPoint: CGPoint(x: redX + 130, y: h)
                            )
                        )

                        // Specular liquid chrome reflection ribbon
                        var chromePath = Path()
                        let chromeX = w * (0.5 + 0.3 * CGFloat(cycle3))
                        chromePath.move(to: CGPoint(x: chromeX - 90, y: -60))
                        chromePath.addLine(to: CGPoint(x: chromeX + 70, y: -60))
                        chromePath.addLine(to: CGPoint(x: chromeX + 180, y: h + 60))
                        chromePath.addLine(to: CGPoint(x: chromeX + 20, y: h + 60))
                        chromePath.closeSubpath()

                        context.fill(
                            chromePath,
                            with: .linearGradient(
                                Gradient(stops: [
                                    .init(color: Color.clear, location: 0.0),
                                    .init(color: Color.white.opacity(0.16), location: 0.5),
                                    .init(color: Color.clear, location: 1.0)
                                ]),
                                startPoint: CGPoint(x: chromeX - 50, y: 0),
                                endPoint: CGPoint(x: chromeX + 110, y: h)
                            )
                        )
                    }
                    .blur(radius: 28)
                    .ignoresSafeArea()
                }
            }

            // 3. Radial ambient glow
            RadialGradient(
                colors: [
                    Color(red: 0.25, green: 0.35, blue: 0.65).opacity(0.14),
                    Color.clear
                ],
                center: .top,
                startRadius: 60,
                endRadius: 520
            )
            .ignoresSafeArea()
        }
    }
}

