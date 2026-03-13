//
//  DataManager.swift
//  Mindora
//
//  Created by pawanpreet singh on 19/12/25.
//  Fully migrated to Supabase — no local storage.
//

import Foundation
import UIKit
import Supabase

// MARK: - Data Models

struct Quote: Codable {
    let text: String
    let author: String
}

struct AnalyticsData: Codable {
    var totalPoints: Int = 0
    var totalButterflies: Int = 0
    var currentStreak: Int = 0
    var lastSessionDate: String?
    var totalSessions: Int = 0
    var sessionCount: [String: Int] = [:]
    var completedGardens: Int = 0
    var moodHistory: [String: [Int]] = [:]
}

struct CurrentUserData: Codable {
    var name: String
    var email: String
    var isLoggedIn: Bool
    var lastLoginDate: String?
}

struct SettingsData: Codable {
    var notificationsEnabled: Bool = true
    var soundEnabled: Bool = true
    var themeMode: String = "light"
}

// MARK: - Supabase Row Models

struct ProfileRow: Codable {
    let id: String
    let name: String
    let email: String
    let created_at: String?
}

// MARK: - DataManager Class (Supabase Only)
class DataManager {
    static let shared = DataManager()
    
    // In-memory cache (populated from Supabase)
    private var currentUser: CurrentUserData?
    private var currentUserAnalytics: AnalyticsData = AnalyticsData()
    private var currentUserId: String?
    
