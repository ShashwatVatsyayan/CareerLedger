import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    var tint: Color = .blue
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(tint.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                    .shadow(color: tint.opacity(0.35), radius: 6, x: 0, y: 3)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .opacity(isHovered ? 1 : 0)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    tint.opacity(isHovered ? 0.45 : 0.18),
                                    tint.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: tint.opacity(isHovered ? 0.22 : 0.08), radius: isHovered ? 14 : 8, x: 0, y: isHovered ? 6 : 3)
        #if os(macOS)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                isHovered = hovering
            }
        }
        #endif
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
}
