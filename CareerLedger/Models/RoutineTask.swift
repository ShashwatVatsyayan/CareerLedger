import Foundation
import SwiftData

@Model
final class RoutineTask: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var category: String
    var timeString: String
    var isAllDay: Bool
    var scheduledDate: Date
    var iconName: String
    var iconBgHex: String
    var iconTintHex: String
    var isCompleted: Bool
    var notes: String
    var orderIndex: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        category: String = "Routine",
        timeString: String = "Time: All-Day",
        isAllDay: Bool = true,
        scheduledDate: Date = Date(),
        iconName: String = "basket.fill",
        iconBgHex: String = "#E0E7FF",
        iconTintHex: String = "#4F46E5",
        isCompleted: Bool = false,
        notes: String = "",
        orderIndex: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.timeString = timeString
        self.isAllDay = isAllDay
        self.scheduledDate = scheduledDate
        self.iconName = iconName
        self.iconBgHex = iconBgHex
        self.iconTintHex = iconTintHex
        self.isCompleted = isCompleted
        self.notes = notes
        self.orderIndex = orderIndex
        self.createdAt = createdAt
    }
}
