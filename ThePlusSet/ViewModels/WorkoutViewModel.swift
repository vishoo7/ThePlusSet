import Foundation
import SwiftData

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var currentWorkout: Workout?
    @Published var showingNewTMPreview = false
    @Published var newTrainingMaxes: [LiftType: Double] = [:]

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func generateWorkout(
        for progress: CycleProgress,
        trainingMaxes: [TrainingMax],
        settings: AppSettings,
        overrideLiftType: LiftType? = nil
    ) -> Workout {
        let liftType = overrideLiftType ?? progress.currentLiftType
        let week = progress.currentWeek

        guard let tm = trainingMaxes.first(where: { $0.liftType == liftType }) else {
            fatalError("Training max not found for \(liftType.rawValue)")
        }

        let workout = Workout(
            liftType: liftType,
            cycleNumber: progress.cycleNumber,
            weekNumber: week
        )

        var setIndex = 0

        // Generate warmup sets (skip on deload week)
        if week != 4 {
            let warmupSets = WendlerCalculator.calculateWarmupSets(
                trainingMax: tm.weight,
                availablePlates: settings.availablePlates,
                barWeight: settings.barWeight
            )

            for set in warmupSets {
                let workoutSet = WorkoutSet(
                    setNumber: setIndex,
                    targetWeight: set.weight,
                    targetReps: set.reps,
                    isAMRAP: false,
                    isBBB: false,
                    isWarmup: true
                )
                workoutSet.workout = workout
                workout.addSet(workoutSet)
                setIndex += 1
            }
        }

        // Generate main sets
        let mainSets = WendlerCalculator.calculateMainSets(
            trainingMax: tm.weight,
            week: week,
            availablePlates: settings.availablePlates,
            barWeight: settings.barWeight
        )

        for set in mainSets {
            let workoutSet = WorkoutSet(
                setNumber: setIndex,
                targetWeight: set.weight,
                targetReps: set.reps,
                isAMRAP: set.isAMRAP,
                isBBB: false,
                isWarmup: false
            )
            workoutSet.workout = workout
            workout.addSet(workoutSet)
            setIndex += 1
        }

        // Generate BBB sets (skip on deload week)
        if week != 4 {
            let bbbSets = WendlerCalculator.calculateBBBSets(
                trainingMax: tm.weight,
                bbbPercentage: settings.bbbPercentage,
                availablePlates: settings.availablePlates,
                barWeight: settings.barWeight
            )

            for set in bbbSets {
                let workoutSet = WorkoutSet(
                    setNumber: setIndex,
                    targetWeight: set.weight,
                    targetReps: set.reps,
                    isAMRAP: false,
                    isBBB: true,
                    isWarmup: false
                )
                workoutSet.workout = workout
                workout.addSet(workoutSet)
                setIndex += 1
            }
        }

        return workout
    }

    func completeSet(_ set: WorkoutSet, reps: Int, settings: AppSettings) {
        set.complete(reps: reps)

        // Check for workout completion
        if let workout = currentWorkout {
            let allComplete = (workout.sets ?? []).allSatisfy { $0.isComplete }
            if allComplete {
                workout.isComplete = true
            }
        }

        try? modelContext?.save()
    }

    func checkAndUpdateProgression(
        after workout: Workout,
        trainingMaxes: [TrainingMax],
        progress: CycleProgress,
        prs: [PersonalRecord]
    ) -> (newTMs: [LiftType: Double], newPRs: [(LiftType, PersonalRecord)])? {
        guard workout.weekNumber == 3,
              workout.isComplete,
              let amrapSet = workout.amrapSet,
              let actualReps = amrapSet.actualReps else {
            return nil
        }

        // Calculate estimated 1RM using Epley formula
        let estimated1RM = WendlerCalculator.estimatedOneRepMax(
            weight: amrapSet.targetWeight,
            reps: actualReps
        )

        // Calculate new training max (90% of e1RM)
        let newTM = WendlerCalculator.newTrainingMax(from: estimated1RM)

        // Get current TM
        guard let currentTM = trainingMaxes.first(where: { $0.liftType == workout.liftType }) else {
            return nil
        }

        var result: [LiftType: Double] = [:]
        var newPRsList: [(LiftType, PersonalRecord)] = []

        // Only update if new TM is higher (no regression)
        if newTM > currentTM.weight {
            result[workout.liftType] = newTM
        }

        // Check for PR
        let currentPR = prs
            .filter { $0.liftType == workout.liftType }
            .max { $0.estimated1RM < $1.estimated1RM }

        if currentPR == nil || estimated1RM > currentPR!.estimated1RM {
            let newPR = PersonalRecord(
                liftType: workout.liftType,
                weight: amrapSet.targetWeight,
                reps: actualReps,
                workoutSetId: amrapSet.id
            )
            newPRsList.append((workout.liftType, newPR))
        }

        return (result, newPRsList)
    }

    func applyNewTrainingMaxes(_ newTMs: [LiftType: Double], to trainingMaxes: [TrainingMax]) {
        for (liftType, weight) in newTMs {
            if let tm = trainingMaxes.first(where: { $0.liftType == liftType }) {
                tm.weight = weight
                tm.updatedAt = Date()
            }
        }
        try? modelContext?.save()
    }
}
