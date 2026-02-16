import Foundation

enum LiftType: String, Codable, CaseIterable, Identifiable {
    case squat = "Squat"
    case bench = "Bench Press"
    case deadlift = "Deadlift"
    case overheadPress = "Overhead Press"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .squat: return "SQ"
        case .bench: return "BP"
        case .deadlift: return "DL"
        case .overheadPress: return "OHP"
        }
    }

    var dayOrder: Int {
        switch self {
        case .squat: return 0
        case .bench: return 1
        case .deadlift: return 2
        case .overheadPress: return 3
        }
    }

    var storageKey: String {
        switch self {
        case .squat: return "squat"
        case .bench: return "bench"
        case .deadlift: return "deadlift"
        case .overheadPress: return "overheadPress"
        }
    }

    static func fromKey(_ key: String) -> LiftType? {
        switch key {
        case "squat": return .squat
        case "bench": return .bench
        case "deadlift": return .deadlift
        case "overheadPress": return .overheadPress
        default: return nil
        }
    }
}
