import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(AnyShapeStyle(.regularMaterial))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: isHovered
                                            ? [Color.blue.opacity(0.4), Color.purple.opacity(0.2)]
                                            : [Color.primary.opacity(0.09), Color.primary.opacity(0.03)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.1
                                )
                        }
                        .opacity(colorScheme == .dark ? 0 : 1)

                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            AnyShapeStyle(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color(red: 0.14, green: 0.14, blue: 0.17).opacity(0.92), location: 0.0),
                                        .init(color: Color(red: 0.08, green: 0.08, blue: 0.10).opacity(0.95), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: isHovered
                                            ? [Color.white.opacity(0.45), Color(red: 0.35, green: 0.55, blue: 0.95).opacity(0.4), Color.black.opacity(0.8)]
                                            : [Color.white.opacity(0.24), Color.white.opacity(0.04), Color.black.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.1
                                )
                        }
                        .opacity(colorScheme == .dark ? 1 : 0)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(isHovered ? 0.6 : 0.45)
                    : (isHovered ? Color.blue.opacity(0.12) : Color.black.opacity(0.06)),
                radius: isHovered ? 18 : 12,
                x: 0,
                y: isHovered ? 8 : 4
            )
            .animation(.easeInOut(duration: 0.35), value: colorScheme)
            #if os(macOS)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .onHover { hovering in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    isHovered = hovering
                }
            }
            #endif
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.heavy)
                .tracking(1.2)
                .foregroundStyle(.secondary)
            if let subtitle {
                Text(subtitle)
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct VerificationBadge: View {
    let title: String
    let icon: String
    let tint: Color
    var onTap: (() -> Void)? = nil

    init(status: CertificateVerificationStatus, onTap: (() -> Void)? = nil) {
        self.title = status.badgeTitle
        self.icon = status.iconName
        self.tint = status.tintColor
        self.onTap = onTap
    }

    init(status: VerificationStatus, onTap: (() -> Void)? = nil) {
        self.title = status.displayName.uppercased()
        switch status {
        case .selfReported:
            self.icon = "circle"
            self.tint = .secondary
        case .evidenceProvided:
            self.icon = "checkmark.circle.fill"
            self.tint = .blue
        case .sourceVerified:
            self.icon = "link.badge.plus"
            self.tint = .purple
        case .issuerVerified:
            self.icon = "checkmark.seal.fill"
            self.tint = .green
        }
        self.onTap = onTap
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .opacity(0.6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12))
            .foregroundStyle(tint)
            .overlay {
                Capsule()
                    .strokeBorder(tint.opacity(0.35), lineWidth: 0.8)
            }
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}


struct EvidenceSection: View {
    let items: [EvidenceItem]

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 9) {
                Text("Evidence")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .foregroundStyle(.secondary)

                ForEach(items) { item in
                    if let url = item.url {
                        Link(destination: url) {
                            EvidenceRow(item: item)
                        }
                        .buttonStyle(.plain)
                    } else {
                        EvidenceRow(item: item)
                    }
                }
            }
        }
    }
}

struct EvidenceRow: View {
    let item: EvidenceItem

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.icon)
                .foregroundStyle(item.url == nil ? Color.secondary : Color.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                if let detail = item.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer()
            if item.url != nil {
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct EvidenceItem: Identifiable {
    let id = UUID()
    var title: String
    var detail: String?
    var url: URL?
    var icon: String = "checkmark.circle.fill"
}

struct PremiumEmptyState: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        GlassCard {
            VStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 42))
                    .foregroundStyle(.blue.gradient)
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}

struct AdaptivePage<Content: View>: View {
    let maxWidth: CGFloat
    let content: Content

    init(maxWidth: CGFloat = 1180, @ViewBuilder content: () -> Content) {
        self.maxWidth = maxWidth
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
                .padding(paddingAmount)
                #if !os(macOS)
                .padding(.bottom, 104)
                #endif
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        }
        .background(AppBackground())
    }

    private var paddingAmount: CGFloat {
        #if os(macOS)
        return 24
        #else
        return 16
        #endif
    }
}

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    platformBackground,
                    Color.blue.opacity(0.08),
                    Color.purple.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(colorScheme == .dark ? 0 : 1)

            LiquidMetalBackgroundView(showFluidWaves: true)
                .opacity(colorScheme == .dark ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.35), value: colorScheme)
    }

    private var platformBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }
}

func validURL(_ string: String) -> URL? {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
        return nil
    }

    if let url = URL(string: trimmed), url.scheme != nil {
        return url
    }

    return URL(string: "https://\(trimmed)")
}

extension View {
    @ViewBuilder
    func urlInputStyle() -> some View {
        #if os(iOS)
        self
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        #else
        self
            .autocorrectionDisabled()
        #endif
    }

    @ViewBuilder
    func emailInputStyle() -> some View {
        #if os(iOS)
        self
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        #else
        self
            .autocorrectionDisabled()
        #endif
    }

    @ViewBuilder
    func decimalInputStyle() -> some View {
        #if os(iOS)
        self
            .keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    @ViewBuilder
    func inlineNavigationBarTitle() -> some View {
        #if os(iOS)
        self
            .navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
