//
//  VideoPlayerViewController.swift
//

import Foundation
import UIKit
import MessageUI
import CoreMedia
import NextGenDataManager
import UAProgressView
import MBProgressHUD

public enum VideoPlayerMode {
    case mainFeature
    case supplemental
    case supplementalInMovie
    case basicPlayer
}

public enum VideoPlayerState {
    case unknown
    case readyToPlay
    case videoLoading
    case videoSeeking
    case videoPlaying
    case videoPaused
    case suspended
    case dismissed
    case error
}

protocol VideoPlayerDelegate {
    func videoPlayer(_ videoPlayer: VideoPlayerViewController, isBuffering: Bool)
}

class VideoPlayerPlaybackView: UIView {
    
    override class var layerClass: AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }
    
    var player: AVPlayer? {
        get {
            return (self.layer as? AVPlayerLayer)?.player
        }
        
        set {
            (self.layer as? AVPlayerLayer)?.player = newValue
        }
    }
    
    var videoFillMode = AVLayerVideoGravityResizeAspect {
        didSet {
            if let playerLayer = self.layer as? AVPlayerLayer {
                CATransaction.begin()
                CATransaction.setAnimationDuration(0)
                CATransaction.setDisableActions(true)
                playerLayer.videoGravity = videoFillMode
                CATransaction.commit()
            }
        }
    }
    
    func toggleVideoFillMode() {
        videoFillMode = (videoFillMode == AVLayerVideoGravityResizeAspectFill ? AVLayerVideoGravityResizeAspect : AVLayerVideoGravityResizeAspectFill)
    }
    
}

class VideoPlayerViewController: UIViewController {
    
    private struct Constants {
        static let CountdownTimeInterval: CGFloat = 1
        static let CountdownTotalTime: CGFloat = 5
        static let PlayerControlsAutoHideTime = 5.0
        
        struct Keys {
            static let Status = "status"
            static let Duration = "duration"
            static let PlaybackBufferEmpty = "playbackBufferEmpty"
            static let PlaybackLikelyToKeepUp = "playbackLikelyToKeepUp"
            static let CurrentItem = "currentItem"
            static let Rate = "rate"
            static let Tracks = "tracks"
            static let Playable = "playable"
        }
    }
    
    var delegate: VideoPlayerDelegate?
    var mode = VideoPlayerMode.supplemental
    var shouldMute = false
    var shouldTrackOutput = false
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playerItemVideoOutput: AVPlayerItemVideoOutput?
    private var originalContainerView: UIView?
    
    // State
    private var didPlayInterstitial = false
    private var isManuallyPaused = false
    private var isSeeking = false
    private var lastNotifiedTime = -1.0
    var isMuted: Bool {
        get {
            return player?.isMuted ?? true
        }
        
        set {
            player?.isMuted = newValue
        }
    }
    
    private var VideoPlayerStatusObservationContext = 0
    private var VideoPlayerDurationObservationContext = 1
    private var VideoPlayerBufferEmptyObservationContext = 2
    private var VideoPlayerPlaybackLikelyToKeepUpObservationContext = 3
    private var VideoPlayerCurrentItemObservationContext = 4
    private var VideoPlayerRateObservationContext = 5
    
    private var state = VideoPlayerState.unknown {
        didSet {
            switch state {
            case .unknown:
                removePlayerTimeObserver()
                syncScrubber()
                break
                
            case .readyToPlay:
                // Play from playbackSyncStartTime
                if playbackSyncStartTime > 1 && !hasSeekedToPlaybackSyncStartTime {
                    if !isSeeking {
                        seekPlayer(to: playbackSyncStartTime)
                    }
                } else {
                    // Start from either beginning or from wherever left off
                    hasSeekedToPlaybackSyncStartTime = true
                    if !isPlaying {
                        playVideo()
                    }
                }
                
                // Scrubber timer
                initScrubberTimer()
                
                // Hide activity indicator
                activityIndicatorVisible = false
                
                // Enable (not show) controls
                playerControlsEnabled = true
                break
                
            case .videoPlaying:
                // Hide activity indicator
                activityIndicatorVisible = false
                
                // Enable (not show) controls
                playerControlsEnabled = true
                
                // Auto Hide Timer
                initAutoHideTimer()
                break
                
            case .videoPaused:
                // Hide activity indicator
                activityIndicatorVisible = false
                
                // Enable (not show) controls
                playerControlsEnabled = true
                break
                
            case .videoSeeking, .videoLoading:
                // Show activity indicator
                activityIndicatorVisible = true
                break
                
            default:
                break
            }
            
            NotificationCenter.default.post(name: .videoPlayerPlaybackStateDidChange, object: self)
        }
    }
    
