import SwiftUI

struct AcademicsView: View {
    @State private var semesters = sampleSemesters
    @State private var showingAddSemester = false
    @State private var editingSemester: Semester?

    var body: some View {
        NavigationStack {
            List {
                Section("Academic Performance") {
                    ForEach(semesters) { semester in
                        SemesterCardView(
                            semester: semester,
                            onEdit: { editingSemester = semester },
                            onDelete: { deleteSemester(semester) }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteSemester(semester)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                editingSemester = semester
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.blue.opacity(0.06))
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: semesters.count)
            .navigationTitle("Academics")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingAddSemester = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSemester) {
                AddSemesterView { newSemester in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        semesters.append(newSemester)
                    }
                }
            }
            .sheet(item: $editingSemester) { semester in
                AddSemesterView(semester: semester) { updatedSemester in
                    updateSemester(semester, with: updatedSemester)
                }
            }
        }
    }

    private func updateSemester(_ oldSemester: Semester, with updatedSemester: Semester) {
        guard let index = semesters.firstIndex(where: { $0.id == oldSemester.id }) else {
            return
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            semesters[index] = updatedSemester
        }
    }

    private func deleteSemester(_ semester: Semester) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            semesters.removeAll { $0.id == semester.id }
        }
    }
}

private struct SemesterCardView: View {
    let semester: Semester
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            NavigationLink {
                SemesterDetailView(semester: semester)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "graduationcap.fill")
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.blue.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

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
            }
            .buttonStyle(.plain)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderless)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderless)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    AcademicsView()
}
