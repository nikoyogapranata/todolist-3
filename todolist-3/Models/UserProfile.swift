//
//  UserProfile.swift
//  todolist-3
//
//  LAYER: Model
//  PURPOSE: Holds the user's profile data (name, bio, avatar emoji).
//           Codable so it can be persisted to UserDefaults as JSON.
//           Keeping it as a struct (value type) prevents accidental
//           shared-state bugs.
//

import Foundation

// -----------------------------------------------------------------------------
// UserProfile
// Persisted as JSON in UserDefaults under the key "userProfile_v1".
// The ViewModel owns one @Published var of this type and provides save/load.
// -----------------------------------------------------------------------------
struct UserProfile: Codable {

    /// The user's display name shown on the Profile tab.
    var name: String = "Niko"

    /// Short tagline / bio shown below the avatar.
    var bio: String = "Getting things done 🚀"

    /// Single emoji used as the avatar – easy to customise without image assets.
    var avatarEmoji: String = "🧑‍💻"
}
