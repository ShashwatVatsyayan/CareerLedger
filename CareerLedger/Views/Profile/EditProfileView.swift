import SwiftData
import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name: String
    @State private var university: String
    @State private var course: String
    @State private var email: String
    @State private var bio: String
    @State private var githubURL: String
    @State private var linkedinURL: String
    @State private var skillsText: String

    private let student: Student

    init(student: Student) {
        self.student = student
        _name = State(initialValue: student.name)
        _university = State(initialValue: student.university)
        _course = State(initialValue: student.course)
        _email = State(initialValue: student.email)
        _bio = State(initialValue: student.bio)
        _githubURL = State(initialValue: student.githubURL)
        _linkedinURL = State(initialValue: student.linkedinURL)
        _skillsText = State(initialValue: student.skillsText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Name", text: $name)
                    TextField("University", text: $university)
                    TextField("Course", text: $course)
                    TextField("Email", text: $email)
                        .emailInputStyle()
                }

                Section("About") {
                    TextEditor(text: $bio)
                        .frame(minHeight: 120)
                }

                Section("Professional Links") {
                    TextField("GitHub URL", text: $githubURL)
                        .urlInputStyle()
                    TextField("LinkedIn URL", text: $linkedinURL)
                        .urlInputStyle()
                }

                Section("Skills") {
                    TextField("Comma separated skills", text: $skillsText)
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
                        save()
                    }
                }
            }
        }
    }

    private func save() {
        student.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        student.university = university.trimmingCharacters(in: .whitespacesAndNewlines)
        student.course = course.trimmingCharacters(in: .whitespacesAndNewlines)
        student.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        student.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        student.githubURL = githubURL.trimmingCharacters(in: .whitespacesAndNewlines)
        student.linkedinURL = linkedinURL.trimmingCharacters(in: .whitespacesAndNewlines)
        student.skillsText = skillsText.trimmingCharacters(in: .whitespacesAndNewlines)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    EditProfileView(student: Student(name: "Shashwat", course: "Computer Science", university: "Chandigarh University", email: "student@example.com", bio: "Student"))
}
