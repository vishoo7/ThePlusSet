import SwiftUI

struct NoWorkoutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Active Workout")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Start a workout on your iPhone")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    NoWorkoutView()
}
