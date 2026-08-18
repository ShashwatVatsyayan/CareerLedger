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
        .navigationTitle("Semester \(semester.number)")
    }
}

#Preview {
    NavigationStack {
        SemesterDetailView(semester: sampleSemesters[0])
    }
}
