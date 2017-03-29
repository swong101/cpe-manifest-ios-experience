//
//  ExternalPlaybackManager.swift
//

import Foundation

class ExternalPlaybackManager {

    static var isAirPlayActive = false {
        didSet {
            syncExternalPlaybackFlag()
        }
    }

    static var isChromecastActive = false {
        didSet {
            syncExternalPlaybackFlag()
        }
    }

    static var isFireTVActive = false {
        didSet {
            syncExternalPlaybackFlag()
        }
    }

    static var isExternalPlaybackActive = false {
        didSet {
            if isExternalPlaybackActive != oldValue {
                NotificationCenter.default.post(name: .externalPlaybackDidToggle, object: nil, userInfo: [NotificationConstants.isExternalPlaybackActive: isExternalPlaybackActive])
            }
        }
    }

    static private func syncExternalPlaybackFlag() {
        isExternalPlaybackActive = (isAirPlayActive || isChromecastActive || isFireTVActive)
    }

}
