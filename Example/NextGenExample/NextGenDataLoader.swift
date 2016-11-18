//
//  NextGenDataLoader.swift
//

import Foundation
import UIKit
import GoogleMaps
import NextGenDataManager
import PromiseKit

@objc class NextGenDataLoader: NSObject {
    
    private enum DataLoaderError: Error {
        case TitleNotFound
        case FileMissing
    }
    
    private struct Constants {
        static let XMLBaseURI = "https://your-domain.com"
        
        struct ConfigKey {
            static let TheTakeAPI = "thetake_api_key"
            static let BaselineAPI = "baseline_api_key"
            static let GoogleMapsAPI = "google_maps_api_key"
        }
    }
    
    static let ManifestData = [
        "man_of_steel": [
            "title": "Man of Steel",
            "image": "MOS-Onesheet",
            "manifest": "path-to-manifest.xml",
            "appdata": "path-to-appdata.xml",
            "cpestyle": "path-to-cpestyle.xml"
        ]
    ]
    
    static func supportsContent(cid: String) -> Bool {
        return ManifestData[cid] != nil
    }
    
    static let sharedInstance = NextGenDataLoader()
    private var currentCid: String?
    
    override init() {
        super.init()
        
        NextGenHook.delegate = self
    }
    
    func loadConfig() {
        // Load configuration file
        if let configDataPath = Bundle.main.path(forResource: "Data/config", ofType: "json") {
            do {
                let configData = try NSData(contentsOf: URL(fileURLWithPath: configDataPath), options: NSData.ReadingOptions.mappedIfSafe)
                if let configJSON = try JSONSerialization.jsonObject(with: configData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                    if let key = configJSON[Constants.ConfigKey.TheTakeAPI] as? String {
                        TheTakeAPIUtil.sharedInstance.apiKey = key
                    }
                    
                    if let key = configJSON[Constants.ConfigKey.BaselineAPI] as? String {
                        NGDMConfiguration.talentAPIUtil = BaselineAPIUtil(apiKey: key)
                    }
                    
                    if let key = configJSON[Constants.ConfigKey.GoogleMapsAPI] as? String {
                        GMSServices.provideAPIKey(key)
                        NGDMConfiguration.mapService = .googleMaps
                    }
                }
            } catch let error as NSError {
                print("Error parsing config data \(error.localizedDescription)")
            }
        } else {
            print("Configuration file not found")
        }
    }
    
    func loadTitle(cid: String, completionHandler: @escaping (_ success: Bool) -> Void) throws {
        guard let titleData = NextGenDataLoader.ManifestData[cid] else { throw DataLoaderError.TitleNotFound }
        
        guard let manifestFileName = titleData["manifest"] else { throw NGDMError.manifestMissing }
        loadXMLFile(fileName: manifestFileName).then { localFilePath -> Void in
            do {
                NGDMManifest.createInstance()
                
                try NGDMManifest.sharedInstance.loadManifestXMLFile(localFilePath)
                
                if TheTakeAPIUtil.sharedInstance.apiKey != nil, let mediaId = NGDMManifest.sharedInstance.mainExperience?.customIdentifier(Namespaces.TheTake) {
                    TheTakeAPIUtil.sharedInstance.mediaId = mediaId
                    TheTakeAPIUtil.sharedInstance.prefetchProductFrames(start: 0)
                    TheTakeAPIUtil.sharedInstance.prefetchProductCategories()
                }
                
                if var talentAPIUtil = NGDMConfiguration.talentAPIUtil {
                    talentAPIUtil.apiId = NGDMManifest.sharedInstance.mainExperience?.customIdentifier(Namespaces.Baseline)
                }
                
                NGDMManifest.sharedInstance.mainExperience?.loadTalent()
            } catch NGDMError.mainExperienceMissing {
                print("Error loading Manifest file: no main Experience found")
                abort()
            } catch NGDMError.inMovieExperienceMissing {
                print("Error loading Manifest file: no in-movie Experience found")
                abort()
            } catch NGDMError.outOfMovieExperienceMissing {
                print("Error loading Manifest file: no out-of-movie Experience found")
                abort()
            } catch {
                print("Error loading Manifest file: unknown error")
                abort()
            }
            
            var promises = [Promise<String>]()
            var hasAppData = false
            
            if let appDataFileName = titleData["appdata"] {
                promises.append(self.loadXMLFile(fileName: appDataFileName))
                hasAppData = true
            }
            
            if let cpeStyleFileName = titleData["cpestyle"] {
                promises.append(self.loadXMLFile(fileName: cpeStyleFileName))
            }
            
            if promises.count > 0 {
                _ = when(fulfilled: promises).then(on: DispatchQueue.global(qos: .userInitiated), execute: { results -> Void in
                    var appDataFilePath: String?
                    var cpeStyleFilePath: String?
                    if hasAppData {
                        appDataFilePath = results.first
                        if results.count > 1 {
                            cpeStyleFilePath = results.last
                        }
                    } else {
                        cpeStyleFilePath = results.first
                    }
                    
                    if let localFilePath = appDataFilePath {
                        do {
                            NGDMManifest.sharedInstance.appData = try NGDMManifest.sharedInstance.loadAppDataXMLFile(localFilePath)
                        } catch {
                            print("Error loading AppData file")
                        }
                    }
                    
                    if let localFilePath = cpeStyleFilePath {
                        do {
                            try NGDMManifest.sharedInstance.loadCPEStyleXMLFile(localFilePath)
                        } catch {
                            print ("Error loading CPE-Style file")
                        }
                    }
                    
                    self.currentCid = cid
                    completionHandler(true)
                })
            } else {
                self.currentCid = cid
                completionHandler(true)
            }
        }.catch { error in
            completionHandler(false)
        }
    }
    
