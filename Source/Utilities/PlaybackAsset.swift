//
//  PlaybackAsset.swift
//

import Foundation
import AVFoundation
import GoogleCast

@objc public protocol PlaybackAsset {

    var assetId: String { get }
    var assetURL: URL { get }
    var assetURLAsset: AVURLAsset? { get }
    var assetContentType: String? { get }
    var assetTitle: String? { get }
    var assetImageURL: URL? { get }
    var assetImage: UIImage { get }
    var assetPlaybackPosition: Double { get set }
    var assetPlaybackDuration: Double { get set }
    var assetIsCastable: Bool { get }
    var assetTextTracks: [PlaybackTextTrack]? { get }
    @objc optional var assetCastCustomData: [String: Any]? { get }

}

@objc public enum PlaybackTextTrackType: Int {
    case subtitles = 1
    case captions = 2

    var gckMediaTextTrackSubtype: GCKMediaTextTrackSubtype {
        switch self {
        case .subtitles:
            return .subtitles

        case .captions:
            return .captions
        }
    }
}

@objc public enum PlaybackTextTrackFormat: Int {
    case vtt = 1
    case ttml = 2

    var contentType: String {
        switch self {
        case .vtt:
            return "text/vtt"

        case .ttml:
            return "application/ttml+xml"
        }
    }
}

@objc public protocol PlaybackTextTrack {

    var textTrackType: PlaybackTextTrackType { get }
    var textTrackFormat: PlaybackTextTrackFormat { get }
    var textTrackURL: URL { get }
    var textTrackLanguageCode: String { get }
    @objc optional var textTrackTitle: String? { get }
    @objc optional var textTrackCastCustomData: Any? { get }

}
