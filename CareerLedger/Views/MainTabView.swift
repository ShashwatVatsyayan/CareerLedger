import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            AcademicsView()
                .tabItem {
                    Label("Academics", systemImage: "graduationcap.fill")
                }

            AchievementsView()
                .tabItem {
                    Label("Achievements", systemImage: "trophy.fill")
                }

            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: "folder.fill")
                }

            CertificatesView()
                .tabItem {
                    Label("Certificates", systemImage: "doc.text.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
