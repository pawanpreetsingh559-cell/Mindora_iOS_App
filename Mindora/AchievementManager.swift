import Foundation
import UIKit
import Supabase

class AchievementManager {
    static let shared = AchievementManager()

    // MARK: - Achievements List (in-memory only, synced to Supabase)
    var achievements: [Achievement] = [] {
        didSet { syncAchievementsToSupabase() }
    }

    // MARK: - Init
    private init() {
        loadAchievements()
    }

    // MARK: - Public API

    /// Unlock an achievement by its ID. Posts .achievementUnlocked notification.
    func unlock(id: String) {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return }
        guard !achievements[index].isUnlocked else { return }
        achievements[index].isUnlocked = true
        achievements[index].currentValue = achievements[index].requiredValue
        achievements[index].dateUnlocked = Date()
        NotificationCenter.default.post(name: .achievementUnlocked, object: achievements[index])
    }

    /// Update the current progress value for an achievement (does NOT auto-unlock).
    func setProgress(id: String, value: Int) {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return }
        achievements[index].currentValue = value
    }

    /// Lock an achievement again (e.g. for testing/reset).
    func lock(id: String) {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return }
        achievements[index].isUnlocked = false
        achievements[index].currentValue = 0
        achievements[index].dateUnlocked = nil
    }

    /// Reset all achievements to their default locked state.
    func resetAll() {
        achievements = defaultAchievements()
    }

    // MARK: - Load (Supabase then defaults)
    
    private func loadAchievements() {
        // Start with defaults
        self.achievements = defaultAchievements()
        
        // Fetch from Supabase in background
        fetchAchievementsFromSupabase()
    }
    
    // MARK: - Supabase Achievement Sync
    
    private func fetchAchievementsFromSupabase() {
        Task {
            do {
                let session = try await supabase.auth.session
                let userId = session.user.id.uuidString
                
                struct AchievementRow: Codable {
                    let achievement_id: String
                    let current_value: Int
                    let is_unlocked: Bool
                    let date_unlocked: String?
                }
                
                let rows: [AchievementRow] = try await supabase
                    .from("achievements")
                    .select()
                    .eq("user_id", value: userId)
                    .execute()
                    .value
                
                if !rows.isEmpty {
                    let savedMap = Dictionary(rows.map { ($0.achievement_id, $0) }, uniquingKeysWith: { first, _ in first })
                    var list = self.defaultAchievements()
                    
                    let dateFormatter = ISO8601DateFormatter()
                    
                    for (i, item) in list.enumerated() {
                        if let saved = savedMap[item.id] {
                            list[i].isUnlocked = saved.is_unlocked
                            list[i].currentValue = saved.current_value
                            if let dateStr = saved.date_unlocked {
                                list[i].dateUnlocked = dateFormatter.date(from: dateStr)
                            }
                        }
                    }
                    
                    await MainActor.run {
                        self.achievements = list
                    }
                }
            } catch {
                print("[Supabase] Achievements fetch failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func syncAchievementsToSupabase() {
        Task {
            do {
                let session = try await supabase.auth.session
                let userId = session.user.id.uuidString
                
                let dateFormatter = ISO8601DateFormatter()
                
                for achievement in achievements {
                    let row: [String: AnyJSON] = [
                        "user_id": AnyJSON(stringLiteral: userId),
                        "achievement_id": AnyJSON(stringLiteral: achievement.id),
                        "current_value": AnyJSON(integerLiteral: achievement.currentValue),
                        "is_unlocked": AnyJSON(booleanLiteral: achievement.isUnlocked),
                        "date_unlocked": achievement.dateUnlocked.map { AnyJSON(stringLiteral: dateFormatter.string(from: $0)) } ?? AnyJSON.null
                    ]
                    
                    try await supabase
                        .from("achievements")
                        .upsert(row, onConflict: "user_id,achievement_id")
                        .execute()
                }
            } catch {
                print("[Supabase] Achievements sync failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Default Achievement Definitions
    private func defaultAchievements() -> [Achievement] {
        return [
            // --- Growth (Life Stage Milestones) ---
            Achievement(id: "growth_egg",         title: "First Egg",        description: "You completed your very first session. A tiny egg of potential has appeared in your garden — your journey of transformation begins here. Every great butterfly starts exactly like this.",                                                                    category: .growth, requiredValue: 1,  currentValue: 0, isUnlocked: false),
            Achievement(id: "growth_caterpillar", title: "Caterpillar Born",  description: "You've been showing up consistently. Like a caterpillar beginning its slow, determined crawl, you are building momentum — one session, one breath, one moment at a time.",                                                      category: .growth, requiredValue: 2,  currentValue: 0, isUnlocked: false),
            Achievement(id: "growth_cocoon",      title: "Into the Cocoon",   description: "You've reached a turning point. Inside the cocoon, the most profound changes happen in silence and stillness — invisible to the world, but deeply real. Your dedication is reshaping you from within.",                                                             category: .growth, requiredValue: 3,  currentValue: 0, isUnlocked: false),
            Achievement(id: "growth_butterfly",   title: "Butterfly Emerges", description: "You've broken free. What began as a single session has blossomed into a true practice of mindfulness. You are no longer just trying — you are transforming. Spread your wings.",                                                                   category: .growth, requiredValue: 4,  currentValue: 0, isUnlocked: false),

            // --- Streak ---
            Achievement(id: "streak_3",  title: "Spark of Habit",  description: "Three days in a row — the spark that starts a fire. You showed up when it mattered.",                                                  category: .streak, requiredValue: 3,   currentValue: 0, isUnlocked: false),
            Achievement(id: "streak_7",  title: "Weekly Warrior",  description: "Seven days of unbroken focus. A full week of choosing yourself — that's real strength.",                                               category: .streak, requiredValue: 7,   currentValue: 0, isUnlocked: false),
            Achievement(id: "streak_30", title: "Monthly Master",  description: "Thirty days of dedication. What started as a habit is now becoming part of who you are.",                                              category: .streak, requiredValue: 30,  currentValue: 0, isUnlocked: false),
            Achievement(id: "streak_60", title: "Unbreakable",     description: "Sixty days without breaking. You've crossed the line from discipline into identity. This is who you are now.",                         category: .streak, requiredValue: 60,  currentValue: 0, isUnlocked: false),

            // --- Butterfly Milestones ---
            Achievement(id: "butterfly_5",  title: "Flutter",           description: "5 butterflies collected. Your garden is beginning to come alive with wings and wonder.",                                    category: .butterfly, requiredValue: 5,  currentValue: 0, isUnlocked: false),
            Achievement(id: "butterfly_15", title: "Swarm of Grace",    description: "15 butterflies. They gather around you now — a living testament to your patience and care.",                              category: .butterfly, requiredValue: 15, currentValue: 0, isUnlocked: false),
            Achievement(id: "butterfly_30", title: "Butterfly Garden",  description: "30 butterflies. Your inner world has become a sanctuary — a place where beauty returns again and again.",               category: .butterfly, requiredValue: 30, currentValue: 0, isUnlocked: false),
            Achievement(id: "butterfly_60", title: "Monarch of Calm",   description: "60 butterflies. You have become the monarch — a rare soul who has transformed stillness into something extraordinary.",  category: .butterfly, requiredValue: 60, currentValue: 0, isUnlocked: false),

            // --- Sessions ---
            Achievement(id: "session_10", title: "First Steps",       description: "10 sessions completed. You have taken your first real steps on the path inward. The journey has begun — and it is already changing you.",                                                    category: .sessions, requiredValue: 10, currentValue: 0, isUnlocked: false),
            Achievement(id: "session_20", title: "Steady Rhythm",     description: "20 sessions. A rhythm is forming. Like breathing itself, you are finding your natural pace — steady, consistent, and deeply yours.",                                                          category: .sessions, requiredValue: 20, currentValue: 0, isUnlocked: false),
            Achievement(id: "session_40", title: "Deep Commitment",   description: "40 sessions of inner work. This is no longer a habit — it is a promise you keep to yourself. Your commitment runs deeper than words.",                                                          category: .sessions, requiredValue: 40, currentValue: 0, isUnlocked: false),
            Achievement(id: "session_80", title: "Mindful Master",    description: "80 sessions. You have crossed into mastery. What once required effort now flows naturally. You are not just practicing mindfulness — you are living it.",                                       category: .sessions, requiredValue: 80, currentValue: 0, isUnlocked: false),

            // --- Mindfulness Depth ---
            Achievement(id: "mind_double", title: "Double Calm",   description: "Two sessions in one day. You returned to stillness twice — that is not habit, that is devotion.",                                                                    category: .mindfulness, requiredValue: 2, currentValue: 0, isUnlocked: false),
            Achievement(id: "mind_triple", title: "Triple Focus",  description: "Three sessions in a single day. Your mind sought peace three times today. You are building something extraordinary.",                                                 category: .mindfulness, requiredValue: 3, currentValue: 0, isUnlocked: false),
            Achievement(id: "mind_4",      title: "Deep Presence", description: "Four sessions in one day. You are no longer just practicing mindfulness — you are living it, breath by breath, moment by moment.",                                    category: .mindfulness, requiredValue: 4, currentValue: 0, isUnlocked: false),
            Achievement(id: "mind_deep",   title: "Deep Reset",    description: "Five sessions in 24 hours. You dove deep into the well of calm. Few ever go this far — you did it in a single day.",                                                 category: .mindfulness, requiredValue: 5, currentValue: 0, isUnlocked: false),

            // --- Garden (6 Tiers) ---
            Achievement(id: "garden_1",   title: "First Seed",     description: "You planted your first seed of calm. Every great garden starts with one.",                   category: .garden, requiredValue: 1,   currentValue: 0, isUnlocked: false),
            Achievement(id: "garden_10",  title: "Sprouting Life", description: "Ten gardens tended. Your dedication is beginning to take root.",                              category: .garden, requiredValue: 10,  currentValue: 0, isUnlocked: false),
            Achievement(id: "garden_25",  title: "Blooming Garden",description: "Twenty-five gardens nurtured. Your inner world is flourishing with color.",                   category: .garden, requiredValue: 25,  currentValue: 0, isUnlocked: false),
            Achievement(id: "garden_50",  title: "Ancient Grove",  description: "Fifty gardens grown. You have cultivated something truly beautiful.",                         category: .garden, requiredValue: 50,  currentValue: 0, isUnlocked: false),
            Achievement(id: "garden_75",  title: "Forest Keeper",  description: "Seventy-five gardens. You are the guardian of a thriving inner forest.",                      category: .garden, requiredValue: 75,  currentValue: 0, isUnlocked: false),
            Achievement(id: "garden_100", title: "Eden",           description: "One hundred gardens. You have built a paradise of peace within yourself.",                    category: .garden, requiredValue: 100, currentValue: 0, isUnlocked: false),

            // --- Points ---
            Achievement(id: "points_200",  title: "Calm Builder",       description: "Two hundred points earned. You are building a foundation of peace, one session at a time.",                          category: .points, requiredValue: 200,  currentValue: 0, isUnlocked: false),
            Achievement(id: "points_350",  title: "Mind Strengthening", description: "350 points of pure dedication. Your mind is growing stronger with every breath.",                                    category: .points, requiredValue: 350,  currentValue: 0, isUnlocked: false),
            Achievement(id: "points_600",  title: "Growth Accelerator", description: "600 points. You have moved beyond beginner — this is where real transformation begins.",                             category: .points, requiredValue: 600,  currentValue: 0, isUnlocked: false),
            Achievement(id: "points_800",  title: "Inner Stability",    description: "800 points of inner work. You have found a stillness that the world cannot shake.",                                  category: .points, requiredValue: 800,  currentValue: 0, isUnlocked: false),
            Achievement(id: "points_1200", title: "Serenity Architect", description: "1200 points. You are no longer just practicing mindfulness — you are designing your life around it.",                category: .points, requiredValue: 1200, currentValue: 0, isUnlocked: false),
            Achievement(id: "points_2000", title: "Mindora Champion",   description: "2000 points. You have reached the summit. A true champion of mind, breath, and spirit.",                            category: .points, requiredValue: 2000, currentValue: 0, isUnlocked: false),

            // --- User ---
            Achievement(id: "user_login", title: "Welcome Home",
                        description: "You opened the door and stepped inside. This is where your journey begins — a space built just for you, waiting to grow with every session.",
                        category: .user, requiredValue: 1, currentValue: 1, isUnlocked: true),
        ]
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}
