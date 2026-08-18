import Foundation

struct Project: Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var technologies: String
    var githubURL: String
    var demoURL: String
}

let sampleProjects = [
    Project(
        name: "Aegis AI",
        description: "A project for detecting manipulated or deepfake media.",
        technologies: "Python, Machine Learning, Flask",
        githubURL: "https://github.com/",
        demoURL: ""
    ),
    Project(
        name: "Student Portfolio",
        description: "Digital student portfolio and academic achievement tracker.",
        technologies: "Swift, SwiftUI",
        githubURL: "https://github.com/",
        demoURL: ""
    )
]
