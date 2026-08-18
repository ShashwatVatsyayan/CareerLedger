import Foundation

struct Achievement: Identifiable {
    let id = UUID()
    var title: String
    var organization: String
    var date: Date
    var category: String
    var description: String
}

let sampleAchievements = [
    Achievement(
        title: "Hackathon Participant",
        organization: "Chandigarh University",
        date: Date(),
        category: "Technical",
        description: "Participated in a university hackathon."
    ),
    Achievement(
        title: "Club Leadership",
        organization: "University Club",
        date: Date(),
        category: "Leadership",
        description: "Contributed to student club activities."
    )
]
