import SwiftUI
import SwiftData
import AudioToolbox

struct TodayWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]
    @Query private var trainingMaxes: [TrainingMax]
    @Query private var cycleProgressArray: [CycleProgress]
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    @Query private var personalRecords: [PersonalRecord]

    @EnvironmentObject var timerVM: TimerViewModel
    @StateObject private var workoutVM = WorkoutViewModel()

    private let watchSession = PhoneSessionManager.shared

    @State private var currentWorkout: Workout?
    @State private var showTimerOverlay = false
    @State private var selectedSet: WorkoutSet?
    @State private var showingNewCycleSheet = false
    @State private var pendingNewTMs: [LiftType: Double] = [:]
    @State private var showingPRCelebration = false
    @State private var newPRLift: LiftType?
    @State private var showingLiftPicker = false
    @State private var selectedLiftType: LiftType?
    @State private var showingChangeExerciseConfirmation = false
    @State private var pendingNewLiftType: LiftType?
    @State private var lastCompletedSetId: UUID?

    private var settings: AppSettings {
        settingsArray.first ?? AppSettings()
    }

    private var cycleProgress: CycleProgress {
        cycleProgressArray.first ?? CycleProgress()
    }

    // Get exercises already completed this week (same cycle and week number)
    private var exercisesCompletedThisWeek: Set<LiftType> {
        let currentCycle = cycleProgress.cycleNumber
        let currentWeek = cycleProgress.currentWeek

        let completedThisWeek = allWorkouts.filter { workout in
            workout.isComplete &&
            workout.cycleNumber == currentCycle &&
            workout.weekNumber == currentWeek
        }

        return Set(completedThisWeek.map { $0.liftType })
    }

    // Exercises available to switch to (not done this week, excluding current)
    private var availableExercisesForChange: [LiftType] {
        guard let current = currentWorkout else { return [] }
        let completed = exercisesCompletedThisWeek
        return settings.exerciseOrder.filter { lift in
            lift != current.liftType && !completed.contains(lift)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Cycle info header
                        cycleHeader

                        if let workout = currentWorkout {
                            // Warmup sets section (hidden on deload week)
                            if !workout.warmupSets.isEmpty {
                                setsSection(title: "Warmup", sets: workout.warmupSets, isWarmup: true)
                            }

                            // Main sets section
                            setsSection(title: "Working Sets", sets: workout.mainSets)

                            // BBB sets section (hidden on deload week)
                            if !workout.bbbSets.isEmpty {
                                setsSection(title: "BBB Sets (5×10)", sets: workout.bbbSets)
                            }

                            // Notes section
                            notesSection(workout: workout)

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
                if timerVM.isRunning && showTimerOverlay {
                    // Tap outside to dismiss
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showTimerOverlay = false
                        }

                    VStack {
                        Spacer()
                        TimerView(
                            timerVM: timerVM,
                            onAddTime: { timerVM.addTime(seconds: $0) },
                            onStop: {
                                timerVM.stop()
                                showTimerOverlay = false
                                // Watch refresh handled by onChange(of: timerVM.isRunning)
                            },
                            onDismiss: { showTimerOverlay = false }
                        )
                        .padding(.horizontal)
                    }
                    .transition(.move(edge: .bottom))
                }

                // PR celebration overlay
                if showingPRCelebration, let lift = newPRLift {
                    prCelebrationOverlay(for: lift)
                }
            }
            .navigationTitle("Today's Workout")
            .sheet(item: $selectedSet) { set in
                RepInputSheet(
                    set: set,
                    onComplete: { reps in
                        completeSet(set, reps: reps)
                        selectedSet = nil
                    },
                    onCancel: {
                        selectedSet = nil
                    }
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingNewCycleSheet) {
                newCycleSheet
            }
            .alert("Change Exercise?", isPresented: $showingChangeExerciseConfirmation) {
                Button("Cancel", role: .cancel) {
                    pendingNewLiftType = nil
                }
                Button("Change") {
                    if let newLift = pendingNewLiftType {
                        changeExercise(to: newLift)
                    }
                }
            } message: {
                if let newLift = pendingNewLiftType {
                    Text("This will discard your current workout progress and start a new \(newLift.rawValue) workout.")
                }
            }
            .onAppear {
                loadOrCreateWorkout()

                // Update watch with current state
                if let workout = currentWorkout {
                    sendWorkoutStartedToWatch(workout)
                } else {
                    watchSession.sendWorkoutCleared()
                }
            }
            .onChange(of: timerVM.isRunning) { wasRunning, isRunning in
                // When timer stops (completes naturally or via skip), refresh watch state
                if wasRunning && !isRunning {
                    // Small delay to ensure timer update is processed first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        refreshWatchState()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var cycleHeader: some View {
        VStack(spacing: 8) {
            Text("The Plus Set")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.tertiary)

            Text("Cycle \(cycleProgress.cycleNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(cycleProgress.weekDescription)
                .font(.headline)

            if let workout = currentWorkout {
                HStack(spacing: 8) {
                    Text(workout.liftType.rawValue)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if !availableExercisesForChange.isEmpty {
                        Menu {
                            ForEach(availableExercisesForChange) { lift in
                                Button {
                                    pendingNewLiftType = lift
                                    showingChangeExerciseConfirmation = true
                                } label: {
                                    Label(lift.rawValue, systemImage: "figure.strengthtraining.traditional")
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.title3)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var nextIncompleteSetId: UUID? {
        guard let workout = currentWorkout else { return nil }
        let orderedSets = workout.warmupSets + workout.mainSets + workout.bbbSets
        return orderedSets.first(where: { !$0.isComplete })?.id
    }

    private func setsSection(title: String, sets: [WorkoutSet], isWarmup: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(isWarmup ? .orange : .secondary)

            ForEach(sets, id: \.id) { set in
                let isNextSet = set.id == nextIncompleteSetId
                SetRowView(
                    set: set,
                    plates: PlateCalculator.platesPerSide(
                        targetWeight: set.targetWeight,
                        availablePlates: settings.availablePlates,
                        barWeight: settings.barWeight
                    ),
                    onTap: {
                        if !set.isComplete && isNextSet {
                            selectedSet = set
                        }
                    },
                    onQuickComplete: {
                        if !set.isComplete && isNextSet {
                            quickCompleteSet(set)
                        }
                    },
                    onUndo: {
                        undoSet(set)
                    },
                    canUndo: set.id == lastCompletedSetId,
                    isActive: isNextSet
                )
            }
        }
    }

    private func notesSection(workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(.secondary)

            TextField("Add notes for this workout...", text: Binding(
                get: { workout.notes },
                set: {
                    workout.notes = $0
                    try? modelContext.save()
                }
            ), axis: .vertical)
            .lineLimit(3...6)
            .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var suggestedLiftType: LiftType {
        // Get the next exercise in order that hasn't been done this week
        let completed = exercisesCompletedThisWeek
        for lift in settings.exerciseOrder {
            if !completed.contains(lift) {
                return lift
            }
        }
        // Fallback to cycle progress default
        return cycleProgress.liftType(for: settings)
    }

    // Exercises available to start (not done this week)
    private var availableExercisesToStart: [LiftType] {
        let completed = exercisesCompletedThisWeek
        return settings.exerciseOrder.filter { !completed.contains($0) }
    }

    private var startWorkoutButton: some View {
        VStack(spacing: 16) {
            // Exercise picker
            VStack(spacing: 12) {
                Text("Select Exercise")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    ForEach(availableExercisesToStart) { lift in
                        Button {
                            selectedLiftType = lift
                        } label: {
                            Text(lift.shortName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    (selectedLiftType ?? suggestedLiftType) == lift
                                        ? Color.blue
                                        : Color(.secondarySystemBackground)
                                )
                                .foregroundStyle(
                                    (selectedLiftType ?? suggestedLiftType) == lift
                                        ? .white
                                        : .primary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Start button
            Button {
                createNewWorkout()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 48))
                    Text("Start Workout")
                        .font(.headline)
                    Text("\((selectedLiftType ?? suggestedLiftType).rawValue) - \(cycleProgress.weekDescription)")
                        .font(.subheadline)
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
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
            settings: settings,
            overrideLiftType: selectedLiftType ?? suggestedLiftType
        )
        modelContext.insert(workout)
        currentWorkout = workout
        selectedLiftType = nil
        try? modelContext.save()

        // Send workout started to watch
        sendWorkoutStartedToWatch(workout)
    }

    private func sendWorkoutStartedToWatch(_ workout: Workout) {
        let orderedSets = workout.warmupSets + workout.mainSets + workout.bbbSets
        guard let firstSet = orderedSets.first else { return }

        let plates = PlateCalculator.platesPerSide(
            targetWeight: firstSet.targetWeight,
            availablePlates: settings.availablePlates,
            barWeight: settings.barWeight
        )

        let nextSet = orderedSets.count > 1 ? orderedSets[1] : nil
        let nextSetPlates = nextSet.map {
            PlateCalculator.platesPerSide(
                targetWeight: $0.targetWeight,
                availablePlates: settings.availablePlates,
                barWeight: settings.barWeight
            )
        }

        watchSession.sendWorkoutStarted(
            workout: WorkoutInfo.from(workout),
            currentSet: SetInfo.from(firstSet, plates: plates),
            nextSet: nextSet.map { SetInfo.from($0, plates: nextSetPlates ?? []) },
            completedSetsCount: 0,
            totalSetsCount: orderedSets.count
        )
    }

    private func changeExercise(to newLiftType: LiftType) {
        // Delete the current incomplete workout
        if let workout = currentWorkout {
            if let sets = workout.sets {
                for set in sets {
                    modelContext.delete(set)
                }
            }
            modelContext.delete(workout)
        }

        // Create new workout with the selected exercise
        let newWorkout = workoutVM.generateWorkout(
            for: cycleProgress,
            trainingMaxes: trainingMaxes,
            settings: settings,
            overrideLiftType: newLiftType
        )
        modelContext.insert(newWorkout)
        currentWorkout = newWorkout
        pendingNewLiftType = nil
        try? modelContext.save()
    }

    private func quickCompleteSet(_ set: WorkoutSet) {
        // Quick complete uses the target reps
        completeSet(set, reps: set.targetReps)
    }

    private func undoSet(_ set: WorkoutSet) {
        // Only allow undo of the last completed set
        guard set.id == lastCompletedSetId else { return }

        set.actualReps = nil
        set.isComplete = false

        // Find the previous completed set to make it undoable
        lastCompletedSetId = findLastCompletedSet()?.id

        // Stop the timer if running
        timerVM.stop()
        showTimerOverlay = false

        try? modelContext.save()
    }

    private func findLastCompletedSet() -> WorkoutSet? {
        guard let workout = currentWorkout else { return nil }

        // Order: warmup -> main -> BBB
        let orderedSets = workout.warmupSets + workout.mainSets + workout.bbbSets

        // Find the last completed set
        return orderedSets.last(where: { $0.isComplete })
    }

    private func completeSet(_ set: WorkoutSet, reps: Int) {
        set.complete(reps: reps)
        lastCompletedSetId = set.id
        try? modelContext.save()

        // Start rest timer based on set type
        let restTime: Int
        if set.isWarmup {
            restTime = settings.warmupRestSeconds
        } else if set.isBBB {
            restTime = settings.bbbSetRestSeconds
        } else {
            restTime = settings.mainSetRestSeconds
        }

        // Find next incomplete set
        let nextSet = findNextIncompleteSet(after: set)
        let nextSetPlates = nextSet.map {
            PlateCalculator.platesPerSide(
                targetWeight: $0.targetWeight,
                availablePlates: settings.availablePlates,
                barWeight: settings.barWeight
            )
        } ?? []

        // Determine next set type
        let nextSetType: String
        if let next = nextSet {
            if next.isWarmup {
                nextSetType = "Warmup"
            } else if next.isBBB {
                nextSetType = "BBB"
            } else {
                nextSetType = "Working"
            }
        } else {
            nextSetType = ""
        }

        // Send set update to watch BEFORE starting timer to ensure correct ordering
        if let workout = currentWorkout {
            sendSetUpdateToWatch(workout: workout, nextSet: nextSet, nextSetPlates: nextSetPlates)
        }

        // Only start rest timer if there's a next set
        if nextSet != nil {
            // Set the chime sound from settings
            NotificationManager.shared.chimeSoundID = SystemSoundID(settings.timerChimeSoundID)
            timerVM.start(
                seconds: restTime,
                nextSetWeight: nextSet?.targetWeight,
                nextSetReps: nextSet?.targetReps,
                nextSetPlates: nextSetPlates,
                nextSetIsAMRAP: nextSet?.isAMRAP ?? false,
                nextSetType: nextSetType
            )
            showTimerOverlay = true
        }

        // Check for PR on AMRAP sets
        if set.isAMRAP, let workout = currentWorkout {
            checkForPR(set: set, workout: workout, reps: reps)
        }
    }

    private func sendSetUpdateToWatch(workout: Workout, nextSet: WorkoutSet?, nextSetPlates: [Double]) {
        let orderedSets = workout.warmupSets + workout.mainSets + workout.bbbSets
        let completedCount = orderedSets.filter { $0.isComplete }.count

        // Find the set after nextSet (for preview)
        var upcomingSet: WorkoutSet? = nil
        if let next = nextSet,
           let nextIndex = orderedSets.firstIndex(where: { $0.id == next.id }),
           nextIndex + 1 < orderedSets.count {
            upcomingSet = orderedSets[nextIndex + 1]
        }

        let upcomingSetPlates = upcomingSet.map {
            PlateCalculator.platesPerSide(
                targetWeight: $0.targetWeight,
                availablePlates: settings.availablePlates,
                barWeight: settings.barWeight
            )
        }

        watchSession.sendSetUpdated(
            workout: WorkoutInfo.from(workout),
            currentSet: nextSet.map { SetInfo.from($0, plates: nextSetPlates) },
            nextSet: upcomingSet.map { SetInfo.from($0, plates: upcomingSetPlates ?? []) },
            completedSetsCount: completedCount,
            totalSetsCount: orderedSets.count
        )
    }

    private func refreshWatchState() {
        guard let workout = currentWorkout else {
            watchSession.sendWorkoutCleared()
            return
        }

        let orderedSets = workout.warmupSets + workout.mainSets + workout.bbbSets
        let nextSet = orderedSets.first(where: { !$0.isComplete })
        let completedCount = orderedSets.filter { $0.isComplete }.count

        let nextSetPlates = nextSet.map {
            PlateCalculator.platesPerSide(
                targetWeight: $0.targetWeight,
                availablePlates: settings.availablePlates,
                barWeight: settings.barWeight
            )
        } ?? []

        // Find the set after nextSet (for preview)
        var upcomingSet: WorkoutSet? = nil
        if let next = nextSet,
           let nextIndex = orderedSets.firstIndex(where: { $0.id == next.id }),
           nextIndex + 1 < orderedSets.count {
            upcomingSet = orderedSets[nextIndex + 1]
        }

        let upcomingSetPlates = upcomingSet.map {
            PlateCalculator.platesPerSide(
                targetWeight: $0.targetWeight,
                availablePlates: settings.availablePlates,
                barWeight: settings.barWeight
            )
        }

        watchSession.sendSetUpdated(
            workout: WorkoutInfo.from(workout),
            currentSet: nextSet.map { SetInfo.from($0, plates: nextSetPlates) },
            nextSet: upcomingSet.map { SetInfo.from($0, plates: upcomingSetPlates ?? []) },
            completedSetsCount: completedCount,
            totalSetsCount: orderedSets.count
        )
    }

    private func findNextIncompleteSet(after completedSet: WorkoutSet) -> WorkoutSet? {
        guard let workout = currentWorkout,
              workout.sets != nil else { return nil }

        // Order: warmup -> main -> BBB
        let orderedSets = workout.warmupSets + workout.mainSets + workout.bbbSets

        // Find the index of the completed set
        guard let completedIndex = orderedSets.firstIndex(where: { $0.id == completedSet.id }) else {
            return nil
        }

        // Find the next incomplete set after this one
        for i in (completedIndex + 1)..<orderedSets.count {
            if !orderedSets[i].isComplete {
                return orderedSets[i]
            }
        }

        return nil
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

        // Send workout completed to watch
        let orderedSets = workout.warmupSets + workout.mainSets + workout.bbbSets
        watchSession.sendWorkoutCompleted(
            workout: WorkoutInfo.from(workout),
            totalSetsCount: orderedSets.count
        )

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
        showTimerOverlay = false
    }

    private func calculateNewTMs(for workout: Workout) {
        guard let amrapSet = workout.amrapSet,
              let actualReps = amrapSet.actualReps else { return }

        let estimated1RM = WendlerCalculator.estimatedOneRepMax(
            weight: amrapSet.targetWeight,
            reps: actualReps
        )
        let newTM = WendlerCalculator.newTrainingMax(from: estimated1RM, tmPercentage: settings.trainingMaxPercentage)

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
        .environmentObject(TimerViewModel())
        .modelContainer(for: [
            AppSettings.self,
            TrainingMax.self,
            CycleProgress.self,
            Workout.self,
            WorkoutSet.self,
            PersonalRecord.self
        ])
}
