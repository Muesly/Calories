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
        let dateString = date.formatted(date: .abbreviated, time: .omitted)
        return "\(dateString)-\(mealType.rawValue)"
    }
}
