//
//  NextGenHook.swift
//

import Foundation
import UIKit
import AVFoundation

public enum NextGenAnalyticsEvent: String {
    case homeAction = "home_action"
    case extrasAction = "extras_action"
    case extrasTalentAction = "extras_talent_action"
    case extrasTalentGalleryAction = "extras_talent_gallery_action"
    case extrasVideoGalleryAction = "extras_video_gallery_action"
    case extrasImageGalleryAction = "extras_image_gallery_action"
    case extrasSceneLocationsAction = "extras_scene_locations_action"
    case imeAction = "ime_action"
    case imeExtrasAction = "ime_extras_action"
    case imeLocationAction = "ime_location_action"
    case imeClipShareAction = "ime_clipshare_action"
    case imeTalentAction = "ime_talent_action"
    case imeImageGalleryAction = "ime_image_gallery_action"
}

public enum NextGenAnalyticsAction: String {
    // General
    case exit = "exit"
    
    // Home
    case launchInMovie = "launch_ime"
    case launchExtras = "launch_extras"
    case launchBuy = "launch_buy"
    
    // Extras
    case selectTalent = "select_talent"
    case selectVideoGallery = "select_video_gallery"
    case selectImageGalleries = "select_image_galleries"
    case selectExperienceList = "select_experience_list"
    case selectSceneLocations = "select_scene_locations"
    case selectApp = "select_app"
    case selectShopping = "select_shopping"
    
    // Talent
    case selectGallery = "select_gallery"
    case selectSocial = "select_social"
    case selectFilm = "select_film"
    case selectImage = "select_image"
    
    // Galleries
    case selectVideo = "select_video"
    case setVideoFullScreen = "set_video_full_screen"
    case selectImageGallery = "select_image_gallery"
    case setImageGalleryFullScreen = "set_image_gallery_full_screen"
    case scrollImageGallery = "scroll_image_gallery"
    case shareImage = "share_image"
    
    // Locations
    case setMapType = "set_map_type"
    case selectLocationMarker = "select_location_marker"
    case selectLocationThumbnail = "select_location_thumbnail"
    case selectMap = "select_map"
    
    // TODO: SHOPPING
    
    // IME
    case skipInterstitial = "skip_interstitial"
    case rotateShowExtras = "rotate_show_extras"
    case rotateHideExtras = "rotate_hide_extras"
    case showMore = "show_more"
    case showLess = "show_less"
    case selectClipShare = "select_clipshare"
    case selectLocation = "select_location"
    case selectTrivia = "select_trivia"
    case selectPrevious = "select_previous"
    case selectNext = "select_next"
    case shareVideo = "share_video"
    
    // Player
    case playButton = "play_button"
    case pauseButton = "pause_button"
    case seekSlider = "seek_slider"
    case remotePlayButton = "remote_play_button"
    case remotePauseButton = "remote_pause_button"
    case remoteTogglePlayPauseButton = "remote_toggle_play_pause_button"
    case remoteSkipBackButton = "remote_skip_back_button"
    case remoteSkipForwardButton = "remote_skip_forward_button"
    case showCommentarySelection = "show_commentary_selection"
    case commentaryOn = "commentary_on"
    case commentaryOff = "commentary_off"
    case showCaptionsSelection = "show_captions_selection"
    case captionsOn = "captions_on"
    case captionsOff = "captions_off"
    case cropActiveOn = "crop_active_on"
    case cropActiveOff = "crop_active_off"
    case pictureInPictureOn = "picture_in_picture_on"
    case airPlayOn = "airplay_on"
    case chromecastOn = "chromecast_on"
}

struct NextGenAnalyticsLabel {
    // Locations
    static let road = "road"
    static let satellite = "satellite"
}

public enum NextGenConnectionStatus {
    case onWiFi
    case onCellular
    case off
}

public enum NextGenSharedContentType {
    case image
    case video
}

public protocol NextGenHookDelegate {
    
    // Connection status
    func connectionStatusChanged(status: NextGenConnectionStatus)
    
    // NextGen Experience status
    func experienceWillOpen()
    func experienceWillClose()
    func experienceWillEnterDebugMode()
    
    // Preview mode callbacks
    func previewModeShouldLaunchBuy()
    
    // Video Player callbacks
    func videoPlayerWillClose(_ mode: VideoPlayerMode, playbackPosition: Double)
    func interstitialShouldPlayMultipleTimes() -> Bool
    func updatePlaybackAsset(_ playbackAsset: PlaybackAsset, mode: VideoPlayerMode, isInterstitial: Bool, completion: @escaping (PlaybackAsset) -> Void)
    
    // Sharing callbacks
    func urlForSharedContent(id: String, type: NextGenSharedContentType, completion: @escaping (_ url: URL?) -> Void)
    
    // Talent callbacks
    func didTapFilmography(forTitle title: String, fromViewController viewController: UIViewController)
    
    // Analytics
    func logAnalyticsEvent(_ event: NextGenAnalyticsEvent, action: NextGenAnalyticsAction, itemId: String?, itemName: String?)
}

class NextGenHook {
    
    static var delegate: NextGenHookDelegate?
    
    static func experienceWillClose() {
        delegate?.experienceWillClose()
        NextGenCacheManager.clearTempDirectory()
    }
    
    static func logAnalyticsEvent(_ event: NextGenAnalyticsEvent, action: NextGenAnalyticsAction, itemId: String? = nil, itemName: String? = nil) {
        delegate?.logAnalyticsEvent(event, action: action, itemId: itemId, itemName: itemName)
    }
    
}
