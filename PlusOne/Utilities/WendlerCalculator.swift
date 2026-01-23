import Foundation

struct WendlerCalculator {
    // Week percentages for main sets
    static let week1Percentages: [Double] = [0.65, 0.75, 0.85]
    static let week2Percentages: [Double] = [0.70, 0.80, 0.90]
    static let week3Percentages: [Double] = [0.75, 0.85, 0.95]
    static let deloadPercentages: [Double] = [0.40, 0.50, 0.60]

    // Target reps for each week
    static let week1Reps: [Int] = [5, 5, 5]  // 5/5/5+
    static let week2Reps: [Int] = [3, 3, 3]  // 3/3/3+
    static let week3Reps: [Int] = [5, 3, 1]  // 5/3/1+
    static let deloadReps: [Int] = [5, 5, 5]

    static func percentagesForWeek(_ week: Int) -> [Double] {
        switch week {
        case 1: return week1Percentages
        case 2: return week2Percentages
        case 3: return week3Percentages
        case 4: return deloadPercentages
        default: return week1Percentages
        }
    }

    static func repsForWeek(_ week: Int) -> [Int] {
        switch week {
        case 1: return week1Reps
        case 2: return week2Reps
        case 3: return week3Reps
        case 4: return deloadReps
        default: return week1Reps
        }
    }

    static func isAMRAPSet(week: Int, setIndex: Int) -> Bool {
        // Last main set (index 2) is AMRAP for weeks 1-3, not deload
        return setIndex == 2 && week != 4
    }

    static func calculateMainSets(
        trainingMax: Double,
        week: Int,
        availablePlates: [Double],
        barWeight: Double
    ) -> [(weight: Double, reps: Int, isAMRAP: Bool)] {
        let percentages = percentagesForWeek(week)
        let reps = repsForWeek(week)

        return zip(percentages, reps).enumerated().map { index, pair in
            let rawWeight = trainingMax * pair.0
            let roundedWeight = PlateCalculator.roundToNearestLoadable(
                weight: rawWeight,
                availablePlates: availablePlates,
                barWeight: barWeight
            )
            let isAMRAP = isAMRAPSet(week: week, setIndex: index)
            return (roundedWeight, pair.1, isAMRAP)
        }
    }

    static func calculateBBBSets(
        trainingMax: Double,
        bbbPercentage: Double,
        availablePlates: [Double],
        barWeight: Double
    ) -> [(weight: Double, reps: Int)] {
        let rawWeight = trainingMax * bbbPercentage
        let roundedWeight = PlateCalculator.roundToNearestLoadable(
            weight: rawWeight,
            availablePlates: availablePlates,
            barWeight: barWeight
        )
        // 5 sets of 10 reps
        return Array(repeating: (roundedWeight, 10), count: 5)
    }

    // Epley formula: 1RM = weight × (1 + reps/30)
    static func estimatedOneRepMax(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }

    // Calculate new training max (90% of estimated 1RM)
    static func newTrainingMax(from estimated1RM: Double) -> Double {
        return estimated1RM * 0.90
    }
}
