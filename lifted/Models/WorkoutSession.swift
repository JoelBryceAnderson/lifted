import Foundation

struct WorkoutSession: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let workoutType: WorkoutType
    let scheduledDate: Date
    let cycleDay: Int
    var startedAt: Date?
    var completedAt: Date?
    var status: SessionStatus
    var exercises: [ExerciseLog]
    var notes: String?

    init(
        id: String = UUID().uuidString,
        userId: String,
        workoutType: WorkoutType,
        scheduledDate: Date,
        cycleDay: Int,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        status: SessionStatus = .scheduled,
        exercises: [ExerciseLog] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.workoutType = workoutType
        self.scheduledDate = scheduledDate
        self.cycleDay = cycleDay
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.status = status
        self.exercises = exercises
        self.notes = notes
    }

    var duration: TimeInterval? {
        guard let start = startedAt, let end = completedAt else { return nil }
        return end.timeIntervalSince(start)
    }

    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes)m"
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.filter { !$0.isWarmup }.count }
    }

    var completedSets: Int {
        exercises.reduce(0) { $0 + $1.sets.filter { !$0.isWarmup && $0.completedAt != nil }.count }
    }

    var totalVolume: Double {
        exercises.reduce(0) { total, log in
            total + log.sets.reduce(0) { setTotal, set in
                guard let weight = set.actualWeight, let reps = set.actualReps, !set.isWarmup else {
                    return setTotal
                }
                return setTotal + (weight * Double(reps))
            }
        }
    }
}

struct ExerciseLog: Codable, Identifiable, Equatable {
    let id: String
    let exerciseId: String
    var sets: [ExerciseSet]
    var notes: String?

    init(
        id: String = UUID().uuidString,
        exerciseId: String,
        sets: [ExerciseSet] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.sets = sets
        self.notes = notes
    }

    var completedSets: Int {
        sets.filter { !$0.isWarmup && $0.completedAt != nil }.count
    }

    var workingSets: Int {
        sets.filter { !$0.isWarmup }.count
    }

    var totalVolume: Double {
        sets.reduce(0) { total, set in
            guard let weight = set.actualWeight, let reps = set.actualReps, !set.isWarmup else {
                return total
            }
            return total + (weight * Double(reps))
        }
    }
}

struct ExerciseSet: Codable, Identifiable, Equatable {
    let id: String
    var targetReps: Int
    var actualReps: Int?
    var targetWeight: Double
    var actualWeight: Double?
    var rpe: Int?
    var isWarmup: Bool
    var completedAt: Date?

    init(
        id: String = UUID().uuidString,
        targetReps: Int,
        actualReps: Int? = nil,
        targetWeight: Double,
        actualWeight: Double? = nil,
        rpe: Int? = nil,
        isWarmup: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.targetReps = targetReps
        self.actualReps = actualReps
        self.targetWeight = targetWeight
        self.actualWeight = actualWeight
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.completedAt = completedAt
    }

    var isCompleted: Bool {
        completedAt != nil
    }

    var volume: Double? {
        guard let weight = actualWeight, let reps = actualReps else { return nil }
        return weight * Double(reps)
    }

    var hitTarget: Bool {
        guard let actualReps = actualReps, let actualWeight = actualWeight else { return false }
        return actualReps >= targetReps && actualWeight >= targetWeight
    }
}

enum SessionStatus: String, Codable, CaseIterable {
    case scheduled
    case inProgress
    case completed
    case missed
    case rescheduled

    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .missed: return "Missed"
        case .rescheduled: return "Rescheduled"
        }
    }

    var iconName: String {
        switch self {
        case .scheduled: return "calendar"
        case .inProgress: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .missed: return "xmark.circle.fill"
        case .rescheduled: return "arrow.triangle.2.circlepath"
        }
    }
}
