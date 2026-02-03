import SwiftUI

struct WorkoutCompleteView: View {
    let workoutInfo: WatchWorkoutInfo
    let totalSetsCount: Int

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)

            Text("Workout Complete!")
                .font(.headline)
                .fontWeight(.bold)

            VStack(spacing: 4) {
                Text(workoutInfo.liftType)
                    .font(.subheadline)

                Text("\(totalSetsCount) sets completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Great work!")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding()
    }
}

#Preview {
    WorkoutCompleteView(
        workoutInfo: WatchWorkoutInfo(liftType: "Squat", weekNumber: 3, cycleNumber: 1),
        totalSetsCount: 11
    )
}
