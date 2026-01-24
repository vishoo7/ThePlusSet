import XCTest
@testable import ThePlusSet

final class PlateCalculatorTests: XCTestCase {

    let standardPlates = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5]
    let barWeight = 45.0

    // MARK: - Plates Per Side Tests

    func testPlatesPerSideEmptyBar() {
        let plates = PlateCalculator.platesPerSide(
            targetWeight: 45,
            availablePlates: standardPlates,
            barWeight: barWeight
        )
        XCTAssertEqual(plates, [])
    }

    func testPlatesPerSideSingle45() {
        // 135 lbs = bar (45) + 45 per side
        let plates = PlateCalculator.platesPerSide(
            targetWeight: 135,
            availablePlates: standardPlates,
            barWeight: barWeight
        )
        XCTAssertEqual(plates, [45])
    }

    func testPlatesPerSide225() {
        // 225 lbs = bar (45) + 90 per side = 45 + 45
        let plates = PlateCalculator.platesPerSide(
            targetWeight: 225,
            availablePlates: standardPlates,
            barWeight: barWeight
        )
        XCTAssertEqual(plates, [45, 45])
    }

    func testPlatesPerSide315() {
        // 315 lbs = bar (45) + 135 per side = 45 + 45 + 45
        let plates = PlateCalculator.platesPerSide(
            targetWeight: 315,
            availablePlates: standardPlates,
            barWeight: barWeight
        )
        XCTAssertEqual(plates, [45, 45, 45])
    }

    func testPlatesPerSideMixedPlates() {
        // 185 lbs = bar (45) + 70 per side = 45 + 25
        let plates = PlateCalculator.platesPerSide(
            targetWeight: 185,
            availablePlates: standardPlates,
            barWeight: barWeight
        )
        XCTAssertEqual(plates, [45, 25])
    }

    func testPlatesPerSideWithSmallPlates() {
        // 150 lbs = bar (45) + 52.5 per side = 45 + 5 + 2.5
        let plates = PlateCalculator.platesPerSide(
            targetWeight: 150,
            availablePlates: standardPlates,
            barWeight: barWeight
        )
        XCTAssertEqual(plates, [45, 5, 2.5])
    }

    func testPlatesPerSideWeightBelowBar() {
        let plates = PlateCalculator.platesPerSide(
            targetWeight: 30,
            availablePlates: standardPlates,
            barWeight: barWeight
        )
        XCTAssertEqual(plates, [])
    }

    // MARK: - Round To Nearest Loadable Tests

    func testRoundToNearestLoadableExact() {
        // 135 is exactly loadable
        let result = PlateCalculator.roundToNearestLoadable(
            weight: 135,
            availablePlates: standardPlates,
            barWeight: barWeight
        )
        XCTAssertEqual(result, 135)
    }

    func testRoundToNearestLoadableRoundsUp() {
        // 138 should round to 140 (nearest 5 lb increment)
        // 138 - 45 = 93, 93/5 = 18.6, rounds to 19, 19*5 = 95, total = 140
        let result = PlateCalculator.roundToNearestLoadable(
            weight: 138,
            availablePlates: standardPlates,
            barWeight: barWeight
        )
        XCTAssertEqual(result, 140)
    }

    func testRoundToNearestLoadableRoundsDown() {
        // 132 should round to 130
        let result = PlateCalculator.roundToNearestLoadable(
            weight: 132,
            availablePlates: standardPlates,
            barWeight: barWeight
        )
        XCTAssertEqual(result, 130)
    }

    func testRoundToNearestLoadableBelowBar() {
        // Weight below bar weight should return bar weight
        let result = PlateCalculator.roundToNearestLoadable(
            weight: 30,
            availablePlates: standardPlates,
            barWeight: barWeight
        )
        XCTAssertEqual(result, barWeight)
    }

    func testRoundToNearestLoadableWithDifferentSmallestPlate() {
        // With only 10 lb plates as smallest, increment is 20
        let plates = [45.0, 25.0, 10.0]
        let result = PlateCalculator.roundToNearestLoadable(
            weight: 137,
            availablePlates: plates,
            barWeight: barWeight
        )
        // 137 - 45 = 92, rounded to nearest 20 = 100, total = 145
        XCTAssertEqual(result, 145)
    }

    // MARK: - Format Plates Tests

    func testFormatPlatesEmpty() {
        let result = PlateCalculator.formatPlates([])
        XCTAssertEqual(result, "Empty bar")
    }

    func testFormatPlatesSingle() {
        let result = PlateCalculator.formatPlates([45])
        XCTAssertEqual(result, "45")
    }

    func testFormatPlatesMultipleDifferent() {
        let result = PlateCalculator.formatPlates([45, 25, 10])
        XCTAssertEqual(result, "45 + 25 + 10")
    }

    func testFormatPlatesMultipleSame() {
        let result = PlateCalculator.formatPlates([45, 45])
        XCTAssertEqual(result, "45×2")
    }

    func testFormatPlatesMixed() {
        let result = PlateCalculator.formatPlates([45, 45, 25, 10, 10])
        XCTAssertEqual(result, "45×2 + 25 + 10×2")
    }

    func testFormatPlatesWithDecimals() {
        let result = PlateCalculator.formatPlates([45, 2.5])
        XCTAssertEqual(result, "45 + 2.5")
    }

    // MARK: - Format Weight Tests

    func testFormatWeightWholeNumber() {
        let result = PlateCalculator.formatWeight(45)
        XCTAssertEqual(result, "45")
    }

    func testFormatWeightWithDecimal() {
        let result = PlateCalculator.formatWeight(2.5)
        XCTAssertEqual(result, "2.5")
    }

    func testFormatWeightRoundsDecimal() {
        let result = PlateCalculator.formatWeight(135.0)
        XCTAssertEqual(result, "135")
    }

    func testFormatWeightLargeNumber() {
        let result = PlateCalculator.formatWeight(405)
        XCTAssertEqual(result, "405")
    }
}
