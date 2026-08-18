import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    var tint: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(tint.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Spacer()
            }

            Text(value)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: tint.opacity(0.16), radius: 10, x: 0, y: 6)
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
