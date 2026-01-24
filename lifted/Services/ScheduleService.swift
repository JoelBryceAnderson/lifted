import Foundation

actor ScheduleService {
    static let shared = ScheduleService()

    private let firestoreService = FirestoreService.shared

    private init() {}

    // MARK: - Schedule Generation

    func generateUpcomingSessions(
        userId: String,
        schedule: WorkoutSchedule,
        startDate: Date,
        numberOfDays: Int = 14
    ) async throws -> [WorkoutSession] {
        let calendar = Calendar.current
        var sessions: [WorkoutSession] = []

        for dayOffset in 0..<numberOfDays {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }

            let dayIndex = dayOffset % schedule.cycleDurationDays
            guard let scheduledDay = schedule.days.first(where: { $0.dayIndex == dayIndex }),
                  case .workout(let workoutType) = scheduledDay.dayType else {
                continue
            }

            let session = WorkoutSession(
                userId: userId,
                workoutType: workoutType,
                scheduledDate: calendar.startOfDay(for: date),
                cycleDay: dayIndex,
                status: .scheduled
            )
            sessions.append(session)
        }

        return sessions
    }

    func getTodaySession(userId: String, schedule: WorkoutSchedule) async throws -> WorkoutSession? {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let sessions: [WorkoutSession] = try await firestoreService.getWorkoutSessions(
            userId: userId,
            startDate: today,
            endDate: tomorrow
        )

        if let existing = sessions.first(where: { $0.status != .missed && $0.status != .rescheduled }) {
            return existing
        }

        let daysSinceScheduleStart = Calendar.current.dateComponents([.day], from: schedule.createdAt, to: today).day ?? 0
        let cycleDay = daysSinceScheduleStart % schedule.cycleDurationDays

        guard let scheduledDay = schedule.days.first(where: { $0.dayIndex == cycleDay }),
              case .workout(let workoutType) = scheduledDay.dayType else {
            return nil
        }

        return WorkoutSession(
            userId: userId,
            workoutType: workoutType,
            scheduledDate: today,
            cycleDay: cycleDay,
            status: .scheduled
        )
    }
    
    func getSessionForDate(_ date: Date, userId: String, schedule: WorkoutSchedule) async throws -> WorkoutSession? {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: targetDate)!

        // Try to find an existing session for this date
        let sessions: [WorkoutSession] = try await firestoreService.getWorkoutSessions(
            userId: userId,
            startDate: targetDate,
            endDate: nextDay
        )

        if let existing = sessions.first(where: { $0.status != .missed && $0.status != .rescheduled }) {
            return existing
        }

        // Generate a preview session based on the schedule
        let daysSinceScheduleStart = calendar.dateComponents([.day], from: schedule.createdAt, to: targetDate).day ?? 0
        let cycleDay = daysSinceScheduleStart % schedule.cycleDurationDays

        guard let scheduledDay = schedule.days.first(where: { $0.dayIndex == cycleDay }),
              case .workout(let workoutType) = scheduledDay.dayType else {
            return nil
        }

        return WorkoutSession(
            userId: userId,
            workoutType: workoutType,
            scheduledDate: targetDate,
            cycleDay: cycleDay,
            status: .scheduled
        )
    }

    // MARK: - Missed Day Handling

    func handleMissedDay(session: WorkoutSession, schedule: WorkoutSchedule) async throws -> [WorkoutSession] {
        var updatedSession = session
        updatedSession.status = .missed

        try await firestoreService.updateInSubcollection(
            updatedSession,
            parentCollection: .users,
            parentId: session.userId,
            subcollection: .workoutSessions,
            documentId: session.id
        )

        return try await rescheduleRemainingDays(
            userId: session.userId,
            missedDate: session.scheduledDate,
            schedule: schedule
        )
    }

    private func rescheduleRemainingDays(
        userId: String,
        missedDate: Date,
        schedule: WorkoutSchedule
    ) async throws -> [WorkoutSession] {
        let calendar = Calendar.current
        let cycleEndDate = calendar.date(byAdding: .day, value: schedule.cycleDurationDays, to: missedDate)!

        let remainingSessions: [WorkoutSession] = try await firestoreService.getWorkoutSessions(
            userId: userId,
            startDate: calendar.date(byAdding: .day, value: 1, to: missedDate)!,
            endDate: cycleEndDate
        )

        let scheduledSessions = remainingSessions.filter { $0.status == .scheduled }

        var rescheduledSessions: [WorkoutSession] = []
        var currentDate = missedDate

        for var session in scheduledSessions {
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!

            while isRestDay(date: currentDate, schedule: schedule) {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }

            session.status = .rescheduled
            try await firestoreService.updateInSubcollection(
                session,
                parentCollection: .users,
                parentId: userId,
                subcollection: .workoutSessions,
                documentId: session.id
            )

            let newSession = WorkoutSession(
                userId: userId,
                workoutType: session.workoutType,
                scheduledDate: currentDate,
                cycleDay: session.cycleDay,
                status: .scheduled
            )

            let _ = try await firestoreService.createInSubcollection(
                newSession,
                parentCollection: .users,
                parentId: userId,
                subcollection: .workoutSessions,
                documentId: newSession.id
            )

            rescheduledSessions.append(newSession)
        }

        return rescheduledSessions
    }

    private func isRestDay(date: Date, schedule: WorkoutSchedule) -> Bool {
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: schedule.createdAt, to: date).day ?? 0
        let cycleDay = daysSinceStart % schedule.cycleDurationDays

        guard let dayType = schedule.dayType(for: cycleDay) else { return true }
        return dayType.isRest
    }

    // MARK: - Week View

    func getWeekSessions(userId: String, weekStartDate: Date) async throws -> [WorkoutSession] {
        let calendar = Calendar.current
        let weekEndDate = calendar.date(byAdding: .day, value: 7, to: weekStartDate)!

        return try await firestoreService.getWorkoutSessions(
            userId: userId,
            startDate: weekStartDate,
            endDate: weekEndDate
        )
    }

    func getCurrentWeekStartDate() -> Date {
        let calendar = Calendar.current
        let today = Date()
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
    }

    // MARK: - Cycle Information

    nonisolated func getCurrentCycleDay(schedule: WorkoutSchedule) -> Int {
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: schedule.createdAt, to: Date()).day ?? 0
        return daysSinceStart % schedule.cycleDurationDays
    }
    
    nonisolated func getCycleDay(for date: Date, schedule: WorkoutSchedule) -> Int {
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: schedule.createdAt, to: date).day ?? 0
        return daysSinceStart % schedule.cycleDurationDays
    }

    func getNextWorkoutDate(schedule: WorkoutSchedule, from date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        var currentDate = date

        for _ in 0..<schedule.cycleDurationDays {
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            if !isRestDay(date: currentDate, schedule: schedule) {
                return currentDate
            }
        }

        return nil
    }
    
    // MARK: - On-the-Fly Schedule Changes
    
    /// Intelligently reschedules the rest of the week after a workout type change
    func rescheduleWeekAfterChange(
        userId: String,
        changedDate: Date,
        newWorkoutType: WorkoutType,
        schedule: WorkoutSchedule
    ) async throws {
        let calendar = Calendar.current
        
        // Get all scheduled sessions for the rest of the week
        let weekEndDate = calendar.date(byAdding: .day, value: 7, to: changedDate)!
        let futureSessions: [WorkoutSession] = try await firestoreService.getWorkoutSessions(
            userId: userId,
            startDate: calendar.date(byAdding: .day, value: 1, to: changedDate)!,
            endDate: weekEndDate
        )
        
        let scheduledSessions = futureSessions.filter { $0.status == .scheduled }
        
        guard !scheduledSessions.isEmpty else { return }
        
        // Build the expected workout sequence from the schedule
        let cycleDayOfChange = getCycleDay(for: changedDate, schedule: schedule)
        var expectedSequence: [WorkoutType] = []
        
        // Start from the day after the change
        for dayOffset in 1..<8 {
            let cycleDay = (cycleDayOfChange + dayOffset) % schedule.cycleDurationDays
            if let dayType = schedule.dayType(for: cycleDay),
               case .workout(let workoutType) = dayType {
                expectedSequence.append(workoutType)
            }
        }
        
        // Check if the change disrupted the natural flow
        // If the new workout type matches what should have been the next workout, we're good
        // Otherwise, we need to adjust
        
        var workoutsToSchedule: [WorkoutType] = []
        
        // Collect the original workout types that were scheduled
        for session in scheduledSessions {
            if let dayType = schedule.dayType(for: session.cycleDay),
               case .workout(let originalType) = dayType {
                // Skip the workout type that was just changed to (to avoid duplicates)
                if originalType != newWorkoutType {
                    workoutsToSchedule.append(originalType)
                }
            }
        }
        
        // If the user is following a PPL or similar split, maintain the order
        // by ensuring we don't duplicate the workout they just changed to
        if !workoutsToSchedule.isEmpty {
            // Mark old sessions as rescheduled
            for var session in scheduledSessions {
                session.status = .rescheduled
                try await firestoreService.updateInSubcollection(
                    session,
                    parentCollection: .users,
                    parentId: userId,
                    subcollection: .workoutSessions,
                    documentId: session.id
                )
            }
            
            // Create new sessions with adjusted workout types
            var currentDate = changedDate
            var workoutIndex = 0
            
            while workoutIndex < workoutsToSchedule.count {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                
                // Skip rest days
                if isRestDay(date: currentDate, schedule: schedule) {
                    continue
                }
                
                let cycleDay = getCycleDay(for: currentDate, schedule: schedule)
                let workoutType = workoutsToSchedule[workoutIndex]
                
                let newSession = WorkoutSession(
                    userId: userId,
                    workoutType: workoutType,
                    scheduledDate: currentDate,
                    cycleDay: cycleDay,
                    status: .scheduled
                )
                
                let _ = try await firestoreService.createInSubcollection(
                    newSession,
                    parentCollection: .users,
                    parentId: userId,
                    subcollection: .workoutSessions,
                    documentId: newSession.id
                )
                
                workoutIndex += 1
            }
        }
    }
}
