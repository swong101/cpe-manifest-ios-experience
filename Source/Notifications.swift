//
//  Notifications.swift
//

import Foundation

extension Notification.Name {

    // Application
    public static let applicationWillResignActive = Notification.Name("CPEExperience.Notifications.applicationWillResignActive")
    public static let applicationWillEnterForeground = Notification.Name("CPEExperience.Notifications.applicationWillEnterForeground")

    // Out-of-Movie Experience
    public static let outOfMovieExperienceShouldLaunch = Notification.Name("CPEExperience.Notifications.outOfMovieExperienceShouldLaunch")

    // In-Movie Experience
    public static let inMovieExperienceShouldCloseDetails = Notification.Name("CPEExperience.Notifications.inMovieExperienceShouldCloseDetails")

    // Video Player
    public static let videoPlayerWillPlayNextItem = Notification.Name("CPEExperience.Notifications.videoPlayerWillPlayNextItem")
    public static let videoPlayerDidChangeTime = Notification.Name("CPEExperience.Notifications.videoPlayerDidChangeTime")
    public static let videoPlayerDidToggleFullScreen = Notification.Name("CPEExperience.Notifications.videoPlayerDidToggleFullScreen")
    public static let videoPlayerDidPlayMainExperience = Notification.Name("CPEExperience.Notifications.videoPlayerDidPlayMainExperience")
    public static let videoPlayerDidPlayVideo = Notification.Name("CPEExperience.Notifications.videoPlayerDidPlayVideo")
    public static let videoPlayerDidEndVideo = Notification.Name("CPEExperience.Notifications.videoPlayerDidEndVideo")
    public static let videoPlayerDidEndLastVideo = Notification.Name("CPEExperience.Notifications.videoPlayerDidEndLastVideo")
    public static let videoPlayerShouldPause = Notification.Name("CPEExperience.Notifications.videoPlayerShouldPause")
    public static let videoPlayerCanResume = Notification.Name("CPEExperience.Notifications.videoPlayerCanResume")
    public static let videoPlayerPlaybackStateDidChange = Notification.Name("CPEExperience.Notifications.videoPlayerPlaybackStateDidChange")
    public static let videoPlayerItemReadyToPlayer = Notification.Name("CPEExperience.Notifications.videoPlayerItemReadyToPlayer")
    public static let videoPlayerPlaybackBufferEmpty = Notification.Name("CPEExperience.Notifications.videoPlayerPlaybackBufferEmpty")
    public static let videoPlayerPlaybackLikelyToKeepUp = Notification.Name("CPEExperience.Notifications.videoPlayerPlaybackLikelyToKeepUp")
    public static let externalPlaybackDidToggle = Notification.Name("CPEExperience.Notifications.externalPlaybackDidToggle")
    public static let availableWirelessRoutesDidChange = Notification.Name("CPEExperience.Notifications.availableWirelessRoutesDidChange")

    // Image Gallery
    public static let imageGalleryDidScrollToPage = Notification.Name("CPEExperience.Notifications.imageGalleryDidScrollToPage")
    public static let imageGalleryDidToggleFullScreen = Notification.Name("CPEExperience.Notifications.imageGalleryDidToggleFullScreen")

    // Locations
    public static let locationsMapTypeDidChange = Notification.Name("CPEExperience.Notifications.locationsMapTypeDidChange")

    // Shopping
    public static let shoppingDidSelectCategory = Notification.Name("CPEExperience.Notifications.shoppingDidSelectCategory")
    public static let shoppingShouldCloseDetails = Notification.Name("CPEExperience.Notifications.shoppingShouldCloseDetails")

}

public struct NotificationConstants {
    public static let categoryID = "categoryID"
    public static let duration = "duration"
    public static let index = "index"
    public static let isFullScreen = "isFullScreen"
    public static let mapType = "mapType"
    public static let page = "page"
    public static let time = "time"
    public static let videoUrl = "videoUrl"
    public static let isExternalPlaybackActive = "isExternalPlaybackActive"
}
