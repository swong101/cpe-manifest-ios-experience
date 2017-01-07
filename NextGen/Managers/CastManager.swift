//
//  CastManager.swift
//

import UIKit
import GoogleCast

@objc class CastManager: NSObject {
    
    static let sharedInstance = CastManager()
    
    private var currentSession: GCKCastSession? {
        return GCKCastContext.sharedInstance().sessionManager.currentCastSession
    }

    private var currentMediaStatus: GCKMediaStatus? {
        return currentSession?.remoteMediaClient?.mediaStatus
    }
    
    var hasConnectedCastSession: Bool {
        return GCKCastContext.sharedInstance().sessionManager.hasConnectedCastSession()
    }
    
    var currentTime: Double {
        return currentSession?.remoteMediaClient?.approximateStreamPosition() ?? 0
    }
    
    var streamDuration: Double {
        return currentMediaStatus?.mediaInformation?.streamDuration ?? 0
    }
    
    var isPlaying: Bool {
        if let playerState = currentMediaStatus?.playerState {
            return playerState == .playing
        }
        
        return false
    }
    
    func start() {
        GCKCastContext.setSharedInstanceWith(GCKCastOptions(receiverApplicationID: "560D7400"))
        GCKCastContext.sharedInstance().sessionManager.add(self)
        GCKLogger.sharedInstance().delegate = self
    }
    
    func load(_ media: GCKMediaInformation) {
        currentSession?.remoteMediaClient?.loadMedia(media)
    }
    
    func add(remoteMediaClientListener listener: GCKRemoteMediaClientListener) {
        currentSession?.remoteMediaClient?.add(listener)
    }
    
    func playMedia() {
        currentSession?.remoteMediaClient?.play()
    }
    
    func pauseMedia() {
        currentSession?.remoteMediaClient?.pause()
    }
    
    func seekMedia(to time: Double) {
        currentSession?.remoteMediaClient?.seek(toTimeInterval: time, resumeState: .unchanged)
    }
    
}

extension CastManager: GCKSessionManagerListener {
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        print("Cast session started")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        print("Cast session resumed")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        print("Cast session ended with error: \(error)")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        print("Cast session failed to start: \(error)")
    }
    
}

extension CastManager: GCKRemoteMediaClientListener {
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didStartMediaSessionWithID sessionID: Int) {
        print("Remote media client started with ID: \(sessionID)")
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus) {
        print("Remote media client updated media status")
    }
    
}

extension CastManager: GCKLoggerDelegate {
 
    func logMessage(_ message: String, fromFunction function: String) {
        print("GCKLoggerDelegate: \(function) \(message)")
    }
    
}