    private var isPlaying: Bool {
        return (previousScrubbingRate != 0 || (player != nil && player!.rate != 0))
    }
    
    private var isPlaybackLikelyToKeepUp: Bool {
        return playerItem?.isPlaybackLikelyToKeepUp ?? false
    }
    
    private var isPlaybackBufferEmpty: Bool {
        return playerItem?.isPlaybackBufferEmpty ?? false
    }
    
    // Asset
    var url: URL? {
        return (playerItem?.asset as? AVURLAsset)?.url
    }

    // Controls
    @IBOutlet weak private var playbackView: VideoPlayerPlaybackView!
    @IBOutlet weak private var topToolbar: UIView?
    @IBOutlet weak private var playbackToolbar: UIView?
    @IBOutlet weak private var homeButton: UIButton?
    @IBOutlet weak private var scrubber: UISlider?
    @IBOutlet weak private var timeElapsedLabel: UILabel?
    @IBOutlet weak private var durationLabel: UILabel?
    @IBOutlet weak private var cropToActivePictureButton: UIButton?
    @IBOutlet weak private var playButton: UIButton?
    @IBOutlet weak private var pauseButton: UIButton?
    @IBOutlet weak private var subtitlesButton: UIButton?
    @IBOutlet weak var fullScreenButton: UIButton?
    private var previousScrubbingRate: Float = 0
    
    private var playerControlsAutoHideTimer: Timer?
    
    private var isScrubbing: Bool {
        return (previousScrubbingRate != 0)
    }
    
    private var playerControlsEnabled = false {
        didSet {
            scrubber?.isEnabled = playerControlsEnabled
            playButton?.isEnabled = playerControlsEnabled
            pauseButton?.isEnabled = playerControlsEnabled
            subtitlesButton?.isEnabled = playerControlsEnabled
            fullScreenButton?.isEnabled = playerControlsEnabled
        }
    }
    
    private var playerControlsVisible = false {
        didSet {
            if let topToolbar = topToolbar {
                if playerControlsVisible {
                    topToolbar.isHidden = false
                    UIView.animate(withDuration: 0.2, animations: {
                        topToolbar.transform = .identity
                    })
                } else {
                    UIView.animate(withDuration: 0.2, animations: {
                        topToolbar.transform = CGAffineTransform(translationX: 0, y: -topToolbar.bounds.height)
                    }, completion: { (_) in
                        topToolbar.isHidden = true
                    })
                }
            }
            
            if let playbackToolbar = playbackToolbar {
                if playerControlsVisible {
                    playbackToolbar.isHidden = false
                    UIView.animate(withDuration: 0.2, animations: {
                        playbackToolbar.transform = .identity
                    })
                } else {
                    UIView.animate(withDuration: 0.2, animations: {
                        playbackToolbar.transform = CGAffineTransform(translationX: 0, y: playbackToolbar.bounds.height)
                    }, completion: { (_) in
                        playbackToolbar.isHidden = true
                    })
                }
            }
        }
    }
    
    private var playerControlsLocked = false {
        didSet {
            if playerControlsLocked {
                topToolbar?.isHidden = true
                playbackToolbar?.isHidden = true
            }
        }
    }
    
    private var activityIndicator: MBProgressHUD?
    private var activityIndicatorVisible = false {
        didSet {
            if activityIndicatorVisible {
                if activityIndicator == nil {
                    activityIndicator = MBProgressHUD.showAdded(to: self.playbackView, animated: true)
                }
            } else {
                activityIndicator?.hide(true)
                activityIndicator = nil
            }
        }
    }
    
    // Playback Sync
    private var playbackSyncStartTime: Double = 0
    private var hasSeekedToPlaybackSyncStartTime = false
    
    private var isFullScreen = false {
        didSet {
            fullScreenButton?.setImage(UIImage(named: (isFullScreen ? "Minimize" : "Maximize")), for: .normal)
            fullScreenButton?.setImage(UIImage(named: (isFullScreen ? "Minimize Highlighted" : "Maximize Highlighted")), for: .highlighted)
            
            if isFullScreen {
                originalContainerView = self.view.superview
                UIApplication.shared.keyWindow?.addSubview(self.view)
            } else {
                originalContainerView?.addSubview(self.view)
                originalContainerView = nil
            }
            
            if let bounds = self.view.superview?.bounds {
                self.view.frame = bounds
            }
            
            NotificationCenter.default.post(name: .videoPlayerDidToggleFullScreen, object: nil, userInfo: [NotificationConstants.isFullScreen: isFullScreen])
        }
    }
    
    private var playerItemDuration: Double {
        if let playerItem = playerItem, CMTIME_IS_VALID(playerItem.duration), playerItem.duration.seconds.isFinite {
            return playerItem.duration.seconds
        }
        
        return 0
    }
    
