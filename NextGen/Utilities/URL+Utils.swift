//
//  URL+Utils.swift
//

import UIKit
import SafariServices

public enum URLLaunchType {
    case browser
    case itunes
}

extension URL {
    
    func promptLaunch(type: URLLaunchType = .browser) {
        let alertMessage = (type == .itunes ? String.localize("info.leaving_app.message_itunes") : String.localize("info.leaving_app.message"))
        if #available(iOS 9.0, *) {
            if type == .itunes {
                promptLaunch(withMessage: alertMessage)
            } else {
                let safariViewController = SFSafariViewController(url: self)
                UIViewController.top?.present(safariViewController, animated: true, completion: nil)
            }
        } else {
            promptLaunch(withMessage: alertMessage)
        }
    }
    
    func promptLaunch(withMessage message: String?) {
        let alertController = UIAlertController(title: String.localize("info.leaving_app.title"), message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction(title: String.localize("label.no"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: String.localize("label.yes"), style: .default, handler: { (UIAlertAction) -> Void in
            UIApplication.shared.openURL(self)
        }))
        
        alertController.show()
    }
    
}
