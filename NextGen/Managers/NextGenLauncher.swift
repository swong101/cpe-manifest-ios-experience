//
//  NextGenLauncher.swift
//

import UIKit
import NextGenDataManager
import ReachabilitySwift

@objc class NextGenLauncher: NSObject {
    
    static var sharedInstance: NextGenLauncher? = NextGenLauncher()
    
    private var reachability = Reachability()!
    private var reachabilityChangedObserver: NSObjectProtocol?
    
    private var homeViewController: HomeViewController?
    var isBeingDismissed = false
    
    deinit {
        removeObservers()
    }
    
    static func destroyInstance() {
        sharedInstance = nil
    }
    
    func removeObservers() {
        if let observer = reachabilityChangedObserver {
            NotificationCenter.default.removeObserver(observer)
            reachabilityChangedObserver = nil
        }
    }
    
    func launchExperience(fromViewController: UIViewController) {
        NextGenHook.delegate?.experienceWillOpen()
        
        homeViewController = UIStoryboard.getNextGenViewController(HomeViewController.self) as? HomeViewController
        fromViewController.present(homeViewController!, animated: true, completion: nil)
        
        reachabilityChangedObserver = NotificationCenter.default.addObserver(forName: ReachabilityChangedNotification, object: reachability, queue: OperationQueue.main) { (notification) in
            if let reachability = notification.object as? Reachability {
                if reachability.isReachable {
                    if reachability.isReachableViaWiFi {
                        NextGenHook.delegate?.connectionStatusChanged(status: .onWiFi)
                    } else {
                        NextGenHook.delegate?.connectionStatusChanged(status: .onCellular)
                    }
                } else {
                    NextGenHook.delegate?.connectionStatusChanged(status: .off)
                }
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start reachability notifier: \(error)")
        }
    }
    
    func closeExperience() {
        isBeingDismissed = true
        removeObservers()
        NextGenHook.experienceWillClose()
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: { [weak self] in
            self?.isBeingDismissed = false
            CPEXMLSuite.current = nil
        })
    }

}
