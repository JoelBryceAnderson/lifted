import SwiftUI

struct WorkoutTypeChip: View {
    let workoutType: WorkoutType
    let isSelected: Bool
    let action: (() -> Void)?

    init(_ workoutType: WorkoutType, isSelected: Bool = false, action: (() -> Void)? = nil) {
        self.workoutType = workoutType
        self.isSelected = isSelected
        self.action = action
    }

    var color: Color {
        Color.workoutTypeColor(workoutType)
    }

    var body: some View {
        if let action = action {
            Button(action: action) {
                chipContent
            }
        } else {
            chipContent
        }
    }

    private var chipContent: some View {
        HStack(spacing: 6) {
            Image(systemName: workoutType.iconName)
                .font(.system(size: 12, weight: .semibold))

            Text(workoutType.displayName)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? color : color.opacity(0.15))
        .foregroundColor(isSelected ? .white : color)
        .cornerRadius(20)
    }
}

struct WorkoutTypePicker: View {
    @Binding var selectedType: WorkoutType?
    let excludeRest: Bool

    init(selection: Binding<WorkoutType?>, excludeRest: Bool = true) {
        self._selectedType = selection
        self.excludeRest = excludeRest
    }

    var types: [WorkoutType] {
        excludeRest ? WorkoutType.allCases.filter { $0 != .rest } : WorkoutType.allCases
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(types, id: \.self) { type in
                    WorkoutTypeChip(type, isSelected: selectedType == type) {
                        if selectedType == type {
                            selectedType = nil
                        } else {
                            selectedType = type
                        }
                        Haptics.selection()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct WorkoutTypeBadge: View {
    let workoutType: WorkoutType
    let size: BadgeSize

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 14
            case .large: return 18
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 10
            }
        }
    }

    init(_ workoutType: WorkoutType, size: BadgeSize = .medium) {
        self.workoutType = workoutType
        self.size = size
    }

    var body: some View {
        Image(systemName: workoutType.iconName)
            .font(.system(size: size.iconSize, weight: .semibold))
            .foregroundColor(.white)
            .padding(size.padding)
            .background(Color.workoutTypeColor(workoutType))
            .clipShape(Circle())
    }
}

struct DayTypeSelector: View {
    @Binding var dayType: ScheduledDayType

    var body: some View {
        Menu {
            Button {
                dayType = .rest
            } label: {
                Label("Rest Day", systemImage: "bed.double.fill")
            }

            Divider()

            ForEach(WorkoutType.allCases.filter { $0 != .rest }, id: \.self) { type in
                Button {
                    dayType = .workout(type)
                } label: {
                    Label(type.displayName, systemImage: type.iconName)
                }
            }
        } label: {
            HStack(spacing: 8) {
                if case .workout(let type) = dayType {
                    WorkoutTypeBadge(type, size: .small)
                    Text(type.displayName)
                        .font(.subheadline)
                } else {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.gray)
                    Text("Rest")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            WorkoutTypeChip(.push)
            WorkoutTypeChip(.pull, isSelected: true)
            WorkoutTypeChip(.legs)
        }

        WorkoutTypePicker(selection: .constant(.push))

        HStack {
            WorkoutTypeBadge(.push, size: .small)
            WorkoutTypeBadge(.pull, size: .medium)
            WorkoutTypeBadge(.legs, size: .large)
        }

        DayTypeSelector(dayType: .constant(.workout(.push)))
    }
    .padding()
}
