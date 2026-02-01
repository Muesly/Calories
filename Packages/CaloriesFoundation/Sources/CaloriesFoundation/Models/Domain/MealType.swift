import Foundation

public enum MealType: String, CaseIterable, Equatable, Identifiable {
    case breakfast = "Breakfast"
    case morningSnack = "Morning Snack"
    case lunch = "Lunch"
    case afternoonSnack = "Afternoon Snack"
    case dinner = "Dinner"
    case eveningSnack = "Evening Snack"

    public var id: String { rawValue }

    public static func mealTypeForDate(_ date: Date) -> MealType {
        let dc = Calendar.current.dateComponents([.hour], from: date)
        let hour = dc.hour!

        switch hour {
        case rangeOfPeriod(.breakfast): return .breakfast
        case rangeOfPeriod(.morningSnack): return .morningSnack
        case rangeOfPeriod(.lunch): return .lunch
        case rangeOfPeriod(.afternoonSnack): return .afternoonSnack
        case rangeOfPeriod(.dinner): return .dinner
        default: return .eveningSnack
        }
    }

    public var defaultHour: Int {
        switch self {
        case .breakfast: 8
        case .morningSnack: 10
        case .lunch: 12
        case .afternoonSnack: 14
        case .dinner: 18
        case .eveningSnack: 20
        }
    }

    public static func rangeOfPeriod(_ type: MealType) -> Range<Int> {
        type.rangeOfPeriod()
    }

    public func rangeOfPeriod() -> Range<Int> {
        switch self {
        case .breakfast: return 0..<10
        case .morningSnack: return 10..<12
        case .lunch: return 12..<14
        case .afternoonSnack: return 14..<17
        case .dinner: return 17..<20
        default: return 20..<24
        }
    }

    public var iconName: String {
        switch self {
        case .breakfast: "🥣"
        case .morningSnack: "☕️"
        case .lunch: "🥗"
        case .afternoonSnack: "🥜"
        case .dinner: "🍲"
        case .eveningSnack: "🍺"
        }
    }

    public static func rangeOfPeriod(forDate date: Date) -> (Date, Date) {
        let mealType = MealType.mealTypeForDate(date)
        let range = mealType.rangeOfPeriod()
        var dc = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dc.hour = range.startIndex
        let startOfPeriod: Date = Calendar.current.date(from: dc)!
        dc.hour = range.endIndex
        let endOfPeriod: Date = Calendar.current.date(from: dc)!
        return (startOfPeriod, endOfPeriod)
    }

    var shortened: String {
        String(id.prefix(1))
    }

    public var sortOrder: Int {
        switch self {
        case .breakfast: return 0
        case .morningSnack: return 1
        case .lunch: return 2
        case .afternoonSnack: return 3
        case .dinner: return 4
        case .eveningSnack: return 5
        }
    }
}
