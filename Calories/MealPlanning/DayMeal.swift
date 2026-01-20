import Foundation

public struct DayMeal: Hashable {
    let mealType: MealType
    let date: Date

    static func < (lhs: DayMeal, rhs: DayMeal) -> Bool {
        if lhs.date != rhs.date {
            return lhs.date < rhs.date
        }
        return lhs.mealType.sortOrder < rhs.mealType.sortOrder
    }

    var keyString: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]  // Just date, no time: "2026-03-05"
        let dateString = formatter.string(from: date).replacingOccurrences(of: "-", with: "/")
        return "\(dateString)-\(mealType.rawValue)"
    }
}
