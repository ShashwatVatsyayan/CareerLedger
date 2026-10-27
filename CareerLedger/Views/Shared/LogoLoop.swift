import Combine
import SwiftUI

/// Item definition for the LogoLoop continuous ticker.
public struct LogoItem: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let systemImage: String?
    public let badgeText: String?
    public let tintColor: Color
    public let bgGradient: [Color]
    public let href: String?

    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        badgeText: String? = nil,
        tintColor: Color = .blue,
        bgGradient: [Color]? = nil,
        href: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.badgeText = badgeText
        self.tintColor = tintColor
        self.bgGradient = bgGradient ?? [tintColor.opacity(0.25), tintColor.opacity(0.08)]
        self.href = href
    }

    /// Curated technology partners & ecosystem stack for CareerLedger
    public static let defaultTechLogos: [LogoItem] = [
        LogoItem(
            title: "React",
            subtitle: "UI Library",
            systemImage: "atom",
            tintColor: Color(red: 0.38, green: 0.85, blue: 0.98),
            href: "https://react.dev"
        ),
        LogoItem(
            title: "Next.js",
            subtitle: "Fullstack Web",
            systemImage: "triangle.fill",
            tintColor: Color(white: 0.95),
            href: "https://nextjs.org"
        ),
        LogoItem(
            title: "TypeScript",
            subtitle: "Typed JS",
            badgeText: "TS",
            tintColor: Color(red: 0.20, green: 0.52, blue: 0.95),
            href: "https://www.typescriptlang.org"
        ),
        LogoItem(
            title: "Tailwind CSS",
            subtitle: "Design System",
            systemImage: "wind",
            tintColor: Color(red: 0.22, green: 0.75, blue: 0.88),
            href: "https://tailwindcss.com"
        ),
        LogoItem(
            title: "SwiftUI",
            subtitle: "Apple Native",
            systemImage: "square.stack.3d.up.fill",
            tintColor: Color(red: 0.98, green: 0.40, blue: 0.22),
            href: "https://developer.apple.com/xcode/swiftui/"
        ),
        LogoItem(
            title: "Supabase",
            subtitle: "Backend & Auth",
            systemImage: "bolt.fill",
            tintColor: Color(red: 0.24, green: 0.80, blue: 0.55),
            href: "https://supabase.com"
        ),
        LogoItem(
            title: "Python",
            subtitle: "Backend & Scripts",
            systemImage: "terminal.fill",
            tintColor: Color(red: 0.95, green: 0.78, blue: 0.25),
            href: "https://www.python.org"
        ),
        LogoItem(
            title: "GitHub",
            subtitle: "Version Control",
            systemImage: "chevron.left.forwardslash.chevron.right",
            tintColor: Color(red: 0.82, green: 0.84, blue: 0.90),
            href: "https://github.com"
        ),
        LogoItem(
            title: "Google Cloud",
            subtitle: "Credentials",
            systemImage: "cloud.sun.fill",
            tintColor: Color(red: 0.95, green: 0.45, blue: 0.35),
            href: "https://cloud.google.com"
        ),
        LogoItem(
            title: "Apple Dev",
            subtitle: "Ecosystem",
            systemImage: "apple.logo",
            tintColor: Color(red: 0.90, green: 0.92, blue: 0.98),
            href: "https://developer.apple.com"
        )
    ]
}

public enum LoopDirection {
    case left
    case right
    case up
    case down
}

/// Ultra-smooth infinite marquee ticker with hover deceleration, edge fade-out,
/// scale-on-press/hover, and interactive glassmorphic cards.
public struct LogoLoop: View {
    public let logos: [LogoItem]
    public let speed: Double
    public let direction: LoopDirection
    public let logoHeight: CGFloat
    public let gap: CGFloat
    public let hoverSpeed: Double
    public let scaleOnHover: Bool
    public let fadeOut: Bool
    public let fadeOutWidth: CGFloat
    public let fadeOutColor: Color?
    public let ariaLabel: String?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    @State private var offset: CGFloat = 0
    @State private var isInteracting: Bool = false
    @State private var contentWidth: CGFloat = 0
    @State private var hoveredCardId: String? = nil
    @State private var dragOffset: CGFloat = 0

    // High frequency display ticker
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    @State private var lastTimestamp: TimeInterval = 0

    public init(
        logos: [LogoItem] = LogoItem.defaultTechLogos,
        speed: Double = 60,
        direction: LoopDirection = .left,
        logoHeight: CGFloat = 48,
        gap: CGFloat = 16,
        hoverSpeed: Double = 0,
        scaleOnHover: Bool = true,
        fadeOut: Bool = true,
        fadeOutWidth: CGFloat = 40,
        fadeOutColor: Color? = nil,
        ariaLabel: String? = "Technology partners"
    ) {
        self.logos = logos
        self.speed = speed
        self.direction = direction
        self.logoHeight = logoHeight
        self.gap = gap
        self.hoverSpeed = hoverSpeed
        self.scaleOnHover = scaleOnHover
        self.fadeOut = fadeOut
        self.fadeOutWidth = fadeOutWidth
        self.fadeOutColor = fadeOutColor
        self.ariaLabel = ariaLabel
    }

