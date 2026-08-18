import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: PortfolioStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    statsGrid
                    progressSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.16), Color.purple.opacity(0.08), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Dashboard")
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(.blue.gradient)

            VStack(alignment: .leading, spacing: 5) {
                Text("Welcome, \(store.student.name.components(separatedBy: " ").first ?? "Student")")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Track academics, projects, certificates, and achievements.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var statsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 14
        ) {
            StatCardView(title: "CGPA", value: String(format: "%.1f", store.cgpa), icon: "chart.line.uptrend.xyaxis", tint: .blue)
            StatCardView(title: "Projects", value: "\(store.projects.count)", icon: "folder.fill", tint: .purple)
            StatCardView(title: "Certificates", value: "\(store.certificates.count)", icon: "doc.text.fill", tint: .green)
            StatCardView(title: "Achievements", value: "\(store.achievements.count)", icon: "trophy.fill", tint: .orange)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Academic Progress")
                .font(.title2)
                .fontWeight(.semibold)

            ForEach(store.semesters) { semester in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Semester \(semester.number)")
                            .font(.headline)
                        Text("\(semester.subjects.count) subjects")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.1f", semester.sgpa))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

#Preview {
    DashboardView()
}

