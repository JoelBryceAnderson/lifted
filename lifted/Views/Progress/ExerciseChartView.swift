import SwiftUI
import Charts

struct ExerciseChartView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var progressViewModel: ProgressViewModel

    let exercise: Exercise

    @State private var chartType: ChartType = .weight

    enum ChartType: String, CaseIterable {
        case weight = "Weight"
        case volume = "Volume"
    }

    var body: some View {
        VStack(spacing: 16) {
            // Chart type picker
            Picker("Chart Type", selection: $chartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            // Chart
            if progressViewModel.exerciseHistory.isEmpty {
                Text("No data yet for \(exercise.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                chartView
                    .frame(height: 200)
            }

            // AI Analysis button
            AIAnalysisSection(exercise: exercise)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .task {
            await loadHistory()
        }
        .onChange(of: exercise.id) { _, _ in
            Task {
                await loadHistory()
            }
        }
    }

    @ViewBuilder
    private var chartView: some View {
        switch chartType {
        case .weight:
            WeightChart(data: progressViewModel.exerciseHistory)
        case .volume:
            VolumeChart(data: progressViewModel.exerciseHistory)
        }
    }

    private func loadHistory() async {
        guard let userId = authViewModel.user?.id else { return }
        await progressViewModel.loadExerciseHistory(userId: userId, exerciseId: exercise.id)
    }
}

struct WeightChart: View {
    let data: [ExerciseHistoryPoint]

    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.maxWeight)
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.maxWeight)
            )
            .foregroundStyle(.blue)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let weight = value.as(Double.self) {
                        Text("\(Int(weight))")
                    }
                }
            }
        }
    }
}

struct VolumeChart: View {
    let data: [ExerciseHistoryPoint]

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Date", point.date),
                y: .value("Volume", point.totalVolume)
            )
            .foregroundStyle(.purple.gradient)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let volume = value.as(Double.self) {
                        Text(volume.volumeString)
                    }
                }
            }
        }
    }
}

struct AIAnalysisSection: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var progressViewModel: ProgressViewModel

    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("AI Analysis")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if progressViewModel.isLoadingAnalysis {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button("Analyze") {
                        loadAnalysis()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(.blue)
                }
            }

            if let analysis = progressViewModel.progressAnalysis {
                Text(analysis)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func loadAnalysis() {
        guard let userId = authViewModel.user?.id else { return }
        Task {
            await progressViewModel.loadProgressAnalysis(
                userId: userId,
                exerciseName: exercise.name
            )
        }
    }
}

#Preview {
    ExerciseChartView(
        exercise: ExerciseSeedData.exercises.first!
    )
    .environmentObject(AuthViewModel())
    .environmentObject(ProgressViewModel())
    .padding()
}
