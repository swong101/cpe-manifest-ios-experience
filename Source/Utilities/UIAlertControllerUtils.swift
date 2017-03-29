//
//  UIAlertControllerUtils.swift
//

import UIKit

extension UIAlertController {

    func show() {
        show(true)
    }

    func show(_ animated: Bool) {
        UIViewController.top?.present(self, animated: animated, completion: nil)
    }

}
