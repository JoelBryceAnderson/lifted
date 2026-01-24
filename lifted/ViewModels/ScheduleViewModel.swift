import Foundation
import Combine

@MainActor
class ScheduleViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var schedule: WorkoutSchedule?
    @Published var todaySession: WorkoutSession?
    @Published var weekSessions: [WorkoutSession] = []
    @Published var upcomingSessions: [WorkoutSession] = []
    @Published var isLoading = false
    @Published var error: String?

    // Week Navigation
    @Published var currentWeekStart: Date = Date().startOfWeek
    
    // Day Selection
    @Published var selectedDate: Date = Date()

    // MARK: - Dependencies

    private let firestoreService = FirestoreService.shared
    private let scheduleService = ScheduleService.shared

    // MARK: - Computed Properties

    var todayWorkoutType: WorkoutType? {
        todaySession?.workoutType
    }

    var isRestDay: Bool {
        guard let schedule = schedule else { return true }
        let cycleDay = scheduleService.getCurrentCycleDay(schedule: schedule)
        return schedule.dayType(for: cycleDay)?.isRest ?? true
    }

    var currentCycleDay: Int {
        guard let schedule = schedule else { return 0 }
        return scheduleService.getCurrentCycleDay(schedule: schedule)
    }

    var weekDays: [WeekDay] {
        let calendar = Calendar.current
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: currentWeekStart) ?? currentWeekStart
            let session = weekSessions.first { calendar.isDate($0.scheduledDate, inSameDayAs: date) }
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
            return WeekDay(date: date, session: session, isSelected: isSelected)
        }
    }
    
    var selectedDaySession: WorkoutSession? {
        let calendar = Calendar.current
        return weekSessions.first { calendar.isDate($0.scheduledDate, inSameDayAs: selectedDate) }
    }
    
    var isSelectedDayRestDay: Bool {
        guard let schedule = schedule else { return true }
        let cycleDay = scheduleService.getCycleDay(for: selectedDate, schedule: schedule)
        return schedule.dayType(for: cycleDay)?.isRest ?? true
    }
    
    var selectedDayWorkoutType: WorkoutType? {
        guard let schedule = schedule else { return nil }
        let cycleDay = scheduleService.getCycleDay(for: selectedDate, schedule: schedule)
        guard let scheduledDay = schedule.days.first(where: { $0.dayIndex == cycleDay }),
              case .workout(let workoutType) = scheduledDay.dayType else {
            return nil
        }
        return workoutType
    }

    // MARK: - Data Loading

    func loadSchedule(userId: String) async {
        isLoading = true

        do {
            schedule = try await firestoreService.getActiveSchedule(userId: userId)

            if let schedule = schedule {
                todaySession = try await scheduleService.getTodaySession(userId: userId, schedule: schedule)
                weekSessions = try await scheduleService.getWeekSessions(userId: userId, weekStartDate: currentWeekStart)

                let upcoming = try await scheduleService.generateUpcomingSessions(
                    userId: userId,
                    schedule: schedule,
                    startDate: Date()
                )
                upcomingSessions = upcoming
            }

        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func refreshTodaySession(userId: String) async {
        guard let schedule = schedule else { return }

        do {
            todaySession = try await scheduleService.getTodaySession(userId: userId, schedule: schedule)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Week Navigation

    func goToNextWeek() {
        currentWeekStart = currentWeekStart.adding(weeks: 1)
    }

    func goToPreviousWeek() {
        currentWeekStart = currentWeekStart.adding(weeks: -1)
    }

    func goToCurrentWeek() {
        currentWeekStart = Date().startOfWeek
        selectedDate = Date()
    }
    
    // MARK: - Day Selection
    
    func selectDate(_ date: Date) {
        selectedDate = date
    }

    func loadWeekSessions(userId: String) async {
        do {
            weekSessions = try await scheduleService.getWeekSessions(userId: userId, weekStartDate: currentWeekStart)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Missed Day Handling

    func markDayAsMissed(userId: String) async {
        guard let session = todaySession, let schedule = schedule else { return }

        isLoading = true

        do {
            let rescheduled = try await scheduleService.handleMissedDay(session: session, schedule: schedule)
            upcomingSessions = rescheduled

            // Refresh today's session
            todaySession = nil

        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Schedule Updates

    func updateSchedule(userId: String, newSchedule: WorkoutSchedule) async {
        isLoading = true

        do {
            // Deactivate old schedule
            if var oldSchedule = schedule {
                oldSchedule.isActive = false
                try await firestoreService.updateInSubcollection(
                    oldSchedule,
                    parentCollection: .users,
                    parentId: userId,
                    subcollection: .schedules,
                    documentId: oldSchedule.id
                )
            }

            // Save new schedule
            let _ = try await firestoreService.createInSubcollection(
                newSchedule,
                parentCollection: .users,
                parentId: userId,
                subcollection: .schedules,
                documentId: newSchedule.id
            )

            schedule = newSchedule
            await loadSchedule(userId: userId)

        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Week Day Model

struct WeekDay: Identifiable {
    let date: Date
    let session: WorkoutSession?
    let isSelected: Bool

    var id: Date { date }

    var isToday: Bool { date.isToday }

    var isPast: Bool { date < Date().startOfDay }

    var workoutType: WorkoutType? {
        session?.workoutType
    }

    var status: SessionStatus? {
        session?.status
    }
}
