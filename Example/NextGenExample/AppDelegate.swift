//
//  AppDelegate.swift
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        application.isStatusBarHidden = true

        Config.load()

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationCenter.default.post(name: .nextGenApplicationWillEnterForeground, object: nil)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        NotificationCenter.default.post(name: .nextGenApplicationWillResignActive, object: nil)
    }

}
