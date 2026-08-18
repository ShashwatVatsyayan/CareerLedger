import Foundation

struct Student: Identifiable {
    let id = UUID()
    var name: String
    var university: String
    var course: String
    var email: String
    var bio: String
    var skills: [String]
    var universityURL: String
    var instagramURL: String
    var linkedInURL: String
    var githubURL: String
    var portfolioURL: String
}

let sampleStudent = Student(
    name: "Shashwat Vatsyayan",
    university: "Chandigarh University",
    course: "B.E. Computer Science",
    email: "student@example.com",
    bio: "Computer Science student interested in software development and technology.",
    skills: ["Swift", "C++", "Python", "JavaScript"],
    universityURL: "https://www.cuchd.in/",
    instagramURL: "https://www.instagram.com/",
    linkedInURL: "https://www.linkedin.com/",
    githubURL: "https://github.com/",
    portfolioURL: "https://careerledger.example.com/shashwat-vatsyayan"
)
