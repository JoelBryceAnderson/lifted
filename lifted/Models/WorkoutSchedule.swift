import Foundation

struct WorkoutSchedule: Codable, Identifiable {
    let id: String
    let userId: String
    let cycleDurationDays: Int
    let days: [ScheduledDay]
    let createdAt: Date
    var isActive: Bool

    init(
        id: String = UUID().uuidString,
        userId: String,
        cycleDurationDays: Int = 7,
        days: [ScheduledDay] = [],
        createdAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.userId = userId
        self.cycleDurationDays = cycleDurationDays
        self.days = days
        self.createdAt = createdAt
        self.isActive = isActive
    }

    var workoutDaysCount: Int {
        days.filter { day in
            if case .workout = day.dayType { return true }
            return false
        }.count
    }

    var restDaysCount: Int {
        days.filter { day in
            if case .rest = day.dayType { return true }
            return false
        }.count
    }

    func dayType(for dayIndex: Int) -> ScheduledDayType? {
        days.first { $0.dayIndex == dayIndex }?.dayType
    }

    func workoutType(for dayIndex: Int) -> WorkoutType? {
        guard let dayType = dayType(for: dayIndex),
              case .workout(let type) = dayType else {
            return nil
        }
        return type
    }
}

struct ScheduledDay: Codable, Identifiable {
    var id: String { "\(dayIndex)" }
    let dayIndex: Int
    let dayType: ScheduledDayType

    init(dayIndex: Int, dayType: ScheduledDayType) {
        self.dayIndex = dayIndex
        self.dayType = dayType
    }

    var dayName: String {
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return weekdays[dayIndex % 7]
    }

    var shortDayName: String {
        let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return weekdays[dayIndex % 7]
    }
}

enum ScheduledDayType: Codable, Equatable {
    case workout(WorkoutType)
    case rest

    var displayName: String {
        switch self {
        case .workout(let type): return type.displayName
        case .rest: return "Rest"
        }
    }

    var isRest: Bool {
        if case .rest = self { return true }
        return false
    }

    var workoutType: WorkoutType? {
        if case .workout(let type) = self { return type }
        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case workoutType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        if type == "rest" {
            self = .rest
        } else if type == "workout" {
            let workoutType = try container.decode(WorkoutType.self, forKey: .workoutType)
            self = .workout(workoutType)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown day type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .rest:
            try container.encode("rest", forKey: .type)
        case .workout(let workoutType):
            try container.encode("workout", forKey: .type)
            try container.encode(workoutType, forKey: .workoutType)
        }
    }
}

extension WorkoutSchedule {
    static func defaultPPL(userId: String) -> WorkoutSchedule {
        WorkoutSchedule(
            userId: userId,
            cycleDurationDays: 7,
            days: [
                ScheduledDay(dayIndex: 0, dayType: .rest),
                ScheduledDay(dayIndex: 1, dayType: .workout(.push)),
                ScheduledDay(dayIndex: 2, dayType: .workout(.pull)),
                ScheduledDay(dayIndex: 3, dayType: .workout(.legs)),
                ScheduledDay(dayIndex: 4, dayType: .workout(.push)),
                ScheduledDay(dayIndex: 5, dayType: .workout(.pull)),
                ScheduledDay(dayIndex: 6, dayType: .workout(.legs))
            ]
        )
    }

    static func defaultUpperLower(userId: String) -> WorkoutSchedule {
        WorkoutSchedule(
            userId: userId,
            cycleDurationDays: 7,
            days: [
                ScheduledDay(dayIndex: 0, dayType: .rest),
                ScheduledDay(dayIndex: 1, dayType: .workout(.upper)),
                ScheduledDay(dayIndex: 2, dayType: .workout(.lower)),
                ScheduledDay(dayIndex: 3, dayType: .rest),
                ScheduledDay(dayIndex: 4, dayType: .workout(.upper)),
                ScheduledDay(dayIndex: 5, dayType: .workout(.lower)),
                ScheduledDay(dayIndex: 6, dayType: .rest)
            ]
        )
    }

    static func defaultFullBody(userId: String) -> WorkoutSchedule {
        WorkoutSchedule(
            userId: userId,
            cycleDurationDays: 7,
            days: [
                ScheduledDay(dayIndex: 0, dayType: .rest),
                ScheduledDay(dayIndex: 1, dayType: .workout(.fullBody)),
                ScheduledDay(dayIndex: 2, dayType: .rest),
                ScheduledDay(dayIndex: 3, dayType: .workout(.fullBody)),
                ScheduledDay(dayIndex: 4, dayType: .rest),
                ScheduledDay(dayIndex: 5, dayType: .workout(.fullBody)),
                ScheduledDay(dayIndex: 6, dayType: .rest)
            ]
        )
    }
}
