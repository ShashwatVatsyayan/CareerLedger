import Foundation
import SwiftData

@Model
final class Student {
    @Attribute(.unique) var id: UUID
    var name: String
    var course: String
    var university: String
    var email: String
    var bio: String
    var githubURL: String
    var linkedinURL: String
    var universityURL: String
    var instagramURL: String
    var portfolioURL: String
    var skillsText: String
    var profileImageData: Data?
    var createdAt: Date

    var skills: [String] {
        get {
            skillsText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set {
            skillsText = newValue.joined(separator: ", ")
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        course: String,
        university: String,
        email: String,
        bio: String,
        githubURL: String = "",
        linkedinURL: String = "",
        universityURL: String = "",
        instagramURL: String = "",
        portfolioURL: String = "https://careerledger.example.com/shashwat-vatsyayan",
        skills: [String] = [],
        profileImageData: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.course = course
        self.university = university
        self.email = email
        self.bio = bio
        self.githubURL = githubURL
        self.linkedinURL = linkedinURL
        self.universityURL = universityURL
        self.instagramURL = instagramURL
        self.portfolioURL = portfolioURL
        self.skillsText = skills.joined(separator: ", ")
        self.profileImageData = profileImageData
        self.createdAt = createdAt
    }
}
