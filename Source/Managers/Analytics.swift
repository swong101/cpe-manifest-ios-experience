//
//  Analytics.swift
//
//

import Foundation

public enum AnalyticsEvent: String {
    case homeAction = "home_action"
    case extrasAction = "extras_action"
    case extrasTalentAction = "extras_talent_action"
    case extrasTalentGalleryAction = "extras_talent_gallery_action"
    case extrasVideoGalleryAction = "extras_video_gallery_action"
    case extrasImageGalleryAction = "extras_image_gallery_action"
    case extrasSceneLocationsAction = "extras_scene_locations_action"
    case extrasShopAction = "extras_shop_action"
    case imeAction = "ime_action"
    case imeExtrasAction = "ime_extras_action"
    case imeLocationAction = "ime_location_action"
    case imeClipShareAction = "ime_clipshare_action"
    case imeTalentAction = "ime_talent_action"
    case imeImageGalleryAction = "ime_image_gallery_action"
    case imeShopAction = "ime_shop_action"
}

public enum AnalyticsAction: String {
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

    // Shopping
    case selectCategory = "select_category"
    case selectProduct = "select_product"
    case selectShareProductLink = "select_share_product_link"
    case selectShopProduct = "select_shop_product"

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

struct AnalyticsLabel {
    // Locations
    static let road = "road"
    static let satellite = "satellite"
}

struct Analytics {

    static func log(event: AnalyticsEvent, action: AnalyticsAction, itemId: String? = nil, itemName: String? = nil) {
        ExperienceLauncher.delegate?.logAnalyticsEvent(event, action: action, itemId: itemId, itemName: itemName)
    }

}
