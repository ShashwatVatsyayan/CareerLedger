import SwiftUI

struct SemesterDetailView: View {
    let semester: Semester

    var body: some View {
        List {
            Section("Semester Information") {
                HStack {
                    Text("SGPA")
                    Spacer()
                    Text(String(format: "%.1f", semester.sgpa))
                        .fontWeight(.bold)
                }
            }

            Section("Subjects") {
                if semester.subjects.isEmpty {
                    Text("No subjects recorded.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(semester.subjects) { subject in
                        HStack {
                            Text(subject.name)
                            Spacer()
                            Text(subject.grade)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Semester \(semester.semesterNumber)")
    }
}

#Preview {
    let semester = Semester(semesterNumber: 1, sgpa: 8.2, subjects: [
        Subject(name: "Programming", grade: "A")
    ])

    NavigationStack {
        SemesterDetailView(semester: semester)
    }
}
