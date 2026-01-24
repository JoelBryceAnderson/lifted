import SwiftUI

struct WeekCalendarStrip: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Week navigation
            HStack {
                Button {
                    scheduleViewModel.goToPreviousWeek()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.blue)
                }

                Spacer()

                Text(weekTitle)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Button {
                    scheduleViewModel.goToNextWeek()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            // Days
            HStack(spacing: 8) {
                ForEach(scheduleViewModel.weekDays) { day in
                    WeekDayCell(day: day)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private var weekTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: scheduleViewModel.currentWeekStart)
        let end = formatter.string(from: scheduleViewModel.currentWeekStart.adding(days: 6))
        return "\(start) - \(end)"
    }
}

struct WeekDayCell: View {
    let day: WeekDay

    var body: some View {
        VStack(spacing: 8) {
            // Day name
            Text(day.date.shortDayName)
                .font(.caption2.weight(.medium))
                .foregroundColor(day.isToday ? .blue : .secondary)

            // Day number
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)

                if let workoutType = day.workoutType {
                    WorkoutTypeBadge(workoutType, size: .small)
                } else {
                    Text(day.date.dayNumber)
                        .font(.subheadline.weight(day.isToday ? .bold : .regular))
                        .foregroundColor(textColor)
                }
            }

            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .opacity(day.session != nil ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
    }

    private var backgroundColor: Color {
        if day.isToday {
            return .blue.opacity(0.15)
        } else if day.workoutType != nil {
            return Color.workoutTypeColor(day.workoutType!).opacity(0.15)
        }
        return Color(.systemGray6)
    }

    private var textColor: Color {
        if day.isToday {
            return .blue
        } else if day.isPast {
            return .secondary
        }
        return .primary
    }

    private var statusColor: Color {
        guard let status = day.status else { return .clear }

        switch status {
        case .completed: return .green
        case .missed: return .red
        case .inProgress: return .orange
        case .scheduled: return .blue
        case .rescheduled: return .yellow
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let session: WorkoutSession?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(date.shortDayName)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)

                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 44, height: 44)

                    if let session = session, session.status != .scheduled {
                        statusIcon
                    } else if let workoutType = session?.workoutType {
                        WorkoutTypeBadge(workoutType, size: .medium)
                    } else {
                        Text(date.dayNumber)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(date.isToday ? .blue : .primary)
                    }
                }
            }
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2)
                    .padding(-4)
            }
        }
    }

    private var backgroundColor: Color {
        if date.isToday {
            return .blue.opacity(0.15)
        }
        return Color(.systemGray6)
    }

    @ViewBuilder
    private var statusIcon: some View {
        if let session = session {
            switch session.status {
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            case .missed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            case .inProgress:
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    VStack {
        WeekCalendarStrip()
    }
    .environmentObject(ScheduleViewModel())
}
