//
//  ExternalPlaybackManager.swift
//

import Foundation

public struct ExternalPlaybackManager {

    public static var isAirPlayActive = false {
        didSet {
            syncExternalPlaybackFlag()
        }
    }

    public static var isChromecastActive = false {
        didSet {
            syncExternalPlaybackFlag()
        }
    }

    public static var isFireTVActive = false {
        didSet {
            syncExternalPlaybackFlag()
        }
    }

    public static var isExternalPlaybackActive = false {
        didSet {
            if isExternalPlaybackActive != oldValue {
                NotificationCenter.default.post(name: .externalPlaybackDidToggle, object: nil, userInfo: [NotificationConstants.isExternalPlaybackActive: isExternalPlaybackActive])
            }
        }
    }

    private static func syncExternalPlaybackFlag() {
        isExternalPlaybackActive = (isAirPlayActive || isChromecastActive || isFireTVActive)
    }

}
