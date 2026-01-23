import Foundation

struct PlateCalculator {
    /// Calculate which plates to load on each side of the bar
    static func platesPerSide(
        targetWeight: Double,
        availablePlates: [Double],
        barWeight: Double
    ) -> [Double] {
        let weightPerSide = (targetWeight - barWeight) / 2.0

        guard weightPerSide > 0 else { return [] }

        var remainingWeight = weightPerSide
        var plates: [Double] = []
        let sortedPlates = availablePlates.sorted(by: >)

        for plate in sortedPlates {
            while remainingWeight >= plate {
                plates.append(plate)
                remainingWeight -= plate
            }
        }

        return plates
    }

    /// Round a target weight to the nearest loadable weight
    static func roundToNearestLoadable(
        weight: Double,
        availablePlates: [Double],
        barWeight: Double
    ) -> Double {
        guard let smallestPlate = availablePlates.min() else { return weight }

        // Minimum increment is 2x smallest plate (one on each side)
        let increment = smallestPlate * 2

        // Round to nearest increment above bar weight
        let weightAboveBar = weight - barWeight
        let rounded = (weightAboveBar / increment).rounded() * increment

        return max(barWeight, barWeight + rounded)
    }

    /// Format plates for display (e.g., "45 + 25 + 10")
    static func formatPlates(_ plates: [Double]) -> String {
        if plates.isEmpty { return "Empty bar" }

        // Group consecutive same plates
        var formatted: [String] = []
        var currentPlate: Double? = nil
        var count = 0

        for plate in plates {
            if plate == currentPlate {
                count += 1
            } else {
                if let current = currentPlate {
                    formatted.append(count > 1 ? "\(formatWeight(current))×\(count)" : formatWeight(current))
                }
                currentPlate = plate
                count = 1
            }
        }

        if let current = currentPlate {
            formatted.append(count > 1 ? "\(formatWeight(current))×\(count)" : formatWeight(current))
        }

        return formatted.joined(separator: " + ")
    }

    /// Format weight without unnecessary decimals
    static func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", weight)
        } else {
            return String(format: "%.1f", weight)
        }
    }
}
