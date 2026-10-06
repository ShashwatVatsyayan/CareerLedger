import SwiftUI

public enum TiltEffect {
    case gravitate
    case evade
}

/// A native SwiftUI 3D perspective Tilt Card with dynamic following spotlight,
/// matching the React TiltCard specification.
public struct TiltCard<Content: View>: View {
    public var tiltLimit: Double
    public var scale: CGFloat
    public var effect: TiltEffect
    public var spotlight: Bool
    public var tint: Color
    public var cornerRadius: CGFloat
    @ViewBuilder public var content: () -> Content

    @Environment(\.colorScheme) private var colorScheme
    @State private var isInteracting = false
    @State private var touchPos = UnitPoint(x: 0.5, y: 0.5)
    @State private var xRot: Double = 0
    @State private var yRot: Double = 0
    @State private var currentScale: CGFloat = 1.0

    public init(
        tiltLimit: Double = 12,
        scale: CGFloat = 1.035,
        effect: TiltEffect = .evade,
        spotlight: Bool = true,
        tint: Color = .blue,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tiltLimit = tiltLimit
        self.scale = scale
        self.effect = effect
        self.spotlight = spotlight
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.content = content
    }

    private var dir: Double {
        effect == .evade ? -1.0 : 1.0
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                // Card Content
                content()

                // Dynamic following spotlight
                if spotlight {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    tint.opacity(0.16),
                                    Color.clear
                                ],
                                center: touchPos,
                                startRadius: 0,
                                endRadius: max(size.width, size.height) * 0.75
                            )
                        )
                        .opacity(isInteracting ? 1 : 0)
                        .animation(.easeInOut(duration: 0.25), value: isInteracting)
                        .blendMode(.plusLighter)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                // Dynamic border highlight responding to spotlight position
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            stops: colorScheme == .dark
                                ? [
                                    .init(color: isInteracting ? Color.white.opacity(0.45) : Color.white.opacity(0.22), location: 0.0),
                                    .init(color: isInteracting ? tint.opacity(0.5) : tint.opacity(0.2), location: 0.4),
                                    .init(color: Color.black.opacity(0.7), location: 1.0)
                                ]
                                : [
                                    .init(color: isInteracting ? tint.opacity(0.6) : tint.opacity(0.35), location: 0.0),
                                    .init(color: isInteracting ? tint.opacity(0.25) : Color.primary.opacity(0.10), location: 0.4),
                                    .init(color: Color.primary.opacity(0.04), location: 1.0)
                                ],
                            startPoint: touchPos,
                            endPoint: UnitPoint(x: 1.0 - touchPos.x, y: 1.0 - touchPos.y)
                        ),
                        lineWidth: 1.2
                    )
                    .allowsHitTesting(false)
            }
            .shadow(
                color: colorScheme == .dark
                    ? (isInteracting ? tint.opacity(0.28) : Color.black.opacity(0.4))
                    : (isInteracting ? tint.opacity(0.20) : Color.black.opacity(0.06)),
                radius: isInteracting ? 18 : 10,
                x: CGFloat(-yRot * 0.4),
                y: CGFloat(xRot * 0.4) + (isInteracting ? 6 : 3)
            )
            .animation(.easeInOut(duration: 0.35), value: colorScheme)
            .rotation3DEffect(
                .degrees(xRot),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.65
            )
            .rotation3DEffect(
                .degrees(yRot),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.65
            )
            .scaleEffect(currentScale)
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    updateTilt(at: location, in: size)
                case .ended:
                    resetTilt()
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onChanged { value in
                        updateTilt(at: value.location, in: size)
                    }
                    .onEnded { _ in
                        resetTilt()
                    }
            )
        }
    }

    private func updateTilt(at point: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        let px = min(max(point.x / size.width, 0.0), 1.0)
        let py = min(max(point.y / size.height, 0.0), 1.0)

        touchPos = UnitPoint(x: px, y: py)

        let targetXRot = (Double(py) - 0.5) * (tiltLimit * 2.0) * dir
        let targetYRot = (Double(px) - 0.5) * -(tiltLimit * 2.0) * dir

        withAnimation(.easeOut(duration: 0.12)) {
            isInteracting = true
            xRot = targetXRot
            yRot = targetYRot
            currentScale = scale
        }
    }

    private func resetTilt() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
            isInteracting = false
            xRot = 0
            yRot = 0
            currentScale = 1.0
            touchPos = UnitPoint(x: 0.5, y: 0.5)
        }
    }
}
