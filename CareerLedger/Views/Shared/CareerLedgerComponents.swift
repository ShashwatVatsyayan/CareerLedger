import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 6)
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
    let status: VerificationStatus

    var body: some View {
        Label(status.displayName.uppercased(), systemImage: icon)
            .font(.caption2)
            .fontWeight(.heavy)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.14))
            .foregroundStyle(tint)
            .clipShape(Capsule())
            .animation(.spring(response: 0.3, dampingFraction: 0.78), value: status)
    }

    private var icon: String {
        switch status {
        case .selfReported:
            return "circle"
        case .evidenceProvided:
            return "checkmark.circle.fill"
        case .sourceVerified:
            return "link.badge.plus"
        case .issuerVerified:
            return "checkmark.seal.fill"
        }
    }

    private var tint: Color {
        switch status {
        case .selfReported:
            return .secondary
        case .evidenceProvided:
            return .blue
        case .sourceVerified:
            return .purple
        case .issuerVerified:
            return .green
        }
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
                .padding()
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        }
        .background(AppBackground())
    }
}

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.08, green: 0.09, blue: 0.14),
                    Color(red: 0.06, green: 0.07, blue: 0.12),
                    Color(red: 0.04, green: 0.05, blue: 0.09)
                ]
                : [
                    platformBackground,
                    Color.blue.opacity(0.08),
                    Color.purple.opacity(0.05)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
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
