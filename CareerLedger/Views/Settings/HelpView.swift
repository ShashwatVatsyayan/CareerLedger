import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Section("Managing Data") {
                Label("Use the plus button to add a new item.", systemImage: "plus.circle.fill")
                Label("Use the pencil button to edit an item.", systemImage: "pencil.circle.fill")
                Label("Use the trash button or swipe left to remove an item.", systemImage: "trash.circle.fill")
            }

            Section("Academic Records") {
                Text("Open Academics to add, edit, or delete semester SGPA/CGPA and subject grades.")
                    .foregroundStyle(.secondary)
            }

            Section("Theme") {
                Text("Choose System, Light, or Dark mode from Settings. The app remembers your choice.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Help")
    }
}

#Preview {
    NavigationStack {
        HelpView()
    }
}
