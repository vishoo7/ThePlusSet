import Foundation

@MainActor
class WorkoutViewModel: ObservableObject {

    func generateWorkout(
        for progress: CycleProgress,
        trainingMaxes: [TrainingMax],
        settings: AppSettings,
        overrideLiftType: LiftType? = nil
    ) -> Workout {
        let liftType = overrideLiftType ?? progress.currentLiftType
        let week = progress.currentWeek

        guard let tm = trainingMaxes.first(where: { $0.liftType == liftType }) else {
            // Return an empty workout if training max is missing rather than crashing
            return Workout(liftType: liftType, cycleNumber: progress.cycleNumber, weekNumber: week)
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

        // Generate BBB sets (skip on deload week or if BBB disabled)
        if week != 4 && settings.bbbEnabled {
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
}
