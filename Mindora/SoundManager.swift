import UIKit
import AVFoundation

class SoundManager {
    
    static let shared = SoundManager()
    
    enum CalmingSound: String, CaseIterable {
        case meadowPeace = "Meadow Peace"
        case deepSerenity = "Deep Serenity"
        case twilightDreams = "Twilight Dreams"
        case gardenAwakening = "Garden Awakening"
        case urbanStillness = "Urban Stillness"
        
        var fileName: String {
            switch self {
            case .meadowPeace:
                return "Meadow Peace"
            case .deepSerenity:
                return "Deep Serenity"
            case .twilightDreams:
                return "Twilight Dreams"
            case .gardenAwakening:
                return "Garden Awakening"
            case .urbanStillness:
                return "Urban Stillness"
            }
        }
    }
    
    private let userDefaultsKey = "selectedCalmingSound"
    
    private init() {}
    
    // Get the selected sound (default: Meadow Peace)
    func getSelectedSound() -> CalmingSound {
        if let savedSound = UserDefaults.standard.string(forKey: userDefaultsKey),
           let sound = CalmingSound(rawValue: savedSound) {
            return sound
        }
        return .meadowPeace
    }
    
    // Save the selected sound
    func setSelectedSound(_ sound: CalmingSound) {
        UserDefaults.standard.set(sound.rawValue, forKey: userDefaultsKey)
    }
    
    // Get the file name for a sound
    func getFileName(for sound: CalmingSound) -> String {
        return sound.fileName
    }
    
    // Get all available sounds
    func getAllSounds() -> [CalmingSound] {
        return CalmingSound.allCases
    }
}
