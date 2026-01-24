import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]

    @State private var squatTM: String = ""
    @State private var benchTM: String = ""
    @State private var deadliftTM: String = ""
    @State private var ohpTM: String = ""
    @State private var currentStep = 0

    let onComplete: () -> Void

    private var settings: AppSettings {
        settingsArray.first ?? AppSettings()
    }

    var body: some View {
        VStack(spacing: 32) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal)

            TabView(selection: $currentStep) {
                // Step 1: Welcome
                welcomeStep
                    .tag(0)

                // Step 2: Enter Training Maxes
                trainingMaxStep
                    .tag(1)

                // Step 3: Ready to go
                readyStep
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .padding()
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Welcome to Plus One")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("The simple way to track your Wendler 5/3/1 workouts")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                requestNotificationPermission()
                currentStep = 1
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var trainingMaxStep: some View {
        VStack(spacing: 24) {
            Text("Set Your Training Maxes")
                .font(.title)
                .fontWeight(.bold)

            Text("Enter 90% of your true 1RM for each lift")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                tmInputRow(title: "Squat", value: $squatTM)
                tmInputRow(title: "Bench Press", value: $benchTM)
                tmInputRow(title: "Deadlift", value: $deadliftTM)
                tmInputRow(title: "Overhead Press", value: $ohpTM)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()

            Button {
                currentStep = 2
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(allFieldsFilled ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!allFieldsFilled)
        }
    }

    private var readyStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "calendar", text: "4-week training cycles")
                featureRow(icon: "chart.line.uptrend.xyaxis", text: "Automatic progression")
                featureRow(icon: "trophy", text: "PR tracking")
                featureRow(icon: "icloud", text: "iCloud sync")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()

            Button {
                saveAndComplete()
            } label: {
                Text("Start Training")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Helper Views

    private func tmInputRow(title: String, value: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text("lbs")
                .foregroundStyle(.secondary)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
        }
    }

    // MARK: - Computed Properties

    private var allFieldsFilled: Bool {
        Double(squatTM) != nil &&
        Double(benchTM) != nil &&
        Double(deadliftTM) != nil &&
        Double(ohpTM) != nil
    }

    // MARK: - Actions

    private func requestNotificationPermission() {
        Task {
            await NotificationManager.shared.requestPermission()
            settings.hasRequestedNotificationPermission = true
            try? modelContext.save()
        }
    }

    private func saveAndComplete() {
        // Create training maxes
        if let squat = Double(squatTM) {
            modelContext.insert(TrainingMax(liftType: .squat, weight: squat))
        }
        if let bench = Double(benchTM) {
            modelContext.insert(TrainingMax(liftType: .bench, weight: bench))
        }
        if let deadlift = Double(deadliftTM) {
            modelContext.insert(TrainingMax(liftType: .deadlift, weight: deadlift))
        }
        if let ohp = Double(ohpTM) {
            modelContext.insert(TrainingMax(liftType: .overheadPress, weight: ohp))
        }

        // Create cycle progress
        modelContext.insert(CycleProgress())

        // Mark onboarding complete
        settings.hasCompletedOnboarding = true

        try? modelContext.save()
        onComplete()
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: [AppSettings.self, TrainingMax.self, CycleProgress.self])
}
