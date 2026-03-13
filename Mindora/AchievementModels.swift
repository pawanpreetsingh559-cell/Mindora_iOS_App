import Foundation

enum AchievementCategory: String, CaseIterable, Codable, Sendable {
    case growth = "Growth"
    case streak = "Streak"
    case butterfly = "Butterfly"
    case sessions = "Sessions"
    case mindfulness = "Mindfulness"
    case garden = "Garden"
    case points = "Points"
    case user = "User"
}

enum AchievementStatus: String, Codable, Sendable {
    case locked
    case inProgress
    case completed
}

enum GrowthStage: String, Codable, Sendable {
    case egg = "Egg"
    case caterpillar = "Caterpillar"
    case cocoon = "Cocoon"
    case butterfly = "Butterfly"
    
    var icon: String {
        switch self {
        case .egg: return "circle.fill"
        case .caterpillar: return "circle.grid.cross.fill"
        case .cocoon: return "oval.fill"
        case .butterfly: return "ladybug.fill"
        }
    }
}

struct Achievement: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: AchievementCategory
    let requiredValue: Int
    var currentValue: Int
    var isUnlocked: Bool
    var dateUnlocked: Date? = nil
    var isSecret: Bool = false
    
    var progress: Float {
        guard requiredValue > 0 else { return 1.0 }
        return min(Float(currentValue) / Float(requiredValue), 1.0)
    }
    
    var status: AchievementStatus {
        if isUnlocked || currentValue >= requiredValue {
            return .completed
        } else if currentValue > 0 {
            return .inProgress
        } else {
            return .locked
        }
    }
    
    var iconName: String {
        switch id {
        // Growth
        case "growth_egg": return "circle"
        case "growth_caterpillar": return "leaf"
        case "growth_cocoon": return "capsule.fill"
        case "growth_butterfly": return "sparkles"
            
        // Streak
        case "streak_3":  return "flame"
        case "streak_7":  return "flame.fill"
        case "streak_30": return "shield.fill"
        case "streak_60": return "crown.fill"
            
        // Butterfly
        case "butterfly_5":  return "ladybug"
        case "butterfly_15": return "ladybug.fill"
        case "butterfly_30": return "sparkles"
        case "butterfly_60": return "crown.fill"
            
        // Sessions
        case "session_10": return "figure.mind.and.body"
        case "session_20": return "waveform.path.ecg"
        case "session_40": return "brain.head.profile"
        case "session_80": return "sparkles"
            
        // Mindfulness
        case "mind_double": return "figure.mind.and.body"
        case "mind_triple": return "brain.head.profile"
        case "mind_deep": return "lungs.fill"
        case "mind_4": return "waveform.path.ecg"
            
        // Garden (6 tiers: 1, 10, 25, 50, 75, 100)
        case "garden_1":   return "leaf"
        case "garden_10":  return "sprout.fill"
        case "garden_25":  return "leaf.circle.fill"
        case "garden_50":  return "tree.fill"
        case "garden_75":  return "camera.macro"
        case "garden_100": return "sparkles"
            
        // Points
        case "points_200": return "star"
        case "points_350": return "star.leadinghalf.filled"
        case "points_600": return "star.fill"
        case "points_800": return "star.circle"
        case "points_1200": return "star.circle.fill"
        case "points_2000": return "sparkles"
            
        // User
        case "user_login": return "house.fill"
            
        default:
            switch category {
            case .growth:      return "leaf.fill"
            case .streak:      return "flame.fill"
            case .butterfly:   return "ladybug.fill"
            case .points:      return "star.fill"
            case .user:        return "person.circle.fill"
            case .sessions:    return "figure.mind.and.body"
            case .mindfulness: return "brain.head.profile"
            case .garden:      return "tree.fill"
            }
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(currentValue)
        hasher.combine(isUnlocked)
    }
    
    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        return lhs.id == rhs.id && lhs.currentValue == rhs.currentValue && lhs.isUnlocked == rhs.isUnlocked
    }
}
