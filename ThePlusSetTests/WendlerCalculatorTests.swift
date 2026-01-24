import XCTest
@testable import ThePlusSet

final class WendlerCalculatorTests: XCTestCase {

    // MARK: - Week Percentages Tests

    func testWeek1Percentages() {
        let percentages = WendlerCalculator.percentagesForWeek(1)
        XCTAssertEqual(percentages, [0.65, 0.75, 0.85])
    }

    func testWeek2Percentages() {
        let percentages = WendlerCalculator.percentagesForWeek(2)
        XCTAssertEqual(percentages, [0.70, 0.80, 0.90])
    }

    func testWeek3Percentages() {
        let percentages = WendlerCalculator.percentagesForWeek(3)
        XCTAssertEqual(percentages, [0.75, 0.85, 0.95])
    }

    func testWeek4DeloadPercentages() {
        let percentages = WendlerCalculator.percentagesForWeek(4)
        XCTAssertEqual(percentages, [0.40, 0.50, 0.60])
    }

    func testInvalidWeekDefaultsToWeek1() {
        let percentages = WendlerCalculator.percentagesForWeek(99)
        XCTAssertEqual(percentages, WendlerCalculator.week1Percentages)
    }

    // MARK: - Week Reps Tests

    func testWeek1Reps() {
        let reps = WendlerCalculator.repsForWeek(1)
        XCTAssertEqual(reps, [5, 5, 5])
    }

    func testWeek2Reps() {
        let reps = WendlerCalculator.repsForWeek(2)
        XCTAssertEqual(reps, [3, 3, 3])
    }

    func testWeek3Reps() {
        let reps = WendlerCalculator.repsForWeek(3)
        XCTAssertEqual(reps, [5, 3, 1])
    }

    func testWeek4DeloadReps() {
        let reps = WendlerCalculator.repsForWeek(4)
        XCTAssertEqual(reps, [5, 5, 5])
    }

    // MARK: - AMRAP Tests

    func testAMRAPIsLastSetWeeks1Through3() {
        // Week 1-3: last set (index 2) should be AMRAP
        XCTAssertFalse(WendlerCalculator.isAMRAPSet(week: 1, setIndex: 0))
        XCTAssertFalse(WendlerCalculator.isAMRAPSet(week: 1, setIndex: 1))
        XCTAssertTrue(WendlerCalculator.isAMRAPSet(week: 1, setIndex: 2))

        XCTAssertTrue(WendlerCalculator.isAMRAPSet(week: 2, setIndex: 2))
        XCTAssertTrue(WendlerCalculator.isAMRAPSet(week: 3, setIndex: 2))
    }

    func testNoAMRAPOnDeloadWeek() {
        XCTAssertFalse(WendlerCalculator.isAMRAPSet(week: 4, setIndex: 0))
        XCTAssertFalse(WendlerCalculator.isAMRAPSet(week: 4, setIndex: 1))
        XCTAssertFalse(WendlerCalculator.isAMRAPSet(week: 4, setIndex: 2))
    }

    // MARK: - Estimated 1RM Tests (Epley Formula)

    func testEstimated1RMWithSingleRep() {
        // 1 rep should return the weight itself
        let result = WendlerCalculator.estimatedOneRepMax(weight: 300, reps: 1)
        XCTAssertEqual(result, 300)
    }

    func testEstimated1RMWithZeroReps() {
        // 0 reps should return the weight itself
        let result = WendlerCalculator.estimatedOneRepMax(weight: 300, reps: 0)
        XCTAssertEqual(result, 300)
    }

    func testEstimated1RMWithMultipleReps() {
        // Epley: 1RM = weight × (1 + reps/30)
        // 225 × (1 + 10/30) = 225 × 1.333... = 300
        let result = WendlerCalculator.estimatedOneRepMax(weight: 225, reps: 10)
        XCTAssertEqual(result, 300, accuracy: 0.01)
    }

    func testEstimated1RMWith5Reps() {
        // 285 × (1 + 5/30) = 285 × 1.1667 = 332.5
        let result = WendlerCalculator.estimatedOneRepMax(weight: 285, reps: 5)
        XCTAssertEqual(result, 332.5, accuracy: 0.01)
    }

    // MARK: - New Training Max Tests

    func testNewTrainingMaxDefault90Percent() {
        // Default TM percentage is 90%
        let estimated1RM = 400.0
        let newTM = WendlerCalculator.newTrainingMax(from: estimated1RM)
        XCTAssertEqual(newTM, 360, accuracy: 0.01)
    }

    func testNewTrainingMaxCustomPercentage() {
        let estimated1RM = 400.0
        let newTM = WendlerCalculator.newTrainingMax(from: estimated1RM, tmPercentage: 0.85)
        XCTAssertEqual(newTM, 340, accuracy: 0.01)
    }

    // MARK: - Main Sets Calculation Tests

    func testCalculateMainSetsWeek1() {
        let trainingMax = 300.0
        let plates = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5]
        let barWeight = 45.0

        let sets = WendlerCalculator.calculateMainSets(
            trainingMax: trainingMax,
            week: 1,
            availablePlates: plates,
            barWeight: barWeight
        )

        XCTAssertEqual(sets.count, 3)

        // Set 1: 65% of 300 = 195
        XCTAssertEqual(sets[0].reps, 5)
        XCTAssertFalse(sets[0].isAMRAP)

        // Set 2: 75% of 300 = 225
        XCTAssertEqual(sets[1].reps, 5)
        XCTAssertFalse(sets[1].isAMRAP)

        // Set 3: 85% of 300 = 255 (AMRAP)
        XCTAssertEqual(sets[2].reps, 5)
        XCTAssertTrue(sets[2].isAMRAP)
    }

    // MARK: - BBB Sets Tests

    func testCalculateBBBSets() {
        let trainingMax = 300.0
        let bbbPercentage = 0.50
        let plates = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5]
        let barWeight = 45.0

        let sets = WendlerCalculator.calculateBBBSets(
            trainingMax: trainingMax,
            bbbPercentage: bbbPercentage,
            availablePlates: plates,
            barWeight: barWeight
        )

        XCTAssertEqual(sets.count, 5)

        // All sets should be 10 reps
        for set in sets {
            XCTAssertEqual(set.reps, 10)
        }

        // All sets should have same weight (50% of 300 = 150, rounded)
        let firstWeight = sets[0].weight
        for set in sets {
            XCTAssertEqual(set.weight, firstWeight)
        }
    }

    // MARK: - Warmup Sets Tests

    func testCalculateWarmupSets() {
        let trainingMax = 300.0
        let plates = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5]
        let barWeight = 45.0

        let sets = WendlerCalculator.calculateWarmupSets(
            trainingMax: trainingMax,
            availablePlates: plates,
            barWeight: barWeight
        )

        XCTAssertEqual(sets.count, 3)

        // Set 1: 40% x 5
        XCTAssertEqual(sets[0].reps, 5)

        // Set 2: 50% x 5
        XCTAssertEqual(sets[1].reps, 5)

        // Set 3: 60% x 3
        XCTAssertEqual(sets[2].reps, 3)
    }
}
