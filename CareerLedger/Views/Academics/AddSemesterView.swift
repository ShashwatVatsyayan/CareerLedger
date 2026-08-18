import SwiftUI

struct AddSemesterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var semesterNumber: Int
    @State private var sgpa: String
    @State private var subjectName = ""
    @State private var subjectGrade = "A"
    @State private var subjects: [Subject]

    private let title: String
    let onSave: (Semester) -> Void

    init(semester: Semester? = nil, onSave: @escaping (Semester) -> Void) {
        _semesterNumber = State(initialValue: semester?.number ?? 3)
        _sgpa = State(initialValue: semester.map { String(format: "%.1f", $0.sgpa) } ?? "")
        _subjects = State(initialValue: semester?.subjects ?? [])
        title = semester == nil ? "Add Semester" : "Edit Semester"
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Semester") {
                    Stepper("Semester: \(semesterNumber)", value: $semesterNumber, in: 1...12)
                    TextField("SGPA / CGPA", text: $sgpa)
                }

                Section("Add Subject") {
                    TextField("Subject name", text: $subjectName)
                    Picker("Grade", selection: $subjectGrade) {
                        ForEach(["A+", "A", "B+", "B", "C", "D", "F"], id: \.self) {
                            Text($0)
                        }
                    }
                    Button("Add Subject") {
                        addSubject()
                    }
                }

                Section("Subjects Added") {
                    ForEach(subjects) { subject in
                        HStack {
                            Text(subject.name)
                            Spacer()
                            Text(subject.grade)
                                .fontWeight(.semibold)
                        }
                    }
                    .onDelete { indexSet in
                        subjects.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSemester()
                    }
                }
            }
        }
    }

    private func addSubject() {
        let trimmedName = subjectName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            return
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            subjects.append(
                Subject(
                    name: trimmedName,
                    grade: subjectGrade
                )
            )
        }
        subjectName = ""
    }

    private func saveSemester() {
        let value = Double(sgpa) ?? 0
        let semester = Semester(
            number: semesterNumber,
            sgpa: value,
            subjects: subjects
        )
        onSave(semester)
        dismiss()
    }
}

#Preview {
    AddSemesterView { _ in }
}
