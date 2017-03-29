//
//  BundleUtils.swift
//

import Foundation

extension Bundle {

    static var frameworkResources: Bundle {
        if let resourcesBundleURL = Bundle(for: HomeViewController.self).url(forResource: "CPEExperience", withExtension: "bundle"), let resourcesBundle = Bundle(url: resourcesBundleURL) {
            return resourcesBundle
        }

        return Bundle.main
    }

}
