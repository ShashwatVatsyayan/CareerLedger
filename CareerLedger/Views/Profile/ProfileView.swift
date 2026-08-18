import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct ProfileView: View {
    @State private var student = sampleStudent
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingPublicPortfolio = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 86))
                            .foregroundStyle(.blue.gradient)
                            .symbolEffect(.bounce, value: student.name)

                        VStack(spacing: 4) {
                            Text(student.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(student.course)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.regularMaterial)
                        .padding(.vertical, 4)
                )

                Section("About") {
                    Text(student.bio)
                }

                Section("Education") {
                    LabeledContent("University", value: student.university)
                    LabeledContent("Course", value: student.course)
                    LabeledContent("Email", value: student.email)
                }

                Section("Connect") {
                    HStack(spacing: 24) {
                        if let url = URL(string: student.universityURL) {
                            Link(destination: url) {
                                Image(systemName: "graduationcap")
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                        }
                        if let url = URL(string: student.instagramURL) {
                            Link(destination: url) {
                                Image(systemName: "camera")
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                        }
                        if let url = URL(string: student.linkedInURL) {
                            Link(destination: url) {
                                Image(systemName: "link")
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                        }
                        if let url = URL(string: student.githubURL) {
                            Link(destination: url) {
                                Image(systemName: "chevron.left.slash.chevron.right")
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Share Portfolio") {
                    let portfolioLink = "careerledger.app/portfolio/shashwat-vatsyayan"
                    VStack(alignment: .leading, spacing: 12) {
                        Text(portfolioLink)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Button("Copy Link") {
                            #if canImport(UIKit)
                            UIPasteboard.general.string = portfolioLink
                            #elseif canImport(AppKit)
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(portfolioLink, forType: .string)
                            #endif
                        }

                        Button("Preview Public Portfolio") {
                            showingPublicPortfolio = true
                        }
                        .sheet(isPresented: $showingPublicPortfolio) {
                            Text("Public Portfolio Placeholder")
                                .font(.title)
                                .padding()
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Skills") {
                    FlowLayout(items: student.skills)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.blue.opacity(0.06))
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                ToolbarItem {
                    Button("Edit") {
                        showingEditProfile = true
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(student: $student)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

private struct FlowLayout: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProfileView()
}
