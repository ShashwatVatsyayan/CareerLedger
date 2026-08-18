import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var student: Student

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Name", text: $student.name)
                    TextField("University", text: $student.university)
                    TextField("Course", text: $student.course)
                    TextField("Email", text: $student.email)
                }

                Section("About") {
                    TextEditor(text: $student.bio)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var student = sampleStudent
    EditProfileView(student: $student)
}
