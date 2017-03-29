//
//  ExperienceDelegate.swift
//

import Foundation
import UIKit
import AVFoundation

public enum ConnectionStatus {
    case onWiFi
    case onCellular
    case off
}

public enum SharedContentType {
    case image
    case video
}

public protocol ExperienceDelegate: class {

    // Connection status
    func connectionStatusChanged(status: ConnectionStatus)

    // Experience status
    func experienceWillOpen()
    func experienceWillClose()
    func experienceWillEnterDebugMode()

    // Preview mode callbacks
    func previewModeShouldLaunchBuy()

    // Video Player callbacks
    func interstitialShouldPlayMultipleTimes() -> Bool
    func playbackAsset(withURL url: URL, title: String?, imageURL: URL?, forMode mode: VideoPlayerMode, completion: @escaping (PlaybackAsset) -> Void)
    func didFinishPlayingAsset(_ playbackAsset: PlaybackAsset, mode: VideoPlayerMode)

    // Sharing callbacks
    func urlForSharedContent(id: String, type: SharedContentType, completion: @escaping (_ url: URL?) -> Void)

    // Talent callbacks
    func didTapFilmography(forTitle title: String, fromViewController viewController: UIViewController)

    // Analytics
    func logAnalyticsEvent(_ event: AnalyticsEvent, action: AnalyticsAction, itemId: String?, itemName: String?)

}
