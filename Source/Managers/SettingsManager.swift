//
//  SettingsManager.swift
//

import Foundation

class SettingsManager {

    private struct Constants {
        struct UserDefaults {
            static let DidWatchVideo = "kUserDefaultsDidWatchVideo"
            static let DidWatchInterstitial = "kUserDefaultsDidWatchInterstitial"
        }
    }

    static var didWatchInterstitial: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.UserDefaults.DidWatchInterstitial)
        }

        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaults.DidWatchInterstitial)
        }
    }

    static func didWatchVideo(_ videoURL: URL) -> Bool {
        if let allVideos = UserDefaults.standard.array(forKey: Constants.UserDefaults.DidWatchVideo) as? [String] {
            return allVideos.contains(videoURL.absoluteString)
        }

        return false
    }

    static func setVideoAsWatched(_ videoURL: URL) {
        var allVideos = (UserDefaults.standard.array(forKey: Constants.UserDefaults.DidWatchVideo) as? [String]) ?? [String]()
        if !allVideos.contains(videoURL.absoluteString) {
            allVideos.append(videoURL.absoluteString)
        }

        UserDefaults.standard.set(allVideos, forKey: Constants.UserDefaults.DidWatchVideo)
    }

}