    // Hardcoded library of quotes
    private let quoteLibrary: [Quote] = [
        Quote(text: "Every small step you take is moving you closer to your goals.", author: "Lalah Delia"),
        Quote(text: "Breathe. Let go. And remind yourself that this very moment is the only one you know you have for sure.", author: "Oprah Winfrey"),
        Quote(text: "The greatest glory in living lies not in never falling, but in rising every time we fall.", author: "Nelson Mandela"),
        Quote(text: "Your time is limited, so don't waste it living someone else's life.", author: "Steve Jobs"),
        Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
        Quote(text: "It is during our darkest moments that we must focus to see the light.", author: "Aristotle"),
        Quote(text: "Be yourself; everyone else is already taken.", author: "Oscar Wilde"),
        Quote(text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt"),
        Quote(text: "It is never too late to be what you might have been.", author: "George Eliot"),
        Quote(text: "Life is what happens when you're busy making other plans.", author: "John Lennon"),
        Quote(text: "The way to get started is to quit talking and begin doing.", author: "Walt Disney"),
        Quote(text: "Don't let yesterday take up too much of today.", author: "Will Rogers"),
        Quote(text: "You learn more from failure than from success.", author: "Unknown"),
        Quote(text: "It's not whether you get knocked down, it's whether you get up.", author: "Vince Lombardi"),
        Quote(text: "If you are working on something that you really care about, you don't have to be pushed. The vision pulls you.", author: "Steve Jobs"),
        Quote(text: "People who are crazy enough to think they can change the world, are the ones who do.", author: "Rob Siltanen"),
        Quote(text: "Failure is not the opposite of success, it is a stepping stone to success.", author: "Unknown"),
        Quote(text: "You don't have to be great to start, but you have to start to be great.", author: "Zig Ziglar"),
        Quote(text: "The only person you are destined to become is the person you decide to be.", author: "Ralph Waldo Emerson"),
        Quote(text: "Success is not how high you have climbed, but how you make a positive difference to the world.", author: "Roy T. Bennett"),
        Quote(text: "What lies behind us and what lies before us are tiny matters compared to what lies within us.", author: "Ralph Waldo Emerson"),
        Quote(text: "Act as if what you do makes a difference. It does.", author: "William James"),
        Quote(text: "Success is walking from failure to failure with no loss of enthusiasm.", author: "Winston Churchill"),
        Quote(text: "Don't watch the clock; do what it does. Keep going.", author: "Sam Levenson"),
        Quote(text: "The best time to plant a tree was 20 years ago. The second best time is now.", author: "Chinese Proverb"),
        Quote(text: "Your limitation—it's only your imagination.", author: "Unknown"),
        Quote(text: "Great things never come from comfort zones.", author: "Unknown"),
        Quote(text: "Dream it. Wish it. Do it.", author: "Unknown"),
        Quote(text: "Success doesn't just find you. You have to go out and get it.", author: "Unknown"),
        Quote(text: "The harder you work for something, the greater you'll feel when you achieve it.", author: "Unknown"),
        Quote(text: "Dream bigger. Do bigger.", author: "Unknown"),
        Quote(text: "Don't stop when you're tired. Stop when you're done.", author: "Unknown"),
        Quote(text: "Wake up with determination. Go to bed with satisfaction.", author: "Unknown"),
        Quote(text: "Do something today that your future self will thank you for.", author: "Sean Patrick Flanery"),
        Quote(text: "Little things make big days.", author: "Unknown"),
        Quote(text: "It's going to be hard, but hard does not mean impossible.", author: "Unknown"),
        Quote(text: "Don't wait for opportunity. Create it.", author: "Unknown"),
        Quote(text: "Sometimes we're tested not to show our weaknesses, but to discover our strengths.", author: "Unknown"),
        Quote(text: "The key to success is to focus on goals, not obstacles.", author: "Unknown"),
        Quote(text: "Dream it. Believe it. Build it.", author: "Unknown"),
        Quote(text: "Do something today that will kick start your future.", author: "Unknown"),
        Quote(text: "Forget all the reasons it won't work and believe the one reason that it will.", author: "Unknown"),
        Quote(text: "Successful people don't have fewer problems. They have determined that nothing will stop them from going forward.", author: "Unknown"),
        Quote(text: "Don't let a bad day make you feel like you have a bad life.", author: "Unknown"),
        Quote(text: "You can't have a better tomorrow if you keep thinking about yesterday.", author: "Unknown"),
        Quote(text: "Focus on being productive instead of busy.", author: "Tim Ferriss"),
        Quote(text: "Don't be afraid to give up the good to go for the great.", author: "John D. Rockefeller"),
        Quote(text: "I find that the harder I work, the more luck I seem to have.", author: "Thomas Jefferson"),
        Quote(text: "Success is no accident. It is hard work, perseverance, learning, studying, sacrifice and most of all, love of what you are doing.", author: "Pelé"),
        Quote(text: "The ones who are crazy enough to think they can change the world, are the ones that do.", author: "Rob Siltanen"),
        Quote(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt"),
        Quote(text: "The best revenge is massive success.", author: "Frank Sinatra"),
        Quote(text: "Money is not the only answer, but it makes a difference.", author: "Barack Obama"),
        Quote(text: "You can never quit. Winners never quit, and quitters never win.", author: "Ted Turner"),
        Quote(text: "Ask and you shall receive.", author: "Jesus Christ"),
        Quote(text: "Energy and persistence conquer all things.", author: "Benjamin Franklin"),
        Quote(text: "Do the best you can until you know better. Then when you know better, do better.", author: "Maya Angelou"),
        Quote(text: "Everything you want is on the other side of fear.", author: "George Addair"),
        Quote(text: "Believe in yourself. You are braver than you think, more talented than you know, and capable of more than you imagine.", author: "Roy T. Bennett"),
        Quote(text: "I learned that courage was not the absence of fear, but the triumph over it.", author: "Nelson Mandela")
    ]
    
    init() {
        // Session will be restored by splash screen
    }
    
    // MARK: - Quotes Management
    
    func getDailyQuote() -> Quote {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % quoteLibrary.count
        return quoteLibrary[index]
    }
    
    // MARK: - Save Data (Supabase Only)
    
    func saveData() {
        syncToSupabase()
    }
    
    // MARK: - Supabase Sync
    
    private func syncToSupabase() {
        guard let userId = currentUserId else { return }
        let analytics = currentUserAnalytics
        
        Task {
            do {
                let row: [String: AnyJSON] = [
                    "user_id": AnyJSON(stringLiteral: userId),
                    "total_points": AnyJSON(integerLiteral: analytics.totalPoints),
                    "total_butterflies": AnyJSON(integerLiteral: analytics.totalButterflies),
                    "current_streak": AnyJSON(integerLiteral: analytics.currentStreak),
                    "last_session_date": analytics.lastSessionDate.map { AnyJSON(stringLiteral: $0) } ?? AnyJSON.null,
                    "total_sessions": AnyJSON(integerLiteral: analytics.totalSessions),
                    "session_count": AnyJSON(stringLiteral: encodeJSON(analytics.sessionCount)),
                    "completed_gardens": AnyJSON(integerLiteral: analytics.completedGardens),
                    "mood_history": AnyJSON(stringLiteral: encodeJSON(analytics.moodHistory))
                ]
                
                try await supabase
                    .from("analytics")
                    .upsert(row, onConflict: "user_id")
                    .execute()
                    
            } catch {
                print("[Supabase] Analytics sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchAnalyticsFromSupabase() async {
        guard let userId = currentUserId else { return }
        
        do {
            struct AnalyticsRawRow: Codable {
                let total_points: Int
                let total_butterflies: Int
                let current_streak: Int
                let last_session_date: String?
                let total_sessions: Int
                let session_count: String
                let completed_gardens: Int
                let mood_history: String
            }
            
            let row: AnalyticsRawRow = try await supabase
                .from("analytics")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.currentUserAnalytics = AnalyticsData(
                    totalPoints: row.total_points,
                    totalButterflies: row.total_butterflies,
                    currentStreak: row.current_streak,
                    lastSessionDate: row.last_session_date,
                    totalSessions: row.total_sessions,
                    sessionCount: self.decodeJSON(row.session_count) ?? [:],
                    completedGardens: row.completed_gardens,
                    moodHistory: self.decodeJSON(row.mood_history) ?? [:]
                )
            }
        } catch {
            print("[Supabase] Analytics fetch failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - JSON Encoding/Decoding Helpers
    
    private func encodeJSON<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
    
    private func decodeJSON<T: Decodable>(_ string: String) -> T? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - User Management (Supabase Auth — Async with Completion Handlers)
    
    func registerUser(name: String, email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                let authResponse = try await supabase.auth.signUp(
                    email: email,
                    password: password,
                    data: ["name": AnyJSON(stringLiteral: name)]
                )
                
                let userId = authResponse.user.id.uuidString
                self.currentUserId = userId
                
                // Create profile row
                let profileData: [String: AnyJSON] = [
                    "id": AnyJSON(stringLiteral: userId),
                    "name": AnyJSON(stringLiteral: name),
                    "email": AnyJSON(stringLiteral: email)
                ]
                try await supabase
                    .from("profiles")
                    .insert(profileData)
                    .execute()
                
                // Create initial analytics row
                let analyticsData: [String: AnyJSON] = [
                    "user_id": AnyJSON(stringLiteral: userId)
                ]
                try await supabase
                    .from("analytics")
                    .insert(analyticsData)
                    .execute()
                
                // Create settings row
                let settingsData: [String: AnyJSON] = [
                    "user_id": AnyJSON(stringLiteral: userId)
                ]
                try await supabase
                    .from("settings")
                    .insert(settingsData)
                    .execute()
                
                await MainActor.run {
                    self.currentUserAnalytics = AnalyticsData()
                    self.currentUser = CurrentUserData(
                        name: name,
                        email: email,
                        isLoggedIn: true,
                        lastLoginDate: self.getCurrentDate()
                    )
                    completion(true, nil)
                }
            } catch {
                print("[Supabase] Registration failed: \(error)")
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - OTP Authentication
    
    func sendSignUpOTP(name: String, email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                // Step 1: Create user account (Confirm email must be OFF in Supabase)
                _ = try await supabase.auth.signUp(
                    email: email,
                    password: password,
                    data: ["name": AnyJSON(stringLiteral: name)]
                )
                
                // Step 2: Sign out so user can't access app yet
                try await supabase.auth.signOut()
                
                // Step 3: Send OTP via magic link system
                try await supabase.auth.signInWithOTP(email: email)
                
                await MainActor.run {
                    completion(true, nil)
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    func resendSignUpOTP(email: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                try await supabase.auth.signInWithOTP(email: email)
                await MainActor.run {
                    completion(true, nil)
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    func verifySignUpOTP(email: String, token: String, name: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                let response = try await supabase.auth.verifyOTP(
                    email: email,
                    token: token,
                    type: .email
                )
                
                guard let session = response.session else {
                    await MainActor.run {
                        completion(false, "Verification succeeded but no session was created.")
                    }
                    return
                }
                
                let userId = session.user.id.uuidString
                self.currentUserId = userId
                
                let profileData: [String: AnyJSON] = [
                    "id": AnyJSON(stringLiteral: userId),
                    "name": AnyJSON(stringLiteral: name),
                    "email": AnyJSON(stringLiteral: email)
                ]
                try await supabase.from("profiles").insert(profileData).execute()
                
                let analyticsData: [String: AnyJSON] = ["user_id": AnyJSON(stringLiteral: userId)]
                try await supabase.from("analytics").insert(analyticsData).execute()
                
                let settingsData: [String: AnyJSON] = ["user_id": AnyJSON(stringLiteral: userId)]
                try await supabase.from("settings").insert(settingsData).execute()
                
                await MainActor.run {
                    self.currentUserAnalytics = AnalyticsData()
                    self.currentUser = CurrentUserData(
                        name: name,
                        email: email,
                        isLoggedIn: true,
                        lastLoginDate: self.getCurrentDate()
                    )
                    completion(true, nil)
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    func sendLoginOTP(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                _ = try await supabase.auth.signIn(email: email, password: password)
                try await supabase.auth.signOut()
                try await supabase.auth.signInWithOTP(email: email)
                
                await MainActor.run {
                    completion(true, nil)
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    func verifyLoginOTP(email: String, token: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                let response = try await supabase.auth.verifyOTP(
                    email: email,
                    token: token,
                    type: .email
                )
                
                guard let session = response.session else {
                    await MainActor.run {
                        completion(false, "Verification succeeded but no session was created.")
                    }
                    return
                }
                
                let userId = session.user.id.uuidString
                self.currentUserId = userId
                
                let profile: ProfileRow = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    self.currentUser = CurrentUserData(
                        name: profile.name,
                        email: profile.email,
                        isLoggedIn: true,
                        lastLoginDate: self.getCurrentDate()
                    )
                }
                
                await self.fetchAnalyticsFromSupabase()
                
                await MainActor.run {
                    completion(true, nil)
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Password Reset
    
    func sendPasswordResetOTP(email: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                try await supabase.auth.signInWithOTP(email: email)
                await MainActor.run {
                    completion(true, nil)
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    func verifyPasswordResetOTP(email: String, token: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                let response = try await supabase.auth.verifyOTP(
                    email: email,
                    token: token,
                    type: .email
                )
                
                guard response.session != nil else {
                    await MainActor.run {
                        completion(false, "Verification failed. Please try again.")
                    }
                    return
                }
                
                await MainActor.run {
                    completion(true, nil)
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    func updatePassword(newPassword: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                try await supabase.auth.update(user: UserAttributes(password: newPassword))
                try await supabase.auth.signOut()
                await MainActor.run {
                    completion(true, nil)
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    func loginUser(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                let session = try await supabase.auth.signIn(
                    email: email,
                    password: password
                )
                
                let userId = session.user.id.uuidString
                self.currentUserId = userId
                
                // Fetch profile
                let profile: ProfileRow = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    self.currentUser = CurrentUserData(
                        name: profile.name,
                        email: profile.email,
                        isLoggedIn: true,
                        lastLoginDate: self.getCurrentDate()
                    )
                }
                
                // Fetch analytics
                await self.fetchAnalyticsFromSupabase()
                
                await MainActor.run {
                    completion(true, nil)
                }
            } catch {
                print("[Supabase] Login failed: \(error)")
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    func logoutUser() {
        syncToSupabase()
        
        Task {
            try? await supabase.auth.signOut()
        }
        
        currentUser?.isLoggedIn = false
        currentUser = nil
        currentUserAnalytics = AnalyticsData()
        currentUserId = nil
    }
    
    func getCurrentUser() -> CurrentUserData? {
        return currentUser
    }
    
    /// Restore session from Supabase (async — called from splash screen)
    func restoreSession() async -> Bool {
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString
            self.currentUserId = userId
            
            // Fetch profile
            let profile: ProfileRow = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.currentUser = CurrentUserData(
                    name: profile.name,
                    email: profile.email,
                    isLoggedIn: true,
                    lastLoginDate: self.getCurrentDate()
                )
            }
            
            await self.fetchAnalyticsFromSupabase()
            return true
        } catch {
            print("[Supabase] Session restore failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func updateUserName(_ newName: String) {
        guard currentUser != nil else { return }
        currentUser?.name = newName
        
        guard let userId = currentUserId else { return }
        Task {
            do {
                try await supabase
                    .from("profiles")
                    .update(["name": AnyJSON(stringLiteral: newName)])
                    .eq("id", value: userId)
                    .execute()
            } catch {
                print("[Supabase] Name update failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Profile Photo (Supabase Storage Only)
    private let profilePhotoBucket = "profile-photos"
    
    func saveProfilePhoto(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        guard let userId = currentUserId else { return }
        
        Task {
            do {
                let filePath = "\(userId)/profile.jpg"
                try await supabase.storage
                    .from(profilePhotoBucket)
                    .upload(
                        filePath,
                        data: data,
                        options: FileOptions(contentType: "image/jpeg", upsert: true)
                    )
            } catch {
                print("[Supabase] Photo upload failed: \(error.localizedDescription)")
            }
        }
    }
    
    func loadProfilePhoto(completion: @escaping (UIImage?) -> Void) {
        guard let userId = currentUserId else {
            completion(nil)
            return
        }
        
        Task {
            do {
                let filePath = "\(userId)/profile.jpg"
                let data = try await supabase.storage
                    .from(profilePhotoBucket)
                    .download(path: filePath)
                    
                let image = UIImage(data: data)
                await MainActor.run {
                    completion(image)
                }
            } catch {
                await MainActor.run {
                    completion(nil)
                }
            }
        }
    }
    
    func deleteProfilePhoto() {
        guard let userId = currentUserId else { return }
        Task {
            do {
                let filePath = "\(userId)/profile.jpg"
                try await supabase.storage
                    .from(profilePhotoBucket)
                    .remove(paths: [filePath])
            } catch {
                print("[Supabase] Photo delete failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Analytics Management
    
    func addPoints(_ points: Int) {
        currentUserAnalytics.totalPoints += points
        saveData()
        syncAchievements()
    }
    
    func getPoints() -> Int {
        return currentUserAnalytics.totalPoints
    }
    
    func addButterfly() {
        currentUserAnalytics.totalButterflies += 1
        saveData()
        syncAchievements()
    }
    
    func getButterflies() -> Int {
        return currentUserAnalytics.totalButterflies
    }
    
    func recalculateButterflies() {
        let totalSessions = currentUserAnalytics.totalSessions
        currentUserAnalytics.totalButterflies = totalSessions / 4
        saveData()
        syncAchievements()
    }
    
    func updateStreak() {
        let today = getCurrentDate()
        if let lastDate = currentUserAnalytics.lastSessionDate {
            let daysBetween = daysDifference(from: lastDate, to: today)
            if daysBetween == 1 {
                currentUserAnalytics.currentStreak += 1
            } else if daysBetween > 1 {
                currentUserAnalytics.currentStreak = 1
            }
        } else {
            currentUserAnalytics.currentStreak = 1
        }
        currentUserAnalytics.lastSessionDate = today
        saveData()
        syncAchievements()
    }
    
    func getStreak() -> Int {
        return currentUserAnalytics.currentStreak
    }
    
    func incrementSessionCount() {
        let today = getCurrentDate()
        currentUserAnalytics.sessionCount[today, default: 0] += 1
        currentUserAnalytics.totalSessions += 1
        saveData()
        syncAchievements()
    }
    
    func getSessionCountForDay(_ date: String? = nil) -> Int {
        let day = date ?? getCurrentDate()
        return currentUserAnalytics.sessionCount[day] ?? 0
    }
    
    func getLifecycleStage() -> Int {
        let totalSessions = currentUserAnalytics.totalSessions
        if totalSessions == 0 || totalSessions == 1 {
            return 0
        } else {
            return ((totalSessions - 1) % 4)
        }
    }
    
    func incrementCompletedGardens() {
        currentUserAnalytics.completedGardens += 1
        saveData()
        syncAchievements()
    }
    
    func getAnalytics() -> AnalyticsData {
        return currentUserAnalytics
    }
    
    // MARK: - Garden Logic
    func resetButterflies() {
        currentUserAnalytics.totalButterflies = 0
        saveData()
    }
    
    func resetAnalytics() {
        currentUserAnalytics = AnalyticsData()
        saveData()
    }
    
    func getCompletedGardens() -> Int {
        return currentUserAnalytics.completedGardens
    }
    
    func logMood(score: Int) {
        let today = getCurrentDate()
        currentUserAnalytics.moodHistory[today, default: []].append(score)
        saveData()
    }
    
    // Returns last 7 days of data for the graph
    func getWeeklyMoodData() -> [(day: String, score: Double)] {
        var result: [(day: String, score: Double)] = []
        let calendar = Calendar.current
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dateString = dateToString(date)
                let dayName = formatter.string(from: date)
                
                if let scores = currentUserAnalytics.moodHistory[dateString], !scores.isEmpty {
                    let total = scores.reduce(0, +)
                    let average = Double(total) / Double(scores.count)
                    result.append((day: dayName, score: average))
                } else {
                    result.append((day: dayName, score: 0.0))
                }
            }
        }
        return result
    }
    
    // MARK: - Fixed Week Comparison Logic
    func getFixedWeekComparison() -> (current: [Double?], previous: [Double], labels: [String]) {
        var currentScores: [Double?] = []
        var previousScores: [Double] = []
        let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let today = Date()
        
        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return ([], [], labels)
        }
        
        guard let prevWeekStart = calendar.date(byAdding: .day, value: -7, to: currentWeekStart) else {
            return ([], [], labels)
        }
        
        for i in 0..<7 {
            if let pDate = calendar.date(byAdding: .day, value: i, to: prevWeekStart) {
                let key = dateToString(pDate)
                if let scores = currentUserAnalytics.moodHistory[key], !scores.isEmpty {
                    let avg = Double(scores.reduce(0, +)) / Double(scores.count)
                    previousScores.append(avg)
                } else {
                    previousScores.append(0.0)
                }
            }
            
            if let cDate = calendar.date(byAdding: .day, value: i, to: currentWeekStart) {
                if calendar.startOfDay(for: cDate) > calendar.startOfDay(for: today) {
                    currentScores.append(nil)
                } else {
                    let key = dateToString(cDate)
                    if let scores = currentUserAnalytics.moodHistory[key], !scores.isEmpty {
                        let avg = Double(scores.reduce(0, +)) / Double(scores.count)
                        currentScores.append(avg)
                    } else {
                        currentScores.append(0.0)
                    }
                }
            }
        }
        
        return (currentScores, previousScores, labels)
    }
    
    private func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Helpers
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func daysDifference(from: String, to: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let fromDate = formatter.date(from: from), let toDate = formatter.date(from: to) else { return 0 }
        return Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day ?? 0
    }
    
    // MARK: - Achievement Sync
    
    func syncAchievementsNow() {
        syncAchievements()
    }
    
    private func syncAchievements() {
        let am = AchievementManager.shared
        let analytics = currentUserAnalytics
        let points      = analytics.totalPoints
        let sessions    = analytics.totalSessions
        let streak      = analytics.currentStreak
        let butterflies = analytics.totalButterflies
        let gardens     = analytics.completedGardens
        let todaySessions = getSessionCountForDay()
        
        let pointsThresholds: [(id: String, req: Int)] = [
            ("points_200",  200),
            ("points_350",  350),
            ("points_600",  600),
            ("points_800",  800),
            ("points_1200", 1200),
            ("points_2000", 2000)
        ]
        for t in pointsThresholds {
            am.setProgress(id: t.id, value: min(points, t.req))
            if points >= t.req { am.unlock(id: t.id) }
        }
        
        let growthThresholds: [(id: String, req: Int)] = [
            ("growth_egg",         1),
            ("growth_caterpillar", 2),
            ("growth_cocoon",      3),
            ("growth_butterfly",   4)
        ]
        for t in growthThresholds {
            am.setProgress(id: t.id, value: min(sessions, t.req))
            if sessions >= t.req { am.unlock(id: t.id) }
        }
        
        let sessionThresholds: [(id: String, req: Int)] = [
            ("session_10", 10),
            ("session_20", 20),
            ("session_40", 40),
            ("session_80", 80)
        ]
        for t in sessionThresholds {
            am.setProgress(id: t.id, value: min(sessions, t.req))
            if sessions >= t.req { am.unlock(id: t.id) }
        }
        
        let mindThresholds: [(id: String, req: Int)] = [
            ("mind_double", 2),
            ("mind_triple", 3),
            ("mind_4",      4),
            ("mind_deep",   5)
        ]
        for t in mindThresholds {
            am.setProgress(id: t.id, value: min(todaySessions, t.req))
            if todaySessions >= t.req { am.unlock(id: t.id) }
        }
        
        let streakThresholds: [(id: String, req: Int)] = [
            ("streak_3",  3),
            ("streak_7",  7),
            ("streak_30", 30),
            ("streak_60", 60)
        ]
        for t in streakThresholds {
            am.setProgress(id: t.id, value: min(streak, t.req))
            if streak >= t.req { am.unlock(id: t.id) }
        }
        
        let butterflyThresholds: [(id: String, req: Int)] = [
            ("butterfly_5",  5),
            ("butterfly_15", 15),
            ("butterfly_30", 30),
            ("butterfly_60", 60)
        ]
        for t in butterflyThresholds {
            am.setProgress(id: t.id, value: min(butterflies, t.req))
            if butterflies >= t.req { am.unlock(id: t.id) }
        }
        
        let gardenThresholds: [(id: String, req: Int)] = [
            ("garden_1",   1),
            ("garden_10",  10),
            ("garden_25",  25),
            ("garden_50",  50),
            ("garden_75",  75),
            ("garden_100", 100)
        ]
        for t in gardenThresholds {
            am.setProgress(id: t.id, value: min(gardens, t.req))
            if gardens >= t.req { am.unlock(id: t.id) }
        }
        
        am.unlock(id: "user_login")
    }
}