    public var body: some View {
        GeometryReader { proxy in
            let viewWidth = proxy.size.width

            ZStack(alignment: .leading) {
                // Repeating double track for seamless infinite looping
                HStack(spacing: gap) {
                    trackSet
                        .background(
                            GeometryReader { innerProxy in
                                Color.clear
                                    .preference(key: TrackWidthPreferenceKey.self, value: innerProxy.size.width)
                            }
                        )

                    trackSet
                    trackSet
                }
                .offset(x: -effectiveOffset + dragOffset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            isInteracting = true
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            // Apply drag delta into continuous offset
                            if contentWidth > 0 {
                                offset = (offset - value.translation.width).truncatingRemainder(dividingBy: contentWidth)
                                if offset < 0 { offset += contentWidth }
                            }
                            dragOffset = 0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isInteracting = false
                            }
                        }
                )

                // Optional Fade Out Edge Overlays
                if fadeOut {
                    edgeFadeOverlays(width: viewWidth)
                }
            }
            .frame(width: viewWidth, height: logoHeight + 24, alignment: .leading)
            .clipped()
            .onPreferenceChange(TrackWidthPreferenceKey.self) { newWidth in
                if newWidth > 0 {
                    contentWidth = newWidth + gap
                }
            }
            .onReceive(timer) { _ in
                let now = Date().timeIntervalSinceReferenceDate
                let delta = lastTimestamp == 0 ? 0.016 : min(now - lastTimestamp, 0.1)
                lastTimestamp = now

                guard contentWidth > 0 else { return }

                let activeSpeed = isInteracting ? hoverSpeed : speed
                let step = CGFloat(delta * activeSpeed)

                switch direction {
                case .left, .up:
                    offset += step
                    if offset >= contentWidth {
                        offset -= contentWidth
                    }
                case .right, .down:
                    offset -= step
                    if offset < 0 {
                        offset += contentWidth
                    }
                }
            }
        }
        .frame(height: logoHeight + 24)
        .accessibilityLabel(ariaLabel ?? "Technology partners")
    }

    private var effectiveOffset: CGFloat {
        if contentWidth > 0 {
            return offset.truncatingRemainder(dividingBy: contentWidth)
        }
        return offset
    }

    private var trackSet: some View {
        HStack(spacing: gap) {
            ForEach(logos) { item in
                logoCard(item)
            }
        }
    }

    @ViewBuilder
    private func logoCard(_ item: LogoItem) -> some View {
        let isHovered = hoveredCardId == item.id

        Button {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
            #endif
            if let href = item.href, let url = URL(string: href) {
                openURL(url)
            }
        } label: {
            HStack(spacing: 10) {
                // Icon or Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: item.bgGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)

                    if let sysImg = item.systemImage {
                        Image(systemName: sysImg)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(item.tintColor)
                    } else if let badge = item.badgeText {
                        Text(badge)
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundStyle(item.tintColor)
                    }
                }
                .shadow(color: item.tintColor.opacity(isHovered ? 0.45 : 0.2), radius: isHovered ? 8 : 4, x: 0, y: 1)

                // Labels
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.primary)
                        .lineLimit(1)

                    if let sub = item.subtitle {
                        Text(sub)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(colorScheme == .dark ? Color(red: 0.62, green: 0.65, blue: 0.72) : Color.secondary)
                            .lineLimit(1)
                    }
                }

                if item.href != nil {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(item.tintColor.opacity(0.7))
                        .padding(.leading, 2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(height: logoHeight)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color(red: 0.08, green: 0.09, blue: 0.12)
                            : Color(white: 0.96)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(
                                isHovered ? item.tintColor.opacity(0.8) : Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2),
                                lineWidth: 0.8
                            )
                    )
            )
            .scaleEffect(scaleOnHover && isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredCardId = hovering ? item.id : nil
            isInteracting = hovering
        }
    }

    @ViewBuilder
    private func edgeFadeOverlays(width: CGFloat) -> some View {
        let fadeColor = fadeOutColor ?? (colorScheme == .dark ? Color(red: 0.05, green: 0.05, blue: 0.07) : Color(white: 0.97))

        HStack {
            LinearGradient(
                colors: [fadeColor, fadeColor.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: fadeOutWidth)
            .allowsHitTesting(false)

            Spacer()

            LinearGradient(
                colors: [fadeColor.opacity(0), fadeColor],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: fadeOutWidth)
            .allowsHitTesting(false)
        }
    }
}

private struct TrackWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 24) {
            Text("TECH STACK & PARTNERS")
                .font(.caption)
                .fontWeight(.heavy)
                .foregroundStyle(.gray)

            LogoLoop(
                logos: LogoItem.defaultTechLogos,
                speed: 80,
                direction: .left,
                logoHeight: 52,
                gap: 16,
                hoverSpeed: 0,
                scaleOnHover: true,
                fadeOut: true
            )
            .padding(.horizontal)
        }
    }
}
