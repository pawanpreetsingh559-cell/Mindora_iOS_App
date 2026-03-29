<div align="center">

  <img src="https://github.com/user-attachments/assets/005a0f7c-d404-403e-afa6-ca61a2d5a20f" alt="Mindora Logo" width="120" height="120" style="border-radius: 20px;">

  #  Mindora – Mental Wellness Companion
  
  **Breathe. Relieve. Transform.**

  <p>
    <img src="https://img.shields.io/badge/Platform-iOS_16+-blue?logo=apple&style=flat-square" alt="Platform iOS">
    <img src="https://img.shields.io/badge/Swift-5.9-orange?logo=swift&style=flat-square" alt="Swift 5.9">
    <img src="https://img.shields.io/badge/Backend-Supabase-green?logo=supabase&style=flat-square" alt="Supabase">
    <img src="https://img.shields.io/badge/Rating-4+-brightgreen?style=flat-square" alt="Rating 4+">
  </p>
  
  <!-- Hero iPhone Display -->
  <img src="https://github.com/user-attachments/assets/8c1b0897-8e6c-4619-8522-086a33a762b1" alt="Hero Image" width="250" style="border-radius: 36px; border: 8px solid #000000; box-shadow: 0 0 0 4px #ffffff, 0 15px 25px rgba(0,0,0,0.5); margin: 10px;">
</div>

> **Mindora** is a minimalist iOS mental wellness app that replaces long, intimidating meditation with exactly 120 seconds of real emotional regulation. Find your peace, build micro-habits, and watch a 3D AR sanctuary bloom inside your own room.

---

## ✨ Features

| 🌬️ **2-Minute Calming Activities** | 🦋 **Interactive 3D AR Sanctuary** |
| :--- | :--- |
| • **Breath & Sound Therapy:** Calm racing minds using guided deep breathing rhythms paired with immersive nature sounds.<br>• **Physical Tension Release:** Guided shoulder drops and eye relaxations designed for screen fatigue.<br>• **Mindful Grounding:** Short, focused meditations and tactile finger rhythms for gentle self-massage. | • **The Evolution Lifecycle:** Progress through a calming journey — _Egg → Caterpillar → Pupa → Butterfly_.<br>• **Earn Your Butterflies:** Every 4th session permanently unlocks a vibrant new butterfly for your garden.<br>• **Spatial AR Interaction:** Project the garden into your room via **Apple ARKit**. Fully responsive to pinch-to-zoom and two-finger rotation. |

| 📊 **Mood Analytics & Achievements** | 🎧 **High-Quality Audio Escapes** |
| :--- | :--- |
| • **Frictionless Logging:** Log your mood on a clean 1–5 scale immediately after any reset activity (takes under 5 seconds).<br>• **Visual Trajectory:** Encrypted weekly charts map your emotional trends against your relaxation habits.<br>• **Minimalist Badges:** Elegantly designed achievement badges for milestones — no loud tier labels, just clean acknowledgment. | • **Immersive Soundscapes:** Escape instantly with premium offline audio tracks like _Deep Serenity_, _Meadow Peace_, _Twilight Dreams_, and _Urban Stillness_.<br>• **Offline-First Support:** Fully functional without connectivity, backed seamlessly to the cloud. |

---

## 📸 Screenshots

<p align="center">
  <!-- iPhone Styled Screenshots -->
  <img src="https://github.com/user-attachments/assets/c7df94f0-a8cc-44c6-a20c-a5b111de0b20" width="28%" style="border-radius: 36px; border: 8px solid #000000; box-shadow: 0 0 0 4px #ffffff, 0 15px 25px rgba(0,0,0,0.5); margin: 15px 1%;">
  <img src="https://github.com/user-attachments/assets/dba5bdd2-6fcf-425f-b4f2-ff730502ccfe" width="28%" style="border-radius: 36px; border: 8px solid #000000; box-shadow: 0 0 0 4px #ffffff, 0 15px 25px rgba(0,0,0,0.5); margin: 15px 1%;">
  <img src="https://via.placeholder.com/250x541/1A1A2E/FFFFFF/?text=Add+3rd+Screenshot" width="28%" style="border-radius: 36px; border: 8px solid #000000; box-shadow: 0 0 0 4px #ffffff, 0 15px 25px rgba(0,0,0,0.5); margin: 15px 1%;">
</p>

---

## 🏗️ Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Language** | Swift 5.9 |
| **UI Framework** | UIKit (Storyboards + programmatic constraints) |
| **Backend** | [Supabase](https://supabase.com/) (PostgreSQL, Auth, Realtime) |
| **Augmented Reality**| ARKit & SceneKit / RealityKit (via `.usdz` logic) |
| **Audio Engine** | AVFoundation (SoundManager) |
| **Haptics** | CoreHaptics (`UIImpactFeedbackGenerator`) |
| **Local Persistence**| DataManager |

---

## 📂 Project Structure

```text
Mindora_iOS_App/
├── Mindora.xcodeproj/         # Xcode project bundle
├── Mindora/
│   ├── AppDelegate.swift      # Application lifecycle
│   ├── SceneDelegate.swift    # Scene lifecycle & deep linking
│   ├── Info.plist             # App permissions and configs
│   ├── Assets.xcassets/       # Icons, images, and colours
│   ├── Base.lproj/            # Interface Builder storyboards
│   │
│   ├── Models/
│   │   └── AchievementModels.swift    # Core data structures
│   │
│   ├── Managers/
│   │   ├── DataManager.swift          # Offline-first syncing 
│   │   ├── AchievementManager.swift   # Gamification logic
│   │   └── SoundManager.swift         # MP3 playback engine
│   │
│   ├── Configuration/
│   │   └── SupabaseConfig.swift       # Supabase BAAS integration
│   │
│   ├── Controllers/
│   │   ├── BreathingViewController.swift       # 2-Min Reset Logic
│   │   ├── AdvancedCalmingViewController.swift # Deep stress relief
│   │   ├── ARGardenViewController.swift        # Apple ARKit spatial logic
│   │   ├── InsightsViewController.swift        # Encrypted visual charts
│   │   ├── MoodScoreViewController.swift       # 5-second logging
│   │   ├── PremiumOnboardingViewController.swift
│   │   └── ... (Auth & Setting controllers)
│   │
│   ├── Elements/
│   │   ├── CircularProgressView.swift
│   │   └── *BadgeView.swift           # Reusable milestone components
│   │
│   └── Extensions/
│       └── Extensions.swift           # Shared Swift helpers
│
├── *.usdz                             # Bundled AR 3D Models
└── *.mp3                              # Pre-packaged lossless audio
```
