import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]

    @State private var squat1RM: String = ""
    @State private var bench1RM: String = ""
    @State private var deadlift1RM: String = ""
    @State private var ohp1RM: String = ""
    @State private var currentStep = 0
    @FocusState private var isInputFocused: Bool

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

            Text("Welcome to")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("The Plus Set")
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
            Text("Enter Your 1 Rep Maxes")
                .font(.title)
                .fontWeight(.bold)

            Text("The heaviest weight you can lift once for each exercise")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                oneRMInputRow(title: "Squat", value: $squat1RM)
                oneRMInputRow(title: "Bench Press", value: $bench1RM)
                oneRMInputRow(title: "Deadlift", value: $deadlift1RM)
                oneRMInputRow(title: "Overhead Press", value: $ohp1RM)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()

            Button {
                isInputFocused = false
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                }
            }
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

    private func oneRMInputRow(title: String, value: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .focused($isInputFocused)
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
        Double(squat1RM) != nil &&
        Double(bench1RM) != nil &&
        Double(deadlift1RM) != nil &&
        Double(ohp1RM) != nil
    }

    // MARK: - Actions

    private func requestNotificationPermission() {
        Task {
            _ = await NotificationManager.shared.requestPermission()
            settings.hasRequestedNotificationPermission = true
            try? modelContext.save()
        }
    }

    private func saveAndComplete() {
        // Create training maxes (TM = 1RM × training max percentage)
        let tmPercent = settings.trainingMaxPercentage
        if let squat = Double(squat1RM) {
            modelContext.insert(TrainingMax(liftType: .squat, weight: squat * tmPercent))
        }
        if let bench = Double(bench1RM) {
            modelContext.insert(TrainingMax(liftType: .bench, weight: bench * tmPercent))
        }
        if let deadlift = Double(deadlift1RM) {
            modelContext.insert(TrainingMax(liftType: .deadlift, weight: deadlift * tmPercent))
        }
        if let ohp = Double(ohp1RM) {
            modelContext.insert(TrainingMax(liftType: .overheadPress, weight: ohp * tmPercent))
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