    private func loadXMLFile(fileName: String) -> Promise<String> {
        return Promise { fulfill, reject in
            if let remoteURL = URL(string: Constants.XMLBaseURI + "/" + fileName), let applicationSupportFileURL = NextGenCacheManager.applicationSupportFileURL(remoteURL) {
                if NextGenCacheManager.fileExists(applicationSupportFileURL) {
                    fulfill(applicationSupportFileURL.path)
                    NextGenCacheManager.storeApplicationSupportFile(remoteURL, completionHandler: { (localFileURL) in
                        
                    })
                } else {
                    NextGenCacheManager.storeApplicationSupportFile(remoteURL, completionHandler: { (localFileURL) in
                        if let filePath = localFileURL?.path {
                            fulfill(filePath)
                        } else {
                            reject(DataLoaderError.FileMissing)
                        }
                    })
                }
            } else {
                reject(DataLoaderError.FileMissing)
            }
        }
    }
    
}

extension NextGenDataLoader: NextGenHookDelegate {
    
    func connectionStatusChanged(status: NextGenConnectionStatus) {
        // Respond to any changes in the user's connection status (e.g. display prompt about cellular data usage)
    }
    
    func logAnalyticsEvent(_ event: NextGenAnalyticsEvent, action: NextGenAnalyticsAction, itemId: String?, itemName: String?) {
        // Adjust values as needed for your analytics implementation
    }
    
    func experienceWillOpen() {
        // Any start-up tasks
    }
    
    func experienceWillClose() {
        // Any shutdown tasks
    }
    
    func experienceWillEnterDebugMode() {
        // Perform any debug tasks or unlock any debug sections of the app
        // Debug mode is activated by tapping and holding the "Extras" button on the home screen for five seconds
    }
    
    public func previewModeShouldLaunchBuy() {
        // Callback for when the user taps the home screen buy button
    }
    
    func videoPlayerWillClose(_ mode: VideoPlayerMode, playbackPosition: Double) {
        // Handle end of playback
    }
    
    func videoAsset(forUrl url: URL, mode: VideoPlayerMode, completion: @escaping (AVURLAsset, Double) -> Void) {
        // Handle DRM
        completion(AVURLAsset(url: url), 0)
    }
    
    func interstitialShouldPlayMultipleTimes() -> Bool {
        // Return true if interstitial video should play again after user has already seen it (with ability to skip)
        return true
    }
    
    func urlForTitle(_ title: String, completion: @escaping (URL?) -> Void) {
        if let encodedTitleName = title.replacingOccurrences(of: ":", with: "").replacingOccurrences(of: "-", with: "").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            completion(URL(string: "http://www.vudu.com/movies/#search/" + encodedTitleName))
        } else {
            completion(nil)
        }
    }
    
    func urlForSharedContent(id: String, type: NextGenSharedContentType, completion: @escaping (URL?) -> Void) {
        var shareUrl = "your-domain.com"
        
        if type == .image {
            shareUrl += "/share/images"
        } else {
            shareUrl += "/share/videos"
        }
        
        shareUrl += "/" + id
        completion(URL(string: shareUrl))
    }
    
}
