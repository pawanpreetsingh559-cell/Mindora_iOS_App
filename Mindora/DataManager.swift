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
    // Tracks the totalButterflies value at which the garden-complete alert was last shown.
    // Prevents the alert from re-appearing every time the Garden screen opens.
    var lastGardenAlertedAt: Int = -1
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
    
    // Set to true after the user removes their photo so that any loadProfilePhoto
    // call (even those hitting the URLSession cache) returns nil immediately.
    private var profilePhotoDeleted = false
    
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
        
        // Save locally immediately so offline mode always has the freshest data
        saveAnalyticsToCache(analytics)
        
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
                let fetchedAnalytics = AnalyticsData(
                    totalPoints: row.total_points,
                    totalButterflies: row.total_butterflies,
                    currentStreak: row.current_streak,
                    lastSessionDate: row.last_session_date,
                    totalSessions: row.total_sessions,
                    sessionCount: self.decodeJSON(row.session_count) ?? [:],
                    completedGardens: row.completed_gardens,
                    moodHistory: self.decodeJSON(row.mood_history) ?? [:]
                )
                self.currentUserAnalytics = fetchedAnalytics
                
                // Immediately save the downloaded analytics to local cache for offline viewing later
                self.saveAnalyticsToCache(fetchedAnalytics)
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

    // MARK: - Local Caching (For Offline Mode)
    
    private let kCachedProfileKey = "com.mindora.cachedProfile"
    private let kCachedAnalyticsKey = "com.mindora.cachedAnalytics"

    private func saveProfileToCache(_ data: CurrentUserData) {
        if let json = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(json, forKey: kCachedProfileKey)
        }
    }
    
    private func loadProfileFromCache() -> CurrentUserData? {
        guard let data = UserDefaults.standard.data(forKey: kCachedProfileKey) else { return nil }
        return try? JSONDecoder().decode(CurrentUserData.self, from: data)
    }

    private func saveAnalyticsToCache(_ data: AnalyticsData) {
        if let json = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(json, forKey: kCachedAnalyticsKey)
        }
    }

    private func loadAnalyticsFromCache() -> AnalyticsData? {
        guard let data = UserDefaults.standard.data(forKey: kCachedAnalyticsKey) else { return nil }
        return try? JSONDecoder().decode(AnalyticsData.self, from: data)
    }
    
    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: kCachedProfileKey)
        UserDefaults.standard.removeObject(forKey: kCachedAnalyticsKey)
        UserDefaults.standard.removeObject(forKey: "AvatarFontIndex")
        UserDefaults.standard.removeObject(forKey: "AvatarColorIndex")
        UserDefaults.standard.removeObject(forKey: "AvatarColorIndexSet")
        UserDefaults.standard.removeObject(forKey: "AvatarThemeIndex")
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
    
    // Credentials stored locally until OTP is verified.
    // Zero Supabase records are created until verifySignUpOTP succeeds.
    private var pendingSignUpName: String = ""
    private var pendingSignUpPassword: String = ""
    
    func sendSignUpOTP(name: String, email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        // Save credentials in memory — nothing is written to Supabase yet.
        // signInWithOTP only creates a temporary passwordless placeholder
        // with NO password — it cannot be used to log in.
        // Your profiles / analytics / settings tables stay completely empty.
        self.pendingSignUpName = name
        self.pendingSignUpPassword = password
        
        Task {
            do {
                try await supabase.auth.signInWithOTP(email: email)
                await MainActor.run { completion(true, nil) }
            } catch {
                await MainActor.run { completion(false, error.localizedDescription) }
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
        // Use in-memory credentials stored during sendSignUpOTP.
        let finalName = pendingSignUpName.isEmpty ? name : pendingSignUpName
        let finalPassword = pendingSignUpPassword.isEmpty ? password : pendingSignUpPassword
        
        Task {
            do {
                // Step 1: Verify OTP — this confirms the email and starts a session.
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
                
                // Step 2: Set the password + name on this account NOW (after OTP verified).
                // This converts the temporary passwordless placeholder into a real account.
                try await supabase.auth.update(user: UserAttributes(
                    password: finalPassword,
                    data: ["name": AnyJSON(stringLiteral: finalName)]
                ))
                
                let userId = session.user.id.uuidString
                self.currentUserId = userId
                
                // Step 3: Create all app DB rows — only runs if OTP was verified.
                let profileData: [String: AnyJSON] = [
                    "id": AnyJSON(stringLiteral: userId),
                    "name": AnyJSON(stringLiteral: finalName),
                    "email": AnyJSON(stringLiteral: email)
                ]
                try await supabase.from("profiles").upsert(profileData).execute()
                
                let analyticsData: [String: AnyJSON] = ["user_id": AnyJSON(stringLiteral: userId)]
                try await supabase.from("analytics").upsert(analyticsData).execute()
                
                let settingsData: [String: AnyJSON] = ["user_id": AnyJSON(stringLiteral: userId)]
                try await supabase.from("settings").upsert(settingsData).execute()
                
                // Clear pending credentials
                self.pendingSignUpName = ""
                self.pendingSignUpPassword = ""
                
                await MainActor.run {
                    self.currentUserAnalytics = AnalyticsData()
                    let newUser = CurrentUserData(
                        name: finalName,
                        email: email,
                        isLoggedIn: true,
                        lastLoginDate: self.getCurrentDate()
                    )
                    self.currentUser = newUser
                    self.saveProfileToCache(newUser)
                    self.saveAnalyticsToCache(self.currentUserAnalytics)
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
                let errorStr = error.localizedDescription.lowercased()
                if errorStr.contains("not confirmed") || errorStr.contains("unverified") || errorStr.contains("email address not authorized") {
                    await MainActor.run {
                        completion(false, "Your account creation was incomplete. Please use the Sign Up screen to finish registering.")
                    }
                } else {
                    await MainActor.run {
                        completion(false, error.localizedDescription)
                    }
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
                
                // Safely fetch profile — if no profile exists this user never
                // completed sign-up. Show a helpful error instead of crashing.
                let profiles: [ProfileRow] = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .execute()
                    .value
                
                guard let profile = profiles.first else {
                    // Account exists in auth but never completed sign-up.
                    try? await supabase.auth.signOut()
                    await MainActor.run {
                        completion(false, "Your account setup is incomplete. Please sign up again to finish creating your account.")
                    }
                    return
                }
                
                await MainActor.run {
                    let user = CurrentUserData(
                        name: profile.name,
                        email: profile.email,
                        isLoggedIn: true,
                        lastLoginDate: self.getCurrentDate()
                    )
                    self.currentUser = user
                    self.saveProfileToCache(user)
                    NotificationCenter.default.post(name: NSNotification.Name("UserProfileUpdated"), object: nil)
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
                // First check the profiles table to confirm this email belongs to a real account.
                let profiles: [ProfileRow] = try await supabase
                    .from("profiles")
                    .select()
                    .eq("email", value: email)
                    .execute()
                    .value
                
                guard !profiles.isEmpty else {
                    await MainActor.run {
                        completion(false, "No account found with this email address. Please sign up first.")
                    }
                    return
                }
                
                // Email confirmed — send the OTP.
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
        clearCache()
    }
    
    // MARK: - Account Deletion
    
    func deleteAccount(completion: @escaping (Bool, String?) -> Void) {
        guard let userId = currentUserId else {
            completion(false, "No user logged in.")
            return
        }
        
        Task {
            do {
                // Step 1: Delete app-level DB rows
                try? await supabase.from("profiles").delete().eq("id", value: userId).execute()
                try? await supabase.from("analytics").delete().eq("user_id", value: userId).execute()
                try? await supabase.from("settings").delete().eq("user_id", value: userId).execute()
                
                // Step 2: Delete the Supabase auth user via the RPC helper
                try await supabase.rpc("delete_user").execute()
                
                // Step 3: Sign out locally
                try? await supabase.auth.signOut()
                
                await MainActor.run {
                    self.currentUser?.isLoggedIn = false
                    self.currentUser = nil
                    self.currentUserAnalytics = AnalyticsData()
                    self.currentUserId = nil
                    self.clearCache()
                    completion(true, nil)
                }
            } catch {
                // If the RPC fails (e.g. network issue), still sign out locally so
                // the user is not stuck — they can try again after re-logging in.
                try? await supabase.auth.signOut()
                await MainActor.run {
                    self.currentUser = nil
                    self.currentUserId = nil
                    self.clearCache()
                    completion(false, "Account deletion failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Avatar Theme Management
    func getAvatarTheme() -> Int {
        return UserDefaults.standard.integer(forKey: "AvatarThemeIndex")
    }
    
    func setAvatarTheme(_ index: Int) {
        UserDefaults.standard.set(index, forKey: "AvatarThemeIndex")
    }
    
    func generateInitialsImage(name: String, size: CGSize, forceTheme: Int? = nil) -> UIImage {
        let initials = name.components(separatedBy: " ")
            .compactMap { $0.first.map { String($0) } }
            .prefix(2).joined().uppercased()
            
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        
        // Clip to circle so the icon itself is rounded, important for UIAlertAction previews
        UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
        
        let themeIndex = forceTheme ?? getAvatarTheme()
        var colors: [UIColor]
        var font: UIFont
        let fontSize = size.width * 0.4
        
        switch themeIndex {
        case 1:
            // Elegant Gold
            colors = [UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0), UIColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1.0)]
            font = UIFont(name: "Palatino-Bold", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .bold)
        case 2:
            // Playful Pastel
            colors = [UIColor(red: 1.0, green: 0.6, blue: 0.6, alpha: 1.0), UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)]
            font = UIFont(name: "MarkerFelt-Wide", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .bold)
        case 3:
            // Tech Monospace
            colors = [UIColor(red: 0.2, green: 0.0, blue: 0.4, alpha: 1.0), UIColor(red: 0.0, green: 0.8, blue: 0.4, alpha: 1.0)]
            font = UIFont(name: "Menlo-Bold", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .bold)
        case 4:
            // Minimal Dark
            colors = [UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0), UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)]
            font = UIFont(name: "HelveticaNeue-UltraLight", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .light)
        default:
            // Custom colour palette — matches CustomizeInitialViewController.colorOptions order.
            // If the user picked a colour via the Customize Initial sheet it is stored as
            // AvatarColorIndex (>= 0). Fall back to the name-hash palette otherwise.
            let customPalette: [(UIColor, UIColor)] = [
                (UIColor(red:0.0,green:0.580,blue:1.0,alpha:1), UIColor(red:0.0,green:0.45,blue:0.85,alpha:1)),
                (UIColor(red:0.50,green:0.92,blue:0.94,alpha:1), UIColor(red:0.30,green:0.72,blue:0.80,alpha:1)),
                (UIColor(red:0.45,green:0.95,blue:0.70,alpha:1), UIColor(red:0.25,green:0.75,blue:0.50,alpha:1)),
                (UIColor(red:0.70,green:0.90,blue:0.68,alpha:1), UIColor(red:0.50,green:0.75,blue:0.50,alpha:1)),
                (UIColor(red:0.80,green:0.65,blue:0.98,alpha:1), UIColor(red:0.65,green:0.45,blue:0.85,alpha:1)),
                (UIColor(red:1.00,green:0.62,blue:0.75,alpha:1), UIColor(red:0.90,green:0.40,blue:0.55,alpha:1)),
                (UIColor(red:1.00,green:0.85,blue:0.45,alpha:1), UIColor(red:0.95,green:0.65,blue:0.25,alpha:1)),
            ]
            let colorIndex = UserDefaults.standard.integer(forKey: "AvatarColorIndex")
            // integer(forKey:) returns 0 if unset, so treat -1 (unused) as "not set".
            // We use a separate flag key to distinguish "user chose index 0" vs "never set".
            let userChoseColor = UserDefaults.standard.bool(forKey: "AvatarColorIndexSet")
            if userChoseColor, colorIndex < customPalette.count {
                let pair = customPalette[colorIndex]
                colors = [pair.0, pair.1]
            } else {
                // Fall back to the default blue color
                let pair = customPalette[0]
                colors = [pair.0, pair.1]
            }
            
            // Font — respect AvatarFontIndex for theme-0 variants (Bold, Rounded, Script, etc.)
            let fontIndex = UserDefaults.standard.integer(forKey: "AvatarFontIndex")
            switch fontIndex {
            case 0: // Bold
                font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            case 1: // Rounded
                var base = UIFont.systemFont(ofSize: fontSize, weight: .bold)
                if let rd = base.fontDescriptor.withDesign(.rounded) { base = UIFont(descriptor: rd, size: fontSize) }
                font = base
            case 2: // Serif
                font = UIFont(name: "Palatino-Bold", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .bold)
            case 3: // Pastel
                font = UIFont(name: "MarkerFelt-Wide", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .bold)
            case 4: // Mono
                font = UIFont(name: "Menlo-Bold", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .bold)
            case 5: // Minimal
                font = UIFont(name: "HelveticaNeue-UltraLight", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .light)
            case 6: // Script
                font = UIFont(name: "Noteworthy-Bold", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .bold)
            default:
                var base = UIFont.systemFont(ofSize: fontSize, weight: .bold)
                if let rd = base.fontDescriptor.withDesign(.rounded) { base = UIFont(descriptor: rd, size: fontSize) }
                font = base
            }
        }
        
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors.map { $0.cgColor } as CFArray,
            locations: [0, 1])!
        ctx.drawLinearGradient(gradient,
                               start: .zero,
                               end: CGPoint(x: size.width, y: size.height),
                               options: [])
                               
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        let derivedInitials = initials.isEmpty ? "G" : initials
        let str = derivedInitials as NSString
        let strSize = str.size(withAttributes: attrs)
        str.draw(at: CGPoint(x: (size.width - strSize.width) / 2,
                             y: (size.height - strSize.height) / 2),
                 withAttributes: attrs)
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }
    
    func getCurrentUser() -> CurrentUserData? {
        return currentUser
    }
    
    /// Restore session from Supabase (async — called from splash screen)
    func restoreSession() async -> Bool {
        do {
            // Step 1: Check the locally cached auth token (works 100% offline — stored in Keychain).
            // If this throws, the user has never logged in or explicitly signed out → go to Onboarding.
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString
            self.currentUserId = userId

            // Step 2: Attempt to load the LAST KNOWN data from UserDefaults cache immediately.
            // This ensures the Dashboard has the correct Name, Streaks, Points, etc., instantly offline.
            await MainActor.run {
                // Try caching analytics first
                if let cachedAnalytics = self.loadAnalyticsFromCache() {
                    self.currentUserAnalytics = cachedAnalytics
                }

                // Try caching profile
                if let cachedProfile = self.loadProfileFromCache() {
                    self.currentUser = cachedProfile
                } else {
                    // Extreme fallback if NO cache exists (but they are logged in)
                    self.currentUser = CurrentUserData(
                        name: session.user.email ?? "User",
                        email: session.user.email ?? "",
                        isLoggedIn: true,
                        lastLoginDate: self.getCurrentDate()
                    )
                }
            }

            // Step 3: Attempt to refresh profile & analytics from Supabase in the background.
            // If the device is offline this block simply fails silently — the user is already
            // inside the Dashboard with their last-known local data from the steps above.
            Task {
                do {
                    let profile: ProfileRow = try await supabase
                        .from("profiles")
                        .select()
                        .eq("id", value: userId)
                        .single()
                        .execute()
                        .value

                    await MainActor.run {
                        let updatedUser = CurrentUserData(
                            name: profile.name,
                            email: profile.email,
                            isLoggedIn: true,
                            lastLoginDate: self.getCurrentDate()
                        )
                        self.currentUser = updatedUser
                        self.saveProfileToCache(updatedUser)
                    }

                    await self.fetchAnalyticsFromSupabase()
                } catch {
                    print("[Supabase] Background profile refresh skipped (offline?): \(error.localizedDescription)")
                }
            }

            // Return true immediately — the session token confirmed the user is logged in.
            return true

        } catch {
            // No valid local session token → user is not logged in → go to Onboarding.
            print("[Supabase] No saved session found: \(error.localizedDescription)")
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
    
    func saveProfilePhoto(_ image: UIImage, completion: ((Bool) -> Void)? = nil) {
        // User is uploading a new photo — clear the deleted flag.
        profilePhotoDeleted = false
        // Resize to max 400×400 before uploading — drastically reduces upload size
        let maxDimension: CGFloat = 400
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()

        guard let data = resized.jpegData(compressionQuality: 0.5) else {
            completion?(false); return
        }

        Task {
            do {
                let session = try await supabase.auth.session
                let userId = session.user.id.uuidString.lowercased()
                let filePath = "\(userId)/profile.jpg"
                print("[Supabase] Uploading photo (\(data.count / 1024)KB), path: \(filePath)")

                try await supabase.storage
                    .from(profilePhotoBucket)
                    .upload(
                        filePath,
                        data: data,
                        options: FileOptions(contentType: "image/jpeg", upsert: true)
                    )
                print("[Supabase] Photo uploaded successfully.")
                await MainActor.run { completion?(true) }
            } catch {
                print("[Supabase] Photo upload failed: \(error)")
                await MainActor.run { completion?(false) }
            }
        }
    }
    
    func loadProfilePhoto(completion: @escaping (UIImage?) -> Void) {
        // If the user just deleted their photo, skip the network/cache fetch entirely.
        if profilePhotoDeleted {
            completion(nil)
            return
        }
        
        guard let userId = currentUserId else {
            completion(nil)
            return
        }

        Task {
            // Try lowercase path first (new standard), fall back to uppercase (legacy)
            let paths = [userId.lowercased(), userId]
            for path in paths {
                do {
                    let filePath = "\(path)/profile.jpg"
                    let data = try await supabase.storage
                        .from(profilePhotoBucket)
                        .download(path: filePath)
                    if let image = UIImage(data: data) {
                        await MainActor.run { completion(image) }
                        return
                    }
                } catch {
                    // Try next path
                }
            }
            await MainActor.run { completion(nil) }
        }
    }
    
    func deleteProfilePhoto(completion: (() -> Void)? = nil) {
        Task {
            // Mark as deleted immediately so loadProfilePhoto returns nil from now on,
            // even if the Supabase call is still in-flight or the URLSession cache hit.
            await MainActor.run { self.profilePhotoDeleted = true }
            
            // Also purge the URLSession cache so the stale photo isn't served from disk.
            URLCache.shared.removeAllCachedResponses()
            
            do {
                let session = try await supabase.auth.session
                let userId = session.user.id.uuidString.lowercased()
                let paths = ["\(userId)/profile.jpg", "\(userId.uppercased())/profile.jpg"]
                do {
                    let removed = try await supabase.storage
                        .from(profilePhotoBucket)
                        .remove(paths: paths)
                    print("[Supabase] Photo delete — removed \(removed.count) object(s)")
                } catch {
                    print("[Supabase] ❌ remove() FAILED: \(error)")
                }
            } catch {
                print("[Supabase] ❌ deleteProfilePhoto — auth session error: \(error)")
            }
            await MainActor.run { completion?() }
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
            if daysBetween == 0 {
                // Same day — no streak change, skip the Supabase write
                return
            } else if daysBetween == 1 {
                currentUserAnalytics.currentStreak += 1
            } else {
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
    
    /// Call this when the garden-complete alert is dismissed (reset or keep).
    /// Records the current butterfly count so the alert won't show again for the same milestone.
    func markGardenAlertShown() {
        currentUserAnalytics.lastGardenAlertedAt = currentUserAnalytics.totalButterflies
        saveData()
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
    
    // MARK: - Monthly Mood Data
    func getMonthlyMoodData() -> (scores: [Double?], labels: [String], monthName: String) {
        var scores: [Double?] = []
        var labels: [String] = []
        
        let today = Date()
        let calendar = Calendar.current
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let monthName = formatter.string(from: today)
        
        guard let monthRange = calendar.range(of: .day, in: .month, for: today),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else {
            return ([], [], monthName)
        }
        
        let currentDayNumber = calendar.component(.day, from: today)
        
        for day in 1...monthRange.count {
            labels.append("\(day)")
            
            if day > currentDayNumber {
                scores.append(nil)
            } else {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                    let key = dateToString(date)
                    if let dayScores = currentUserAnalytics.moodHistory[key], !dayScores.isEmpty {
                        let avg = Double(dayScores.reduce(0, +)) / Double(dayScores.count)
                        scores.append(avg)
                    } else {
                        scores.append(0.0)
                    }
                } else {
                    scores.append(0.0)
                }
            }
        }
        
        return (scores, labels, monthName)
    }
    
    // MARK: - Monthly Comparison (Current vs Previous Month)
    func getMonthlyComparison() -> (current: [Double?], previous: [Double], labels: [String], currentMonthName: String, previousMonthName: String) {
        let calendar = Calendar.current
        let today = Date()
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let currentMonthName = monthFormatter.string(from: today)
        
        // Start of current month
        guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else {
            return ([], [], [], currentMonthName, "")
        }
        
        // Start of previous month
        guard let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart) else {
            return ([], [], [], currentMonthName, "")
        }
        let previousMonthName = monthFormatter.string(from: previousMonthStart)
        
        // Days in each month
        guard let currentMonthRange = calendar.range(of: .day, in: .month, for: currentMonthStart),
              let previousMonthRange = calendar.range(of: .day, in: .month, for: previousMonthStart) else {
            return ([], [], [], currentMonthName, previousMonthName)
        }
        
        let maxDays = max(currentMonthRange.count, previousMonthRange.count)
        let currentDayNumber = calendar.component(.day, from: today)
        
        var currentScores: [Double?] = []
        var previousScores: [Double] = []
        var labels: [String] = []
        
        for day in 1...maxDays {
            labels.append("\(day)")
            
            // Previous month
            if day <= previousMonthRange.count,
               let pDate = calendar.date(byAdding: .day, value: day - 1, to: previousMonthStart) {
                let key = dateToString(pDate)
                if let scores = currentUserAnalytics.moodHistory[key], !scores.isEmpty {
                    previousScores.append(Double(scores.reduce(0, +)) / Double(scores.count))
                } else {
                    previousScores.append(0.0)
                }
            } else {
                previousScores.append(0.0)
            }
            
            // Current month
            if day > currentMonthRange.count || day > currentDayNumber {
                currentScores.append(nil)
            } else if let cDate = calendar.date(byAdding: .day, value: day - 1, to: currentMonthStart) {
                let key = dateToString(cDate)
                if let scores = currentUserAnalytics.moodHistory[key], !scores.isEmpty {
                    currentScores.append(Double(scores.reduce(0, +)) / Double(scores.count))
                } else {
                    currentScores.append(0.0)
                }
            } else {
                currentScores.append(0.0)
            }
        }
        
        return (currentScores, previousScores, labels, currentMonthName, previousMonthName)
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
