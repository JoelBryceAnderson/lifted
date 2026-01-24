import SwiftUI

struct ScheduleBuilderView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @State private var showTemplates = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Build Your Schedule")
                    .font(.largeTitle.bold())

                Text("Design your weekly workout cycle")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 24) {
                    // Templates button
                    Button {
                        showTemplates = true
                    } label: {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                            Text("Use a Template")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal)

                    // Summary
                    HStack(spacing: 24) {
                        VStack {
                            Text("\(onboardingViewModel.workoutDaysCount)")
                                .font(.title.bold())
                                .foregroundColor(.blue)
                            Text("Workout Days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack {
                            Text("\(onboardingViewModel.restDaysCount)")
                                .font(.title.bold())
                                .foregroundColor(.gray)
                            Text("Rest Days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Day-by-day schedule
                    VStack(spacing: 12) {
                        ForEach(0..<onboardingViewModel.cycleDuration, id: \.self) { index in
                            ScheduleDayRow(
                                dayIndex: index,
                                dayType: Binding(
                                    get: {
                                        onboardingViewModel.scheduleDays[safe: index] ?? .rest
                                    },
                                    set: { newValue in
                                        onboardingViewModel.setDayType(at: index, to: newValue)
                                    }
                                )
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()

            OnboardingNavigationButtons(
                canProceed: onboardingViewModel.hasValidSchedule
            )
        }
        .sheet(isPresented: $showTemplates) {
            TemplatePickerSheet()
        }
    }
}

struct ScheduleDayRow: View {
    let dayIndex: Int
    @Binding var dayType: ScheduledDayType

    private var dayName: String {
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return weekdays[dayIndex % 7]
    }

    var body: some View {
        HStack {
            Text(dayName)
                .font(.headline)
                .frame(width: 100, alignment: .leading)

            Spacer()

            DayTypeSelector(dayType: $dayType)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct TemplatePickerSheet: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(ScheduleTemplate.templates, id: \.name) { template in
                    Button {
                        onboardingViewModel.applyTemplate(template)
                        dismiss()
                        Haptics.success()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.name)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text(template.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            // Preview
                            HStack(spacing: 4) {
                                ForEach(0..<template.days.count, id: \.self) { index in
                                    let dayType = template.days[index]
                                    if case .workout(let type) = dayType {
                                        WorkoutTypeBadge(type, size: .small)
                                    } else {
                                        Circle()
                                            .fill(Color(.systemGray4))
                                            .frame(width: 22, height: 22)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ScheduleBuilderView()
        .environmentObject(OnboardingViewModel())
}
