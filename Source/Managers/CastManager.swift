//
//  CastManager.swift
//

import GoogleCast

@objc open class CastManager: NSObject {

    private struct Keys {
        static let AssetId = "assetId"
    }

    public static let sharedInstance = CastManager()

    public var isInitialized = false

    open var hasDiscoveredDevices: Bool {
        return (isInitialized && GCKCastContext.sharedInstance().discoveryManager.hasDiscoveredDevices)
    }

    open var currentSession: GCKCastSession? {
        if isInitialized {
            return GCKCastContext.sharedInstance().sessionManager.currentCastSession
        }

        return nil
    }

    open var currentMediaStatus: GCKMediaStatus? {
        return currentSession?.remoteMediaClient?.mediaStatus
    }

    open var hasConnectedCastSession: Bool {
        return (isInitialized && GCKCastContext.sharedInstance().sessionManager.hasConnectedCastSession())
    }

    open var currentTime: Double {
        return (currentSession?.remoteMediaClient?.approximateStreamPosition() ?? 0)
    }

    open var streamDuration: Double {
        return (currentMediaStatus?.mediaInformation?.streamDuration ?? 0)
    }

    open var currentAssetId: String? {
        return ((currentMediaStatus?.mediaInformation?.customData as? [String: Any])?[Keys.AssetId] as? String)
    }

    open var currentAssetURL: URL? {
        if let contentID = currentMediaStatus?.mediaInformation?.contentID {
            return URL(string: contentID)
        }

        return nil
    }

    open var currentTextTracks: [GCKMediaTrack]? {
        return currentMediaStatus?.mediaInformation?.mediaTracks?.filter({ $0.type == .text })
    }

    open var isPlaying: Bool {
        return (currentMediaStatus != nil && currentMediaStatus!.playerState == .playing)
    }

    public var currentPlaybackAsset: PlaybackAsset?
    public var currentVideoPlayerMode = VideoPlayerMode.unknown

    open func start(withReceiverAppID receiverAppID: String) {
        GCKCastContext.setSharedInstanceWith(GCKCastOptions(receiverApplicationID: receiverAppID))
        GCKCastContext.sharedInstance().sessionManager.add(self)
        GCKLogger.sharedInstance().delegate = self
        isInitialized = true
    }

    open func load(mediaInfo: GCKMediaInformation, playPosition: Double = 0) {
        currentSession?.remoteMediaClient?.loadMedia(mediaInfo, autoplay: true, playPosition: playPosition)
    }

    open func load(playbackAsset: PlaybackAsset) {
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

        load(mediaInfo: GCKMediaInformation(
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

    open func add(remoteMediaClientListener listener: GCKRemoteMediaClientListener) {
        currentSession?.remoteMediaClient?.add(listener)
    }

    open func add(sessionManagerListener listener: GCKSessionManagerListener) {
        if isInitialized {
            GCKCastContext.sharedInstance().sessionManager.add(listener)
        }
    }

    open func add(discoveryManagerListener listener: GCKDiscoveryManagerListener) {
        if isInitialized {
            GCKCastContext.sharedInstance().discoveryManager.add(listener)
        }
    }

    open func remove(remoteMediaClientListener listener: GCKRemoteMediaClientListener) {
        currentSession?.remoteMediaClient?.remove(listener)
    }

    open func remove(sessionManagerListener listener: GCKSessionManagerListener) {
        if isInitialized {
            GCKCastContext.sharedInstance().sessionManager.remove(listener)
        }
    }

    open func remove(discoveryManagerListener listener: GCKDiscoveryManagerListener) {
        if isInitialized {
            GCKCastContext.sharedInstance().discoveryManager.remove(listener)
        }
    }

    open func playMedia() {
        currentSession?.remoteMediaClient?.play()
    }

    open func pauseMedia() {
        currentSession?.remoteMediaClient?.pause()
    }

    open func stopMedia() {
        currentSession?.remoteMediaClient?.stop()
    }

    open func seekMedia(to time: Double) {
        currentSession?.remoteMediaClient?.seek(toTimeInterval: time, resumeState: .play)
    }

    open func selectTextTrack(withLanguageCode languageCode: String) {
        if let identifier = currentMediaStatus?.mediaInformation?.mediaTracks?.first(where: { $0.languageCode != nil && $0.languageCode! == languageCode })?.identifier {
            selectTextTrack(withIdentifier: identifier)
        }
    }

    open func selectTextTrack(withIdentifier identifier: Int) {
        currentSession?.remoteMediaClient?.setActiveTrackIDs([NSNumber(value: identifier)])
    }

    open func disableTextTracks() {
        currentSession?.remoteMediaClient?.setActiveTrackIDs(nil)
    }

}

extension CastManager: GCKSessionManagerListener {

    public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        print("Cast session started")
        ExternalPlaybackManager.isChromecastActive = true
    }

    public func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        print("Cast session resumed")
        ExternalPlaybackManager.isChromecastActive = true
    }

    public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        print("Cast session ended with error: \(error?.localizedDescription ?? "Unknown error")")
        ExternalPlaybackManager.isChromecastActive = false

        if let playbackAsset = currentPlaybackAsset {
            ExperienceLauncher.delegate?.didFinishPlayingAsset(playbackAsset, mode: currentVideoPlayerMode)
            currentPlaybackAsset = nil
        }
    }

    public func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        print("Cast session failed to start: \(error)")
        ExternalPlaybackManager.isChromecastActive = false

        currentPlaybackAsset = nil
    }

}

extension CastManager: GCKLoggerDelegate {

    public func logMessage(_ message: String, fromFunction function: String) {
        print("GCKLoggerDelegate: \(function) \(message)")
    }

}
