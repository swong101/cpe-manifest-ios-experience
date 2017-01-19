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
    
    static var isExternalPlaybackActive = false
    
    static private func syncExternalPlaybackFlag() {
        isExternalPlaybackActive = (isAirPlayActive || isChromecastActive || isFireTVActive)
    }
    
}
