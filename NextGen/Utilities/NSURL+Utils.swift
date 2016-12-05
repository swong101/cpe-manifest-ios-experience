//
//  NSURL+Utils.swift
//

import UIKit

public enum URLLaunchType {
    case browser
    case itunes
}

extension URL {
    
    func promptLaunch(type: URLLaunchType = .browser) {
        var alertMessage: String?
        switch type {
        case .itunes:
            alertMessage = String.localize("info.leaving_app.message_itunes")
            break
            
        default:
            alertMessage = String.localize("info.leaving_app.message")
        }
        
        let alertController = UIAlertController(title: String.localize("info.leaving_app.title"), message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction(title: String.localize("label.no"), style: UIAlertActionStyle.cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: String.localize("label.yes"), style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
            UIApplication.shared.openURL(self)
        }))
        
        alertController.show()
    }
    
}
