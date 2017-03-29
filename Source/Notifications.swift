//
//  Notifications.swift
//

import Foundation

extension Notification.Name {

    // Application
    public static let applicationWillResignActive = Notification.Name("CPEExperience.Notifications.applicationWillResignActive")
    public static let applicationWillEnterForeground = Notification.Name("CPEExperience.Notifications.applicationWillEnterForeground")

    // Out-of-Movie Experience
    static let outOfMovieExperienceShouldLaunch = Notification.Name("CPEExperience.Notifications.outOfMovieExperienceShouldLaunch")

    // In-Movie Experience
    static let inMovieExperienceShouldCloseDetails = Notification.Name("CPEExperience.Notifications.inMovieExperienceShouldCloseDetails")

    // Video Player
    static let videoPlayerWillPlayNextItem = Notification.Name("CPEExperience.Notifications.videoPlayerWillPlayNextItem")
    static let videoPlayerDidChangeTime = Notification.Name("CPEExperience.Notifications.videoPlayerDidChangeTime")
    static let videoPlayerDidToggleFullScreen = Notification.Name("CPEExperience.Notifications.videoPlayerDidToggleFullScreen")
    static let videoPlayerDidPlayMainExperience = Notification.Name("CPEExperience.Notifications.videoPlayerDidPlayMainExperience")
    static let videoPlayerDidPlayVideo = Notification.Name("CPEExperience.Notifications.videoPlayerDidPlayVideo")
    static let videoPlayerDidEndVideo = Notification.Name("CPEExperience.Notifications.videoPlayerDidEndVideo")
    static let videoPlayerDidEndLastVideo = Notification.Name("CPEExperience.Notifications.videoPlayerDidEndLastVideo")
    static let videoPlayerShouldPause = Notification.Name("CPEExperience.Notifications.videoPlayerShouldPause")
    static let videoPlayerCanResume = Notification.Name("CPEExperience.Notifications.videoPlayerCanResume")
    static let videoPlayerPlaybackStateDidChange = Notification.Name("CPEExperience.Notifications.videoPlayerPlaybackStateDidChange")
    static let videoPlayerItemReadyToPlayer = Notification.Name("CPEExperience.Notifications.videoPlayerItemReadyToPlayer")
    static let videoPlayerPlaybackBufferEmpty = Notification.Name("CPEExperience.Notifications.videoPlayerPlaybackBufferEmpty")
    static let videoPlayerPlaybackLikelyToKeepUp = Notification.Name("CPEExperience.Notifications.videoPlayerPlaybackLikelyToKeepUp")
    static let externalPlaybackDidToggle = Notification.Name("CPEExperience.Notifications.externalPlaybackDidToggle")
    static let availableWirelessRoutesDidChange = Notification.Name("CPEExperience.Notifications.availableWirelessRoutesDidChange")

    // Image Gallery
    static let imageGalleryDidScrollToPage = Notification.Name("CPEExperience.Notifications.imageGalleryDidScrollToPage")
    static let imageGalleryDidToggleFullScreen = Notification.Name("CPEExperience.Notifications.imageGalleryDidToggleFullScreen")

    // Locations
    static let locationsMapTypeDidChange = Notification.Name("CPEExperience.Notifications.locationsMapTypeDidChange")

    // Shopping
    static let shoppingDidSelectCategory = Notification.Name("CPEExperience.Notifications.shoppingDidSelectCategory")
    static let shoppingShouldCloseDetails = Notification.Name("CPEExperience.Notifications.shoppingShouldCloseDetails")

}

struct NotificationConstants {
    static let categoryID = "categoryID"
    static let duration = "duration"
    static let index = "index"
    static let isFullScreen = "isFullScreen"
    static let mapType = "mapType"
    static let page = "page"
    static let time = "time"
    static let videoUrl = "videoUrl"
    static let isExternalPlaybackActive = "isExternalPlaybackActive"
}