    var currentTime: Double {
        if let seconds = playerItem?.currentTime().seconds, !seconds.isNaN, seconds.isFinite {
            return seconds
        }
        
        return 0
    }
    
    // Countdown/Queue
    var queueTotalCount = 0
    var queueCurrentIndex = 0
    private var countdownSeconds: CGFloat = 0 {
        didSet {
            countdownLabel.text = String.localize("label.time.seconds", variables: ["count": String(Int(Constants.CountdownTotalTime - countdownSeconds))])
            countdownProgressView?.setProgress(((countdownSeconds + 1) / Constants.CountdownTotalTime), animated: true)
        }
    }
    
    private var countdownTimer: Timer?
    private var countdownProgressView: UAProgressView?
    @IBOutlet weak private var countdownLabel: UILabel!
    
    // Skip interstitial
    @IBOutlet weak private var skipContainerView: UIView!
    @IBOutlet weak private var skipCountdownContainerView: UIView!
    @IBOutlet private var skipContainerLandscapeHeightConstraint: NSLayoutConstraint?
    @IBOutlet private var skipContainerPortraitHeightConstraint: NSLayoutConstraint?
    
    // Notifications & Observers
    private var playerItemDurationDidLoadObserver: NSObjectProtocol?
    private var videoPlayerDidPlayVideoObserver: NSObjectProtocol?
    private var sceneDetailWillCloseObserver: NSObjectProtocol?
    private var videoPlayerShouldPauseObserver: NSObjectProtocol?
    private var playerTimeObserver: Any?
    
