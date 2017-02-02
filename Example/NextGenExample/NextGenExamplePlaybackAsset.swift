//
//  NextGenExamplePlaybackAsset.swift
//

import Foundation
import AVFoundation
import SDWebImage

class NextGenExamplePlaybackAsset: NextGenPlaybackAsset {
    
    var assetId: String
    var assetURL: URL
    var assetURLAsset: AVURLAsset?
    var assetContentType: String?
    var assetTitle: String?
    var assetImage = UIImage()
    var assetPlaybackPosition: Double = 0
    var assetIsCastable = false
    var assetTextTracks: [NextGenPlaybackTextTrack]?
    var assetImageURL: URL? {
        didSet {
            if let assetImageURL = assetImageURL {
                let lockScreenImageSize = CGSize(width: 768, height: 768)
                SDWebImageDownloader.shared().downloadImage(with: assetImageURL, options: .lowPriority, progress: nil, completed: { [weak self] (image, data, error, finished) in
                    if let image = image {
                        var scaledImageRect = CGRect.zero
                        let aspectWidth = lockScreenImageSize.width / image.size.width
                        let aspectHeight = lockScreenImageSize.height / image.size.height
                        let aspectRatio = (aspectWidth < aspectHeight ? aspectWidth : aspectHeight)
                        scaledImageRect.size.width = image.size.width * aspectRatio
                        scaledImageRect.size.height = image.size.height * aspectRatio
                        scaledImageRect.origin.x = (lockScreenImageSize.width - scaledImageRect.size.width) / 2
                        scaledImageRect.origin.y = (lockScreenImageSize.height - scaledImageRect.size.height) / 2
                        UIColor.black.set()
                        UIRectFill(CGRect(x: 0, y: 0, width: lockScreenImageSize.width, height: lockScreenImageSize.height))
                        image.draw(in: scaledImageRect)
                        let newImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        if let newImage = newImage {
                            self?.assetImage = newImage
                        }
                    }
                })
            }
        }
    }
    
    init(id: String, url: URL, title: String? = nil, imageURL: URL? = nil) {
        assetId = id
        assetURL = url
        assetTitle = title
        assetImageURL = imageURL
    }
    
}
