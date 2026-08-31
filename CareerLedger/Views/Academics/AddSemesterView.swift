import SwiftData
import SwiftUI

struct AddSemesterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var semesterNumber: Int
    @State private var sgpa: String
    @State private var subjectName = ""
    @State private var subjectGrade = "A"
    @State private var subjects: [SubjectDraft]
    @State private var errorMessage: String?

    private let semester: Semester?
    private let title: String

    init(semester: Semester? = nil) {
        self.semester = semester
        _semesterNumber = State(initialValue: semester?.semesterNumber ?? 1)
        _sgpa = State(initialValue: semester.map { String(format: "%.1f", $0.sgpa) } ?? "")
        _subjects = State(initialValue: semester?.subjects.map { SubjectDraft(name: $0.name, grade: $0.grade) } ?? [])
        title = semester == nil ? "Add Semester" : "Edit Semester"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Semester") {
                    Stepper("Semester: \(semesterNumber)", value: $semesterNumber, in: 1...12)
                    TextField("SGPA", text: $sgpa)
                        .decimalInputStyle()
                }

                Section("Add Subject") {
                    TextField("Subject name", text: $subjectName)
                    Picker("Grade", selection: $subjectGrade) {
                        ForEach(["A+", "A", "B+", "B", "C", "D", "F"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    Button("Add Subject") {
                        addSubject()
                    }
                }

                Section("Subjects Added") {
                    if subjects.isEmpty {
                        Text("No subjects added yet.")
                            .foregroundStyle(.secondary)
                    } else {
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

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
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
                    Button("Save Semester") {
                        saveSemester()
                    }
                }
            }
        }
    }

    private func addSubject() {
        let trimmedName = subjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            subjects.append(SubjectDraft(name: trimmedName, grade: subjectGrade))
        }
        subjectName = ""
    }

    private func saveSemester() {
        guard let value = Double(sgpa), value >= 0, value <= 10 else {
            errorMessage = "Enter a valid SGPA between 0 and 10."
            return
        }

        if let semester {
            semester.semesterNumber = semesterNumber
            semester.sgpa = value
            semester.subjects.forEach(modelContext.delete)
            semester.subjects = subjects.map { Subject(name: $0.name, grade: $0.grade) }
        } else {
            modelContext.insert(Semester(
                semesterNumber: semesterNumber,
                sgpa: value,
                subjects: subjects.map { Subject(name: $0.name, grade: $0.grade) }
            ))
        }

        try? modelContext.save()
        dismiss()
    }
}

private struct SubjectDraft: Identifiable {
    let id = UUID()
    var name: String
    var grade: String
}

#Preview {
    AddSemesterView()
        .modelContainer(for: [Semester.self, Subject.self], inMemory: true)
}
