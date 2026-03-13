//
//  SupabaseConfig.swift
//  Mindora
//
//  Supabase client configuration.
//  Replace the placeholder values below with your actual Supabase project credentials.
//

import Foundation
import Supabase

enum SupabaseConfig {
    // REPLACE THESE with your actual Supabase project values
    // Found in: Supabase Dashboard → Project Settings → API
    static let url = URL(string: "https://zzyjdxggfizlqzmremwn.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6eWpkeGdnZml6bHF6bXJlbXduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyNDA0NzUsImV4cCI6MjA4ODgxNjQ3NX0.16Cg9grO2xzG9i0dmV037Mi6vhyZ913804ES-VqnjQk"
}

/// Global Supabase client accessor
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey
)
