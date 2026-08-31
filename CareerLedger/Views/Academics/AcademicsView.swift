import SwiftData
import SwiftUI

struct AcademicsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Semester.semesterNumber) private var semesters: [Semester]
    @State private var showingAddSemester = false
    @State private var editingSemester: Semester?
    @State private var expandedSemesterIDs: Set<UUID> = []

    private var cgpa: Double {
        PortfolioMetrics.cgpa(from: semesters)
    }

    var body: some View {
        NavigationStack {
            AdaptivePage {
                LazyVStack(alignment: .leading, spacing: 18) {
                    SectionHeader(title: "Academics", subtitle: semesters.isEmpty ? "No academic records" : "Overall CGPA \(String(format: "%.2f", cgpa))")

                    if semesters.isEmpty {
                        PremiumEmptyState(
                            title: "No Academic Records",
                            message: "Add semester SGPA and subjects to build your academic timeline.",
                            systemImage: "graduationcap",
                            actionTitle: "Add Semester",
                            action: { showingAddSemester = true }
                        )
                    } else {
                        academicSummary
                        LazyVStack(spacing: 14) {
                            ForEach(semesters) { semester in
                                SemesterTimelineCard(
                                    semester: semester,
                                    isExpanded: expandedSemesterIDs.contains(semester.id),
                                    onToggle: { toggle(semester) },
                                    onEdit: { editingSemester = semester },
                                    onDelete: { deleteSemester(semester) }
                                )
                            }
                        }
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: semesters.count)
            .navigationTitle("Academics")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingAddSemester = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .keyboardShortcut("n", modifiers: [.command])
                }
            }
            .sheet(isPresented: $showingAddSemester) {
                AddSemesterView()
            }
            .sheet(item: $editingSemester) { semester in
                AddSemesterView(semester: semester)
            }
        }
    }

    private var academicSummary: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Overall CGPA")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", cgpa))
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.heavy)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(semesters.count)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Semesters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func toggle(_ semester: Semester) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            if expandedSemesterIDs.contains(semester.id) {
                expandedSemesterIDs.remove(semester.id)
            } else {
                expandedSemesterIDs.insert(semester.id)
            }
        }
    }

    private func deleteSemester(_ semester: Semester) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            modelContext.delete(semester)
            try? modelContext.save()
        }
    }
}

struct SemesterTimelineCard: View {
    let semester: Semester
    let isExpanded: Bool
    let onToggle: () -> Void
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "graduationcap.fill")
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.blue.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Semester \(semester.semesterNumber)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("\(semester.subjects.count) subjects")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(String(format: "%.1f", semester.sgpa))
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundStyle(.blue)

                    Menu {
                        Button("Edit", systemImage: "pencil") {
                            onEdit?()
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            onDelete?()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .frame(width: 32, height: 32)
                    }
                }

                Button(action: onToggle) {
                    Label(isExpanded ? "Hide Subjects" : "Show Subjects", systemImage: isExpanded ? "chevron.up" : "chevron.down")
                }
                .buttonStyle(.bordered)

                if isExpanded {
                    VStack(spacing: 8) {
                        ForEach(semester.subjects) { subject in
                            HStack {
                                Text(subject.name)
                                Spacer()
                                Text(subject.grade)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .padding(10)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
}

#Preview {
    AcademicsView()
        .modelContainer(for: [Semester.self, Subject.self], inMemory: true)
}