    deinit {
        let center = NotificationCenter.default
        
        if let observer = playerItemDurationDidLoadObserver {
            center.removeObserver(observer)
            playerItemDurationDidLoadObserver = nil
        }
        
        if let observer = videoPlayerDidPlayVideoObserver {
            center.removeObserver(observer)
            videoPlayerDidPlayVideoObserver = nil
        }
        
        if let observer = sceneDetailWillCloseObserver {
            center.removeObserver(observer)
            sceneDetailWillCloseObserver = nil
        }
        
        if let observer = videoPlayerShouldPauseObserver {
            center.removeObserver(observer)
            videoPlayerShouldPauseObserver = nil
        }
        
        playerItem?.removeObserver(self, forKeyPath: Constants.Keys.Status)
        playerItem?.removeObserver(self, forKeyPath: Constants.Keys.Duration)
        playerItem?.removeObserver(self, forKeyPath: Constants.Keys.PlaybackBufferEmpty)
        playerItem?.removeObserver(self, forKeyPath: Constants.Keys.PlaybackLikelyToKeepUp)
        player?.removeObserver(self, forKeyPath: Constants.Keys.CurrentItem)
        player?.removeObserver(self, forKeyPath: Constants.Keys.Rate)
        removePlayerTimeObserver()
        cancelCountdown()
    }
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        // Setup audio to be heard even if device is on silent
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            print("Error setting AVAudioSession category: \(error)")
        }
        
        self.playbackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onTapPlayer)))
        
        isSeeking = false
        initScrubberTimer()
        syncPlayPauseButtons()
        syncScrubber()
        
        skipContainerView.isHidden = true
        skipContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onTapSkip)))
        
        // Localizations
        homeButton?.setTitle(String.localize("label.home"), for: UIControlState())
        
        // Notifications
        playerItemDurationDidLoadObserver = NotificationCenter.default.addObserver(forName: .videoPlayerItemDurationDidLoad, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            if let strongSelf = self, let duration = notification.userInfo?[NotificationConstants.duration] as? Double, strongSelf.countdownProgressView == nil {
                let progressView = UAProgressView(frame: strongSelf.skipCountdownContainerView.frame)
                progressView.borderWidth = 0
                progressView.lineWidth = 2
                progressView.fillOnTouch = false
                progressView.tintColor = UIColor.white
                progressView.animationDuration = duration
                strongSelf.skipContainerView.addSubview(progressView)
                strongSelf.countdownProgressView = progressView
                strongSelf.countdownProgressView?.setProgress(1, animated: true)
            }
        })
        
        videoPlayerDidPlayVideoObserver = NotificationCenter.default.addObserver(forName: .videoPlayerDidPlayVideo, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            if let strongSelf = self, strongSelf.didPlayInterstitial {
                if let videoURL = notification.userInfo?[NotificationConstants.videoUrl] as? URL, videoURL != strongSelf.url {
                    strongSelf.pauseVideo()
                }
            }
        })
        
        videoPlayerShouldPauseObserver = NotificationCenter.default.addObserver(forName: .videoPlayerShouldPause, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
            if let strongSelf = self, strongSelf.mode == .mainFeature {
                strongSelf.pauseVideo()
            }
        })
        
        sceneDetailWillCloseObserver = NotificationCenter.default.addObserver(forName: .inMovieExperienceWillCloseDetails, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            if let strongSelf = self, strongSelf.mode == .mainFeature && !strongSelf.isManuallyPaused {
                strongSelf.playVideo()
            }
        })
        
        if !DeviceType.IS_IPAD {
            cropToActivePictureButton?.removeFromSuperview()
        }

        if mode == .mainFeature {
            fullScreenButton?.removeFromSuperview()
            
            if let delegate = NextGenHook.delegate {
                didPlayInterstitial = SettingsManager.didWatchInterstitial && !delegate.interstitialShouldPlayMultipleTimes()
            }
            
            playMainExperience()
        } else {
            didPlayInterstitial = true
            playerControlsVisible = false
            topToolbar?.removeFromSuperview()
            cropToActivePictureButton?.removeFromSuperview()
            
            if mode == .supplementalInMovie {
                fullScreenButton?.removeFromSuperview()
            } else if mode == .basicPlayer {
                playbackToolbar?.removeFromSuperview()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        pauseVideo()
        super.viewWillDisappear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if didPlayInterstitial {
            playerControlsVisible = true
            initAutoHideTimer()
        } else {
            countdownProgressView?.frame = skipCountdownContainerView.frame
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if !didPlayInterstitial {
            let currentOrientation = UIApplication.shared.statusBarOrientation
            skipContainerLandscapeHeightConstraint?.isActive = UIInterfaceOrientationIsLandscape(currentOrientation)
            skipContainerPortraitHeightConstraint?.isActive = UIInterfaceOrientationIsPortrait(currentOrientation)
            countdownProgressView?.frame = skipCountdownContainerView.frame
        }
    }
    
    private func setViewDisplayName() {
        /* If the item has a AVMetadataCommonKeyTitle metadata, use that instead. */
        if let items = playerItem?.asset.commonMetadata {
            for item in items {
                if item.commonKey == AVMetadataCommonKeyTitle {
                    self.title = item.stringValue
                    return
                }
            }
        }
        
        /* Or set the view title to the last component of the asset URL. */
        self.title = url?.lastPathComponent
    }
    
    private func display(error: NSError) {
        let alertController = UIAlertController(title: "", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Video Playback
    /* ---------------------------------------------------------
     **  Called when the value at the specified key path relative
     **  to the given object has changed.
     **  Adjust the movie play and pause button controls when the
     **  player item "status" value changes. Update the movie
     **  scrubber control when the player item is ready to play.
     **  Adjust the movie scrubber control when the player item
     **  "rate" value changes. For updates of the player
     **  "currentItem" property, set the AVPlayer for which the
     **  player layer displays visual output.
     **  NOTE: this method is invoked on the main queue.
     ** ------------------------------------------------------- */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        /* AVPlayerItem "status" property value observer. */
        if context == &VideoPlayerStatusObservationContext {
            if let statusNumber = (change?[NSKeyValueChangeKey.newKey] as? NSNumber)?.intValue, let status = AVPlayerStatus(rawValue: statusNumber) {
                switch status {
                    /* Indicates that the status of the player is not yet known because
                     it has not tried to load new media resources for playback */
                case .unknown:
                    state = .unknown
                    break
                    
                case .readyToPlay:
                    /* Once the AVPlayerItem becomes ready to play, i.e.
                     [playerItem status] == AVPlayerItemStatusReadyToPlay,
                     its duration can be fetched from the item. */
                    
                    if state != .videoPlaying {
                        state = .readyToPlay
                        NotificationCenter.default.post(name: .videoPlayerItemReadyToPlayer, object: nil)
                    }
                    break
                    
                case .failed:
                    if let error = (object as? AVPlayerItem)?.error as? NSError {
                        assetFailedToPrepareForPlayback(error: error)
                    }
                    break
                }
            }
        }
        // AVPlayer "duration" property value observer
        else if context == &VideoPlayerDurationObservationContext {
            if playerItemDuration > 1 {
                durationLabel?.text = timeString(fromSeconds: playerItemDuration)
                NotificationCenter.default.post(name: .videoPlayerItemDurationDidLoad, object: self, userInfo: [Constants.Keys.Duration: playerItemDuration])
            }
        }
        /* AVPlayer "rate" property value observer. */
        else if context == &VideoPlayerRateObservationContext {
            if let newRate = change?[NSKeyValueChangeKey.newKey] as? Bool, newRate {
                state = .videoPlaying
            } else {
                state = .videoPaused
            }
        }
        /* AVPlayer "currentItem" property observer.
         Called when the AVPlayer replaceCurrentItemWithPlayerItem:
         replacement will/did occur. */
        else if context == &VideoPlayerCurrentItemObservationContext {
            /* Replacement of player currentItem has occurred */
            if (change?[NSKeyValueChangeKey.newKey] as? AVPlayerItem) != nil {
                /* Set the AVPlayer for which the player layer displays visual output. */
                playbackView.player = player
                setViewDisplayName()
            } else {
                playerControlsEnabled = false
            }
        }
        else if context == &VideoPlayerBufferEmptyObservationContext {
            state = .videoLoading
            if isPlaybackBufferEmpty && currentTime > 0 && currentTime < (playerItemDuration - 1) && isPlaying {
                delegate?.videoPlayer(self, isBuffering: true)
                NotificationCenter.default.post(name: .videoPlayerPlaybackBufferEmpty, object: nil)
            }
        }
        else if context == &VideoPlayerPlaybackLikelyToKeepUpObservationContext {
            if state != .videoPaused && !isPlaying && isPlaybackLikelyToKeepUp {
                delegate?.videoPlayer(self, isBuffering: false)
                NotificationCenter.default.post(name: .videoPlayerPlaybackLikelyToKeepUp, object: nil)
                
                if !isSeeking && hasSeekedToPlaybackSyncStartTime {
                    playVideo()
                }
            }
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
        playbackView.videoFillMode = (didPlayInterstitial && mode != .basicPlayer ? AVLayerVideoGravityResizeAspect : AVLayerVideoGravityResizeAspectFill)
        syncPlayPauseButtons()
        
        if mode == .basicPlayer {
            player?.actionAtItemEnd = .none
        }
        
    }
    
    /* --------------------------------------------------------------
     **  Called when an asset fails to prepare for playback for any of
     **  the following reasons:
     **
     **  1) values of asset keys did not load successfully,
     **  2) the asset keys did load successfully, but the asset is not
     **     playable
     **  3) the item did not become ready to play.
     ** ----------------------------------------------------------- */
    private func assetFailedToPrepareForPlayback(error: NSError?) {
        state = .error
        removePlayerTimeObserver()
        syncScrubber()
        playerControlsEnabled = false
        
        print("Asset failed to prepare for playback with error: \(error)")
        
        if let error = error {
            display(error: error)
        }
    }
    
    /*
     Invoked at the completion of the loading of the values for all keys on the asset that we require.
     Checks whether loading was successfull and whether the asset is playable.
     If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
     */
    private func prepareToPlay(asset: AVURLAsset, withKeys keys: [String]? = nil) {
        state = .videoLoading
        
        /* Make sure that the value of each key has loaded successfully. */
        if let keys = keys {
            for key in keys {
                let error: NSErrorPointer = nil
                let status = asset.statusOfValue(forKey: key, error: error)
                if status == .failed {
                    assetFailedToPrepareForPlayback(error: error?.pointee)
                    return
                }
            }
        }
        
        /* Use the AVAsset playable property to detect whether the asset can be played. */
        if !asset.isPlayable {
            /* Generate and show an error describing the failure. */
            let errorDict = [NSLocalizedDescriptionKey: NSLocalizedString("player-generalError"), NSLocalizedFailureReasonErrorKey: NSLocalizedString("player-asset-tracks-load-error")]
            assetFailedToPrepareForPlayback(error: NSError(domain: "VideoPlayer", code: 0, userInfo: errorDict))
            return
        }
        
        // At this point we're ready to set up for playback of the asset.
            
        // Stop observing our prior AVPlayerItem, if we have one.
        if let playerItem = playerItem {
            playerItem.removeObserver(self, forKeyPath: Constants.Keys.Status)
            playerItem.removeObserver(self, forKeyPath: Constants.Keys.Duration)
            playerItem.removeObserver(self, forKeyPath: Constants.Keys.PlaybackBufferEmpty)
            playerItem.removeObserver(self, forKeyPath: Constants.Keys.PlaybackLikelyToKeepUp)
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
        
        // Create a new instance of AVPlayerItem from the now successfully loaded AVAsset.
        playerItem = AVPlayerItem(asset: asset)
        playerItem!.addObserver(self, forKeyPath: Constants.Keys.Status, options: [.initial, .new], context: &VideoPlayerStatusObservationContext)
        playerItem!.addObserver(self, forKeyPath: Constants.Keys.Duration, options: [.initial, .new], context: &VideoPlayerDurationObservationContext)
        playerItem!.addObserver(self, forKeyPath: Constants.Keys.PlaybackBufferEmpty, options: .new, context: &VideoPlayerBufferEmptyObservationContext)
        playerItem!.addObserver(self, forKeyPath: Constants.Keys.PlaybackLikelyToKeepUp, options: .new, context: &VideoPlayerPlaybackLikelyToKeepUpObservationContext)
        
        /* When the player item has played to its end time we'll toggle
         the movie controller Pause button to be the Play button */
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        /* Create new player, if we don't already have one. */
        if player == nil {
            /* Get a new AVPlayer initialized to play the specified player item. */
            player = AVPlayer(playerItem: playerItem)
            
            /* Observe the AVPlayer "currentItem" property to find out when any
             AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did occur.*/
            player!.addObserver(self, forKeyPath: Constants.Keys.CurrentItem, options: [.initial, .new], context: &VideoPlayerCurrentItemObservationContext)
            
            /* Observe the AVPlayer "rate" property to update the scrubber control. */
            player!.addObserver(self, forKeyPath: Constants.Keys.Rate, options: [.initial, .new], context: &VideoPlayerRateObservationContext)
        }
        
        /* Make our new AVPlayerItem the AVPlayer's current item. */
        if player!.currentItem != playerItem {
            /* Replace the player item with a new player item. The item replacement occurs 
             asynchronously; observe the currentItem property to find out when the 
             replacement will/did occur
             
             If needed, configure player item here (example: adding outputs, setting text style rules,
             selecting media options) before associating it with a player
             */
            
            player!.replaceCurrentItem(with: playerItem)
        }
        
        scrubber?.value = 0
    }
    
    func removeCurrentItem() {
        player?.replaceCurrentItem(with: nil)
    }
    
    private func playVideo() {
        isManuallyPaused = false
        
        // Play
        player?.play()
        
        // Immediately show pause button. NOTE: syncPlayPauseButtons will actually update this
        // to reflect the playback "rate", e.g. 0.0 will automatically show the pause button.
        showPauseButton()
        
        // Send notification
        NotificationCenter.default.post(name: .videoPlayerDidPlayVideo, object: nil, userInfo: [NotificationConstants.videoUrl: url])
    }
    
    private func pauseVideo() {
        // Pause media
        player?.pause()
        
        // Immediately show play button. NOTE: syncPlayPauseButtons will actually update this
        // to reflect the playback "rate", e.g. 0.0 will automatically show the pause button.
        showPlayButton()
    }
    
    func play(asset: AVURLAsset, fromStartTime startTime: Double = 0) {
        cancelCountdown()
        
        playbackSyncStartTime = startTime
        hasSeekedToPlaybackSyncStartTime = false
        
        let requestedKeys = [Constants.Keys.Tracks, Constants.Keys.Playable]
        /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
        asset.loadValuesAsynchronously(forKeys: requestedKeys) { [weak self] in
            /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
            DispatchQueue.main.async {
                self?.prepareToPlay(asset: asset, withKeys: requestedKeys)
            }
        }
    }
    
    func play(url: URL, fromStartTime startTime: Double = 0) {
        SettingsManager.setVideoAsWatched(url)
        NextGenHook.delegate?.videoAsset(forUrl: url, mode: mode, isInterstitial: !didPlayInterstitial, completion: { [weak self] (asset, startTime) in
            self?.play(asset: asset, fromStartTime: startTime)
        })
    }
    
    // MARK: Main Feature
    private func playMainExperience() {
        playerControlsVisible = false
        countdownProgressView?.removeFromSuperview()
        countdownProgressView = nil
        
        if !didPlayInterstitial {
            if let videoURL = NGDMManifest.sharedInstance.mainExperience?.interstitialVideoURL {
                play(url: videoURL)
                
                playerControlsLocked = true
                skipContainerView.isHidden = !SettingsManager.didWatchInterstitial
                SettingsManager.didWatchInterstitial = true
                return
            }
            
            didPlayInterstitial = true
        }
        
        playerControlsLocked = false
        skipContainerView.isHidden = true
        if let videoURL = NGDMManifest.sharedInstance.mainExperience?.videoURL {
            NotificationCenter.default.post(name: .videoPlayerDidPlayMainExperience, object: nil)
            play(url: videoURL)
        }
    }
    
    private func skipInterstitial() {
        pauseVideo()
        removeCurrentItem()
        didPlayInterstitial = true
        playMainExperience()
        NextGenHook.logAnalyticsEvent(.imeAction, action: .skipInterstitial)
    }
    
    /* Set the scrubber based on the player current time. */
    private func syncScrubber() {
        updateTimeLabels(time: currentTime)
        //activityIndicatorVisible = false
        
        if let scrubber = scrubber {
            if playerItemDuration > 0 {
                let minValue = scrubber.minimumValue
                scrubber.value = (scrubber.maximumValue - minValue) * Float(currentTime) / Float(playerItemDuration) + minValue
            } else {
                scrubber.minimumValue = 0
            }
        }
        
        if player != nil && (mode == .mainFeature || mode == .basicPlayer) {
            if lastNotifiedTime != currentTime {
                lastNotifiedTime = currentTime
                NotificationCenter.default.post(name: .videoPlayerDidChangeTime, object: nil, userInfo: [NotificationConstants.time: Double(currentTime)])
            }
            
            if currentTime >= 1 && mode == .basicPlayer {
                activityIndicator?.removeFromSuperview()
            }
            
            player!.isMuted = shouldMute
            if shouldTrackOutput, let playerItem = playerItem, playerItem.outputs.count == 0 {
                playerItem.add(AVPlayerItemVideoOutput())
            }
        }
    }
    
    func playerItemDidReachEnd(_ notification: Notification!) {
        if let playerItem = notification.object as? AVPlayerItem, playerItem == self.playerItem {
            if !didPlayInterstitial {
                didPlayInterstitial = true
                playMainExperience()
                return
            }
            
            queueCurrentIndex += 1
            if queueCurrentIndex < queueTotalCount {
                pauseVideo()
                
                countdownLabel.isHidden = false
                countdownLabel.frame.origin = CGPoint(x: 30, y: 20)
                
                let progressView = UAProgressView(frame: countdownLabel.frame)
                progressView.centralView = countdownLabel
                progressView.borderWidth = 0
                progressView.lineWidth = 2
                progressView.fillOnTouch = false
                progressView.tintColor = UIColor.themePrimary
                progressView.animationDuration = Double(Constants.CountdownTimeInterval)
                self.view.addSubview(progressView)
                countdownProgressView = progressView
                
                countdownSeconds = 0
                countdownTimer = Timer.scheduledTimer(timeInterval: Double(Constants.CountdownTimeInterval), target: self, selector: #selector(self.onCountdownTimerFired), userInfo: nil, repeats: true)
            } else {
                NotificationCenter.default.post(name: .videoPlayerDidEndLastVideo, object: nil)
            }
            
            NotificationCenter.default.post(name: .videoPlayerDidEndVideo, object: nil)
            
            if mode == .mainFeature {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                    NextGenHook.delegate?.videoPlayerWillClose(self.mode, playbackPosition: 0)
                    self.dismiss(animated: true, completion: {
                        NotificationCenter.default.post(name: .outOfMovieExperienceShouldLaunch, object: nil)
                    })
                }
            }
        }
    }
    
    func onCountdownTimerFired() {
        countdownSeconds += Constants.CountdownTimeInterval
        
        if countdownSeconds >= Constants.CountdownTotalTime {
            if let timer = countdownTimer {
                timer.invalidate()
                countdownTimer = nil
            }
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(Constants.CountdownTimeInterval) * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                self.cancelCountdown()
                NotificationCenter.default.post(name: .videoPlayerWillPlayNextItem, object: nil, userInfo: [NotificationConstants.index: self.queueCurrentIndex])
            }
        }
    }
    
    private func cancelCountdown() {
        if let timer = countdownTimer {
            timer.invalidate()
            countdownTimer = nil
        }
        
        countdownLabel.isHidden = true
        countdownProgressView?.removeFromSuperview()
        countdownProgressView = nil
    }
    
    func getScreenGrab() -> UIImage? {
        if let playerItem = playerItem, let playerItemVideoOutput = playerItem.outputs.first as? AVPlayerItemVideoOutput {
            if let cvPixelBuffer = playerItemVideoOutput.copyPixelBuffer(forItemTime: playerItem.currentTime(), itemTimeForDisplay: nil) {
                return UIImage(ciImage: CIImage(cvPixelBuffer: cvPixelBuffer))
            }
        }
        
        return nil
    }
    
    private func updateTimeLabels(time: Double) {
        // Update time labels
        timeElapsedLabel?.text = timeString(fromSeconds: time)
    }
    
    private func timeString(fromSeconds seconds: Double) -> String? {
        let hours = Int(floor(seconds / 3600))
        let minutes = Int(floor((seconds / 60).truncatingRemainder(dividingBy: 60)))
        let secs = Int(floor(seconds.truncatingRemainder(dividingBy: 60)))
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    private func timeValue(forSlider slider: UISlider) -> Double {
        if playerItemDuration > 0 {
            let minValue = slider.minimumValue
            return Double(Float(playerItemDuration) * (slider.value - minValue) / (slider.maximumValue - minValue))
        }
        
        return 0
    }
    
    func seekPlayer(to time: Double) {
        isSeeking = true
        state = .videoSeeking
        
        player?.seek(to: CMTimeMakeWithSeconds(time, 1), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { [weak self] (finished) in
            if finished {
                DispatchQueue.main.async {
                    self?.isSeeking = false
                    self?.hasSeekedToPlaybackSyncStartTime = true
                    self?.playVideo()
                }
            }
        })
    }
    
    // MARK: Actions
    @IBAction private func onTapPlayer() {
        if !playerControlsLocked {
            playerControlsVisible = !playerControlsVisible
            initAutoHideTimer()
        }
    }
    
    @IBAction private func onPlay() {
        initScrubberTimer()
        playVideo()
    }
    
    @IBAction private func onPause() {
        pauseVideo()
        isManuallyPaused = true
    }
    
    @IBAction private func onToggleFullScreen() {
        isFullScreen = !isFullScreen
    }
    
    @IBAction private func onDone() {
        pauseVideo()
        NextGenHook.delegate?.videoPlayerWillClose(mode, playbackPosition: currentTime)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func onCropToActivePicture() {
        playbackView.toggleVideoFillMode()
        
        if playbackView.videoFillMode == AVLayerVideoGravityResizeAspectFill {
            cropToActivePictureButton?.setImage(UIImage(named: "CropActiveCancel"), for: .normal)
            cropToActivePictureButton?.setImage(UIImage(named: "CropActiveCancel-Highlighted"), for: .highlighted)
        } else {
            cropToActivePictureButton?.setImage(UIImage(named: "CropActive"), for: .normal)
            cropToActivePictureButton?.setImage(UIImage(named: "CropActiveCancel-Highlighted"), for: .highlighted)
        }
    }
    
    func onTapSkip() {
        if !didPlayInterstitial {
            skipInterstitial()
        }
    }
    
    /* The user is dragging the movie controller thumb to scrub through the movie. */
    @IBAction private func beginScrubbing() {
        previousScrubbingRate = player?.rate ?? 0
        pauseVideo()
        
        // Remove previous timer
        removePlayerTimeObserver()
    }
    
    /* Set the player current time to match the scrubber position. */
    @IBAction private func scrub(sender: Any?) {
        if let slider = sender as? UISlider {
            updateTimeLabels(time: timeValue(forSlider: slider))
        }
    }
    
    @IBAction private func endScrubbing(sender: Any?) {
        if playerTimeObserver == nil {
            initScrubberTimer()
        }
        
        if let slider = sender as? UISlider {
            let time = timeValue(forSlider: slider)
            
            // Update time labels
            updateTimeLabels(time: time)
            
            // Seek
            seekPlayer(to: time)
        }
        
        if previousScrubbingRate > 0 {
            player?.rate = previousScrubbingRate
            previousScrubbingRate = 0
        }
    }
    
    // MARK: Controls
    /* Show the pause button in the movie player controller. */
    private func showPauseButton() {
        if state != .videoLoading {
            // Disable + Hide Play Button
            playButton?.isEnabled = false
            playButton?.isHidden = true
            
            // Enable + Show Pause Button
            pauseButton?.isEnabled = true
            pauseButton?.isHidden = false
        }
    }
    
    /* Show the play button in the movie player controller. */
    private func showPlayButton() {
        if state == .videoPaused || state == .readyToPlay {
            // Disable + Hide Pause Button
            pauseButton?.isEnabled = false
            pauseButton?.isHidden = true
            
            // Enable + Show Play Button
            playButton?.isEnabled = true
            playButton?.isHidden = false
        }
    }
    
    /* If the media is playing, show the stop button; otherwise, show the play button. */
    private func syncPlayPauseButtons() {
        if isPlaying {
            showPauseButton()
        } else {
            showPlayButton()
        }
    }
    
    private func initAutoHideTimer() {
        if playerControlsVisible {
            // Invalidate existing timer
            playerControlsAutoHideTimer?.invalidate()
            playerControlsAutoHideTimer = nil
            
            // Start timer
            playerControlsAutoHideTimer = Timer.scheduledTimer(timeInterval: Constants.PlayerControlsAutoHideTime, target: self, selector: #selector(self.autoHideControlsIfNecessary), userInfo: nil, repeats: false)
        }
    }
    
    func autoHideControlsIfNecessary() {
        if playerControlsVisible && state == .videoPlaying {
            playerControlsVisible = false
        }
    }
    
    private func initScrubberTimer() {
        /* Requests invocation of a given block during media playback to update the movie scrubber control. */
        if playerItemDuration > 0 {
            /* Update the scrubber during normal playback. */
            playerTimeObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, 1), queue: nil, using: { [weak self] (_) in
                self?.syncScrubber()
            })
        }
    }
    
    /* Cancels the previously registered time observer. */
    private func removePlayerTimeObserver() {
        // Player time
        if let observer = playerTimeObserver {
            player?.removeTimeObserver(observer)
            playerTimeObserver = nil
        }
        
        // Player Controls Auto-Hide Timer
        playerControlsAutoHideTimer?.invalidate()
        playerControlsAutoHideTimer = nil
    }
    
}
