import Foundation
import SwiftData

/// Categories for organizing exercises in the library
enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case chest = "chest"
    case back = "back"
    case legs = "legs"
    case shoulders = "shoulders"
    case arms = "arms"
    case core = "core"
    
    var id: String { rawValue }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .legs: return "Legs"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .core: return "Core"
        }
    }
}

/// Represents an exercise item in the library that users can search and add to their programs
/// This is separate from the Exercise model which represents exercises within a specific workout day
@Model
final class ExerciseLibraryItem {
    var id: UUID
    var name: String
    var category: ExerciseCategory
    var type: ExerciseType
    var isCustom: Bool
    
    init(id: UUID = UUID(), name: String, category: ExerciseCategory, type: ExerciseType, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.type = type
        self.isCustom = isCustom
    }
}
