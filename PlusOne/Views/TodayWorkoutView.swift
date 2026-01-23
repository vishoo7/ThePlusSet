import SwiftUI
import SwiftData

struct TodayWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]
    @Query private var trainingMaxes: [TrainingMax]
    @Query private var cycleProgressArray: [CycleProgress]
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    @Query private var personalRecords: [PersonalRecord]

    @StateObject private var timerVM = TimerViewModel()
    @StateObject private var workoutVM = WorkoutViewModel()

    @State private var currentWorkout: Workout?
    @State private var selectedSet: WorkoutSet?
    @State private var showingRepInput = false
    @State private var showingNewCycleSheet = false
    @State private var pendingNewTMs: [LiftType: Double] = [:]
    @State private var showingPRCelebration = false
    @State private var newPRLift: LiftType?

    private var settings: AppSettings {
        settingsArray.first ?? AppSettings()
    }

    private var cycleProgress: CycleProgress {
        cycleProgressArray.first ?? CycleProgress()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Cycle info header
                        cycleHeader

                        if let workout = currentWorkout {
                            // Main sets section
                            setsSection(title: "Main Sets", sets: workout.mainSets)

                            // BBB sets section
                            setsSection(title: "BBB Sets (5×10)", sets: workout.bbbSets)

                            // Complete workout button
                            if (workout.sets ?? []).allSatisfy({ $0.isComplete }) {
                                completeWorkoutButton
                            }
                        } else {
                            startWorkoutButton
                        }
                    }
                    .padding()
                }

                // Timer overlay
                if timerVM.isRunning {
                    VStack {
                        Spacer()
                        TimerView(
                            timerVM: timerVM,
                            onAddTime: { timerVM.addTime(seconds: $0) },
                            onStop: { timerVM.stop() }
                        )
                        .padding()
                    }
                    .transition(.move(edge: .bottom))
                }

                // PR celebration overlay
                if showingPRCelebration, let lift = newPRLift {
                    prCelebrationOverlay(for: lift)
                }
            }
            .navigationTitle("Today's Workout")
            .sheet(isPresented: $showingRepInput) {
                if let set = selectedSet {
                    RepInputSheet(
                        set: set,
                        onComplete: { reps in
                            completeSet(set, reps: reps)
                            showingRepInput = false
                            selectedSet = nil
                        },
                        onCancel: {
                            showingRepInput = false
                            selectedSet = nil
                        }
                    )
                    .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: $showingNewCycleSheet) {
                newCycleSheet
            }
            .onAppear {
                workoutVM.setModelContext(modelContext)
                loadOrCreateWorkout()
            }
        }
    }

    // MARK: - Subviews

    private var cycleHeader: some View {
        VStack(spacing: 8) {
            Text("Cycle \(cycleProgress.cycleNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(cycleProgress.weekDescription)
                .font(.headline)

            if let workout = currentWorkout {
                Text(workout.liftType.rawValue)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func setsSection(title: String, sets: [WorkoutSet]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(sets, id: \.id) { set in
                SetRowView(
                    set: set,
                    plates: PlateCalculator.platesPerSide(
                        targetWeight: set.targetWeight,
                        availablePlates: settings.availablePlates,
                        barWeight: settings.barWeight
                    ),
                    onTap: {
                        if !set.isComplete {
                            selectedSet = set
                            showingRepInput = true
                        }
                    }
                )
            }
        }
    }

    private var startWorkoutButton: some View {
        Button {
            createNewWorkout()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 48))
                Text("Start Today's Workout")
                    .font(.headline)
                Text("\(cycleProgress.currentLiftType.rawValue) - \(cycleProgress.weekDescription)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var completeWorkoutButton: some View {
        Button {
            completeWorkout()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Complete Workout")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var newCycleSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)

                Text("Week 3 Complete!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Based on your AMRAP performance, here are your new training maxes:")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    ForEach(LiftType.allCases) { liftType in
                        if let newTM = pendingNewTMs[liftType] {
                            let currentTM = trainingMaxes.first(where: { $0.liftType == liftType })?.weight ?? 0
                            HStack {
                                Text(liftType.rawValue)
                                Spacer()
                                Text("\(PlateCalculator.formatWeight(currentTM))")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.green)
                                Text("\(PlateCalculator.formatWeight(newTM)) lbs")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                Button {
                    applyNewTMs()
                    showingNewCycleSheet = false
                } label: {
                    Text("Start Next Cycle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .navigationTitle("New Cycle")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func prCelebrationOverlay(for lift: LiftType) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)

            Text("NEW PR!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(lift.rawValue)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
        .onTapGesture {
            withAnimation {
                showingPRCelebration = false
                newPRLift = nil
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showingPRCelebration = false
                    newPRLift = nil
                }
            }
        }
    }

    // MARK: - Actions

    private func loadOrCreateWorkout() {
        // Check if there's an incomplete workout for today
        let today = Calendar.current.startOfDay(for: Date())
        if let existingWorkout = allWorkouts.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: today) && !$0.isComplete
        }) {
            currentWorkout = existingWorkout
        }
    }

    private func createNewWorkout() {
        let workout = workoutVM.generateWorkout(
            for: cycleProgress,
            trainingMaxes: trainingMaxes,
            settings: settings
        )
        modelContext.insert(workout)
        currentWorkout = workout
        try? modelContext.save()
    }

    private func completeSet(_ set: WorkoutSet, reps: Int) {
        set.complete(reps: reps)
        try? modelContext.save()

        // Start rest timer
        let restTime = set.isBBB ? settings.bbbSetRestSeconds : settings.mainSetRestSeconds
        timerVM.start(seconds: restTime)

        // Check for PR on AMRAP sets
        if set.isAMRAP, let workout = currentWorkout {
            checkForPR(set: set, workout: workout, reps: reps)
        }
    }

    private func checkForPR(set: WorkoutSet, workout: Workout, reps: Int) {
        let estimated1RM = WendlerCalculator.estimatedOneRepMax(weight: set.targetWeight, reps: reps)

        let currentPR = personalRecords
            .filter { $0.liftType == workout.liftType }
            .max { $0.estimated1RM < $1.estimated1RM }

        if currentPR == nil || estimated1RM > currentPR!.estimated1RM {
            let newPR = PersonalRecord(
                liftType: workout.liftType,
                weight: set.targetWeight,
                reps: reps,
                workoutSetId: set.id
            )
            modelContext.insert(newPR)
            try? modelContext.save()

            // Show PR celebration
            newPRLift = workout.liftType
            withAnimation {
                showingPRCelebration = true
            }
        }
    }

    private func completeWorkout() {
        guard let workout = currentWorkout else { return }

        workout.isComplete = true
        try? modelContext.save()

        // Check for progression after week 3
        if workout.weekNumber == 3 {
            calculateNewTMs(for: workout)
        }

        // Advance to next workout
        cycleProgress.advanceToNextWorkout()
        try? modelContext.save()

        // Reset state
        currentWorkout = nil
        timerVM.stop()
    }

    private func calculateNewTMs(for workout: Workout) {
        guard let amrapSet = workout.amrapSet,
              let actualReps = amrapSet.actualReps else { return }

        let estimated1RM = WendlerCalculator.estimatedOneRepMax(
            weight: amrapSet.targetWeight,
            reps: actualReps
        )
        let newTM = WendlerCalculator.newTrainingMax(from: estimated1RM)

        if let currentTM = trainingMaxes.first(where: { $0.liftType == workout.liftType }) {
            if newTM > currentTM.weight {
                pendingNewTMs[workout.liftType] = newTM
            }
        }

        // Show new cycle sheet if we have pending TM updates
        // This happens after all 4 lifts in week 3 are done
        if cycleProgress.currentDay == 3 && !pendingNewTMs.isEmpty {
            showingNewCycleSheet = true
        }
    }

    private func applyNewTMs() {
        for (liftType, newWeight) in pendingNewTMs {
            if let tm = trainingMaxes.first(where: { $0.liftType == liftType }) {
                tm.weight = newWeight
                tm.updatedAt = Date()
            }
        }
        pendingNewTMs.removeAll()
        try? modelContext.save()
    }
}

#Preview {
    TodayWorkoutView()
        .modelContainer(for: [
            AppSettings.self,
            TrainingMax.self,
            CycleProgress.self,
            Workout.self,
            WorkoutSet.self,
            PersonalRecord.self
        ])
}
