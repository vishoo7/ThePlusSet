import XCTest
@testable import ThePlusSet

final class CycleProgressTests: XCTestCase {

    // MARK: - Initial State

    func testInitialState() {
        let progress = CycleProgress()
        XCTAssertEqual(progress.cycleNumber, 1)
        XCTAssertEqual(progress.currentWeek, 1)
        XCTAssertEqual(progress.currentDay, 0)
    }

    // MARK: - Advance Tests

    func testAdvanceWithinWeek() {
        let progress = CycleProgress()
        progress.advanceToNextWorkout()
        XCTAssertEqual(progress.cycleNumber, 1)
        XCTAssertEqual(progress.currentWeek, 1)
        XCTAssertEqual(progress.currentDay, 1)
    }

    func testAdvanceToDay3() {
        let progress = CycleProgress()
        progress.advanceToNextWorkout() // D1
        progress.advanceToNextWorkout() // D2
        progress.advanceToNextWorkout() // D3
        XCTAssertEqual(progress.cycleNumber, 1)
        XCTAssertEqual(progress.currentWeek, 1)
        XCTAssertEqual(progress.currentDay, 3)
    }

    func testAdvanceAcrossWeekBoundary() {
        let progress = CycleProgress()
        // Advance through all 4 days of week 1
        for _ in 0..<4 {
            progress.advanceToNextWorkout()
        }
        XCTAssertEqual(progress.cycleNumber, 1)
        XCTAssertEqual(progress.currentWeek, 2)
        XCTAssertEqual(progress.currentDay, 0)
    }

    func testAdvanceAcrossCycleBoundary() {
        let progress = CycleProgress()
        // Advance through all 4 weeks × 4 days = 16 workouts
        for _ in 0..<16 {
            progress.advanceToNextWorkout()
        }
        XCTAssertEqual(progress.cycleNumber, 2)
        XCTAssertEqual(progress.currentWeek, 1)
        XCTAssertEqual(progress.currentDay, 0)
    }

    func testAdvanceFullCycleWeekByWeek() {
        let progress = CycleProgress()

        // End of week 1
        for _ in 0..<4 { progress.advanceToNextWorkout() }
        XCTAssertEqual(progress.currentWeek, 2)
        XCTAssertEqual(progress.currentDay, 0)

        // End of week 2
        for _ in 0..<4 { progress.advanceToNextWorkout() }
        XCTAssertEqual(progress.currentWeek, 3)
        XCTAssertEqual(progress.currentDay, 0)

        // End of week 3
        for _ in 0..<4 { progress.advanceToNextWorkout() }
        XCTAssertEqual(progress.currentWeek, 4)
        XCTAssertEqual(progress.currentDay, 0)

        // End of week 4 (deload) → new cycle
        for _ in 0..<4 { progress.advanceToNextWorkout() }
        XCTAssertEqual(progress.cycleNumber, 2)
        XCTAssertEqual(progress.currentWeek, 1)
        XCTAssertEqual(progress.currentDay, 0)
    }

    // MARK: - Rewind Tests

    func testRewindWithinWeek() {
        let progress = CycleProgress()
        progress.currentDay = 3
        progress.rewindToPreviousWorkout()
        XCTAssertEqual(progress.cycleNumber, 1)
        XCTAssertEqual(progress.currentWeek, 1)
        XCTAssertEqual(progress.currentDay, 2)
    }

    func testRewindAcrossWeekBoundary() {
        let progress = CycleProgress()
        progress.currentWeek = 2
        progress.currentDay = 0
        progress.rewindToPreviousWorkout()
        XCTAssertEqual(progress.cycleNumber, 1)
        XCTAssertEqual(progress.currentWeek, 1)
        XCTAssertEqual(progress.currentDay, 3)
    }

    func testRewindAcrossCycleBoundary() {
        let progress = CycleProgress()
        progress.cycleNumber = 2
        progress.currentWeek = 1
        progress.currentDay = 0
        progress.rewindToPreviousWorkout()
        XCTAssertEqual(progress.cycleNumber, 1)
        XCTAssertEqual(progress.currentWeek, 4)
        XCTAssertEqual(progress.currentDay, 3)
    }

    func testRewindAtAbsoluteStart() {
        // Edge case: rewinding at C1W1D0 shouldn't go to cycle 0
        let progress = CycleProgress()
        progress.rewindToPreviousWorkout()
        XCTAssertEqual(progress.cycleNumber, 1) // max(1, 0) = 1
        XCTAssertEqual(progress.currentWeek, 4)
        XCTAssertEqual(progress.currentDay, 3)
    }

    func testRewindFromWeek3ToWeek2() {
        let progress = CycleProgress()
        progress.currentWeek = 3
        progress.currentDay = 0
        progress.rewindToPreviousWorkout()
        XCTAssertEqual(progress.currentWeek, 2)
        XCTAssertEqual(progress.currentDay, 3)
    }

    func testRewindFromWeek4ToWeek3() {
        let progress = CycleProgress()
        progress.currentWeek = 4
        progress.currentDay = 0
        progress.rewindToPreviousWorkout()
        XCTAssertEqual(progress.currentWeek, 3)
        XCTAssertEqual(progress.currentDay, 3)
    }

