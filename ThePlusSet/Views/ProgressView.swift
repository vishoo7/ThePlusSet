import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Query(sort: \PersonalRecord.date) private var allPRs: [PersonalRecord]
    @Query(sort: \Workout.date) private var allWorkouts: [Workout]

    @State private var selectedLift: LiftType = .squat

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    // MARK: - Computed Data

    private var oneRMPoints: [ChartPoint] {
        allPRs
            .filter { $0.liftType == selectedLift }
            .map { ChartPoint(date: $0.date, value: $0.estimated1RM) }
    }

    private var trainingMaxPoints: [ChartPoint] {
        let weekTopPercentage: [Int: Double] = [1: 0.85, 2: 0.90, 3: 0.95]
        return allWorkouts
            .filter { $0.liftType == selectedLift && $0.isComplete && $0.weekNumber != 4 }
            .compactMap { workout -> ChartPoint? in
                guard let amrap = workout.amrapSet,
                      let pct = weekTopPercentage[workout.weekNumber],
                      pct > 0 else { return nil }
                let impliedTM = amrap.targetWeight / pct
                return ChartPoint(date: workout.date, value: (impliedTM * 2).rounded() / 2)
            }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    liftPicker
                    oneRMSection
                    trainingMaxSection
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }

    // MARK: - Subviews

    private var liftPicker: some View {
        Picker("Lift", selection: $selectedLift) {
            ForEach(LiftType.allCases) { lift in
                Text(lift.shortName).tag(lift)
            }
        }
        .pickerStyle(.segmented)
    }

    private var oneRMSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimated 1RM")
                .font(.headline)

            if oneRMPoints.isEmpty {
                emptyState(message: "Complete AMRAP sets to see 1RM trends")
            } else {
                Chart(oneRMPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", point.value)
                    )
                    .foregroundStyle(liftColor)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", point.value)
                    )
                    .foregroundStyle(liftColor)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var trainingMaxSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Max")
                .font(.headline)

            if trainingMaxPoints.isEmpty {
                emptyState(message: "Complete workouts to see training max progression")
            } else {
                Chart(trainingMaxPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("TM", point.value)
                    )
                    .foregroundStyle(liftColor)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("TM", point.value)
                    )
                    .foregroundStyle(liftColor)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func emptyState(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 40)
    }

    private var liftColor: Color {
        switch selectedLift {
        case .squat: .blue
        case .bench: .orange
        case .deadlift: .red
        case .overheadPress: .green
        }
    }
}
