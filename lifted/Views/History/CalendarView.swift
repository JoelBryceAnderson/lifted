import SwiftUI

struct CalendarView: View {
    let sessions: [WorkoutSession]
    let onSelectSession: (WorkoutSession) -> Void

    @State private var currentMonth = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.blue)
                }

                Spacer()

                Text(monthYearString)
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            // Day headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            session: sessionForDate(date),
                            onTap: {
                                if let session = sessionForDate(date) {
                                    onSelectSession(session)
                                }
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var daysInMonth: [Date?] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        // Pad to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func sessionForDate(_ date: Date) -> WorkoutSession? {
        sessions.first { session in
            calendar.isDate(session.scheduledDate, inSameDayAs: date)
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let session: WorkoutSession?
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)

                // Content
                if let session = session {
                    WorkoutTypeBadge(session.workoutType, size: .small)
                        .overlay {
                            if session.status == .completed {
                                Circle()
                                    .stroke(Color.green, lineWidth: 2)
                            } else if session.status == .missed {
                                Circle()
                                    .stroke(Color.red, lineWidth: 2)
                            }
                        }
                } else {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.subheadline)
                        .foregroundColor(textColor)
                }
            }
        }
        .disabled(session == nil)
    }

    private var backgroundColor: Color {
        if calendar.isDateInToday(date) {
            return .blue.opacity(0.15)
        }
        return Color(.systemGray6)
    }

    private var textColor: Color {
        if calendar.isDateInToday(date) {
            return .blue
        } else if date > Date() {
            return .secondary
        }
        return .primary
    }
}

#Preview {
    CalendarView(
        sessions: [
            WorkoutSession(
                userId: "test",
                workoutType: .push,
                scheduledDate: Date(),
                cycleDay: 0,
                status: .completed
            )
        ],
        onSelectSession: { _ in }
    )
    .padding()
    .background(Color(.systemGray6))
}