    // MARK: - Advance + Rewind Roundtrip Tests

    func testAdvanceThenRewindIsIdentity() {
        let progress = CycleProgress()
        // Start at various positions and verify roundtrip
        let startPositions: [(Int, Int, Int)] = [
            (1, 1, 0), (1, 1, 2), (1, 1, 3),
            (1, 2, 0), (1, 3, 3), (1, 4, 0),
            (2, 1, 0), (3, 4, 3),
        ]

        for (cycle, week, day) in startPositions {
            progress.cycleNumber = cycle
            progress.currentWeek = week
            progress.currentDay = day

            progress.advanceToNextWorkout()
            progress.rewindToPreviousWorkout()

            XCTAssertEqual(progress.cycleNumber, cycle, "Cycle mismatch for start (\(cycle),\(week),\(day))")
            XCTAssertEqual(progress.currentWeek, week, "Week mismatch for start (\(cycle),\(week),\(day))")
            XCTAssertEqual(progress.currentDay, day, "Day mismatch for start (\(cycle),\(week),\(day))")
        }
    }

    func testRewindThenAdvanceIsIdentity() {
        let progress = CycleProgress()
        // Don't test C1W1D0 since rewind clamps cycle to 1
        let startPositions: [(Int, Int, Int)] = [
            (1, 1, 1), (1, 1, 3), (1, 2, 0),
            (1, 4, 3), (2, 1, 0), (2, 3, 2),
        ]

        for (cycle, week, day) in startPositions {
            progress.cycleNumber = cycle
            progress.currentWeek = week
            progress.currentDay = day

            progress.rewindToPreviousWorkout()
            progress.advanceToNextWorkout()

            XCTAssertEqual(progress.cycleNumber, cycle, "Cycle mismatch for start (\(cycle),\(week),\(day))")
            XCTAssertEqual(progress.currentWeek, week, "Week mismatch for start (\(cycle),\(week),\(day))")
            XCTAssertEqual(progress.currentDay, day, "Day mismatch for start (\(cycle),\(week),\(day))")
        }
    }

    // MARK: - Week Description Tests

    func testWeekDescriptions() {
        let progress = CycleProgress()

        progress.currentWeek = 1
        XCTAssertEqual(progress.weekDescription, "Week 1: 5/5/5+")

        progress.currentWeek = 2
        XCTAssertEqual(progress.weekDescription, "Week 2: 3/3/3+")

        progress.currentWeek = 3
        XCTAssertEqual(progress.weekDescription, "Week 3: 5/3/1+")

        progress.currentWeek = 4
        XCTAssertEqual(progress.weekDescription, "Week 4: Deload")
    }

    // MARK: - Current Lift Type Tests

    func testCurrentLiftTypeDefaultOrder() {
        let progress = CycleProgress()

        progress.currentDay = 0
        XCTAssertEqual(progress.currentLiftType, .squat)

        progress.currentDay = 1
        XCTAssertEqual(progress.currentLiftType, .bench)

        progress.currentDay = 2
        XCTAssertEqual(progress.currentLiftType, .deadlift)

        progress.currentDay = 3
        XCTAssertEqual(progress.currentLiftType, .overheadPress)
    }

    func testLiftTypeWithCustomOrder() {
        let progress = CycleProgress()
        let settings = AppSettings()
        // Set custom order: OHP, deadlift, bench, squat
        settings.exerciseOrderString = "overheadPress,deadlift,bench,squat"

        progress.currentDay = 0
        XCTAssertEqual(progress.liftType(for: settings), .overheadPress)

        progress.currentDay = 1
        XCTAssertEqual(progress.liftType(for: settings), .deadlift)

        progress.currentDay = 2
        XCTAssertEqual(progress.liftType(for: settings), .bench)

        progress.currentDay = 3
        XCTAssertEqual(progress.liftType(for: settings), .squat)
    }

    func testLiftTypeWithEmptyOrderFallsBackToDefault() {
        let progress = CycleProgress()
        let settings = AppSettings()
        settings.exerciseOrderString = ""

        progress.currentDay = 0
        XCTAssertEqual(progress.liftType(for: settings), .squat)

        progress.currentDay = 3
        XCTAssertEqual(progress.liftType(for: settings), .overheadPress)
    }

    // MARK: - Reset Cycle Tests

    func testResetCycle() {
        let progress = CycleProgress()
        progress.cycleNumber = 3
        progress.currentWeek = 4
        progress.currentDay = 2

        progress.resetCycle()

        XCTAssertEqual(progress.cycleNumber, 1)
        XCTAssertEqual(progress.currentWeek, 1)
        XCTAssertEqual(progress.currentDay, 0)
    }

    // MARK: - Multiple Cycle Advance Tests

    func testAdvanceThroughTwoCycles() {
        let progress = CycleProgress()
        // 32 workouts = 2 full cycles
        for _ in 0..<32 {
            progress.advanceToNextWorkout()
        }
        XCTAssertEqual(progress.cycleNumber, 3)
        XCTAssertEqual(progress.currentWeek, 1)
        XCTAssertEqual(progress.currentDay, 0)
    }
}
