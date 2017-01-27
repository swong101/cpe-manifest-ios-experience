//
//  CastManager.swift
//

import GoogleCast

@objc class CastManager: NSObject {
    
    private struct Keys {
        static let AssetId = "assetId"
    }
    
    static let sharedInstance = CastManager()
    
    private var currentSession: GCKCastSession? {
        return GCKCastContext.sharedInstance().sessionManager.currentCastSession
    }

    var currentMediaStatus: GCKMediaStatus? {
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
    
    var currentAssetId: String? {
        return ((currentMediaStatus?.mediaInformation?.customData as? [String: Any])?[Keys.AssetId] as? String)
    }
    
    var currentAssetURL: URL? {
        if let contentID = currentMediaStatus?.mediaInformation?.contentID {
            return URL(string: contentID)
        }
        
        return nil
    }
    
    var isPlaying: Bool {
        if let playerState = currentMediaStatus?.playerState {
            return playerState == .playing
        }
        
        return false
    }
    
    var currentPlaybackAsset: NextGenPlaybackAsset?
    var currentVideoPlayerMode = VideoPlayerMode.unknown
    
    func start(withReceiverAppID receiverAppID: String) {
        GCKCastContext.setSharedInstanceWith(GCKCastOptions(receiverApplicationID: receiverAppID))
        GCKCastContext.sharedInstance().sessionManager.add(self)
        GCKLogger.sharedInstance().delegate = self
    }
    
    func load(media: GCKMediaInformation, playPosition: Double = 0) {
        currentSession?.remoteMediaClient?.loadMedia(media, autoplay: true, playPosition: playPosition)
    }
    
    func load(playbackAsset: NextGenPlaybackAsset) {
        let metadata = GCKMediaMetadata(metadataType: .movie)
        metadata.setString(playbackAsset.assetTitle ?? "", forKey: kGCKMetadataKeyTitle)
        if let imageURL = playbackAsset.assetImageURL {
            metadata.addImage(GCKImage(url: imageURL, width: 0, height: 0))
        }
        
        var mediaTracks: [GCKMediaTrack]?
        if let textTracks = playbackAsset.assetTextTracks {
            mediaTracks = [GCKMediaTrack]()
            for (identifier, textTrack) in textTracks.enumerated() {
                mediaTracks!.append(GCKMediaTrack(
                    identifier: identifier,
                    contentIdentifier: textTrack.textTrackURL.absoluteString,
                    contentType: textTrack.textTrackFormat.contentType,
                    type: .text,
                    textSubtype: textTrack.textTrackType.gckMediaTextTrackSubtype,
                    name: (textTrack.textTrackTitle ?? (Locale(identifier: textTrack.textTrackLanguageCode) as NSLocale).displayName(forKey: .identifier, value: textTrack.textTrackLanguageCode)),
                    languageCode: textTrack.textTrackLanguageCode,
                    customData: (textTrack.textTrackCastCustomData ?? nil)
                ))
            }
        }
        
        var customData = (playbackAsset.assetCastCustomData ?? nil) ?? [String: Any]()
        customData[Keys.AssetId] = playbackAsset.assetId
        
        load(media:GCKMediaInformation(
            contentID: playbackAsset.assetURL.absoluteString,
            streamType: .buffered,
            contentType: (playbackAsset.assetContentType ?? "video/mp4"),
            metadata: metadata,
            streamDuration: 0,
            mediaTracks: mediaTracks,
            textTrackStyle: nil,
            customData: customData
        ), playPosition: playbackAsset.assetPlaybackPosition)
        
        currentPlaybackAsset = playbackAsset
    }
    
    func add(remoteMediaClientListener listener: GCKRemoteMediaClientListener) {
        currentSession?.remoteMediaClient?.add(listener)
    }
    
    func add(sessionManagerListener listener: GCKSessionManagerListener) {
        GCKCastContext.sharedInstance().sessionManager.add(listener)
    }
    
    func remove(remoteMediaClientListener listener: GCKRemoteMediaClientListener) {
        currentSession?.remoteMediaClient?.remove(listener)
    }
    
    func remove(sessionManagerListener listener: GCKSessionManagerListener) {
        GCKCastContext.sharedInstance().sessionManager.remove(listener)
    }
    
    func playMedia() {
        currentSession?.remoteMediaClient?.play()
    }
    
    func pauseMedia() {
        currentSession?.remoteMediaClient?.pause()
    }
    
    func stopMedia() {
        currentSession?.remoteMediaClient?.stop()
    }
    
    func seekMedia(to time: Double) {
        currentSession?.remoteMediaClient?.seek(toTimeInterval: time, resumeState: .play)
    }
    
    func selectTextTrack(withLanguageCode languageCode: String) {
        if let mediaID = currentMediaStatus?.mediaInformation?.mediaTracks?.first(where: { $0.languageCode != nil && $0.languageCode! == languageCode })?.identifier {
            currentSession?.remoteMediaClient?.setActiveTrackIDs([NSNumber(value: mediaID)])
        }
    }
    
    func disableTextTracks() {
        currentSession?.remoteMediaClient?.setActiveTrackIDs(nil)
    }
    
}

extension CastManager: GCKSessionManagerListener {
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        print("Cast session started")
        ExternalPlaybackManager.isChromecastActive = true
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        print("Cast session resumed")
        ExternalPlaybackManager.isChromecastActive = true
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        print("Cast session ended with error: \(error)")
        ExternalPlaybackManager.isChromecastActive = false
        
        if let playbackAsset = currentPlaybackAsset {
            NextGenHook.delegate?.didFinishPlayingAsset(playbackAsset, mode: currentVideoPlayerMode)
            currentPlaybackAsset = nil
        }
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        print("Cast session failed to start: \(error)")
        ExternalPlaybackManager.isChromecastActive = false
        
        currentPlaybackAsset = nil
    }
    
}

extension CastManager: GCKLoggerDelegate {
 
    func logMessage(_ message: String, fromFunction function: String) {
        print("GCKLoggerDelegate: \(function) \(message)")
    }
    
}
