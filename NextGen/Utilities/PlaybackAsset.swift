//
//  PlaybackAsset.swift
//

import AVKit
import SDWebImage
import GoogleCast

public class PlaybackAsset {
    
    var url: URL
    var urlAsset: AVURLAsset? {
        didSet {
            if let urlAsset = urlAsset {
                url = urlAsset.url
            }
        }
    }
    
    var title: String?
    var image = UIImage()
    var imageSize = CGSize(width: 768, height: 768)
    var imageUrl: URL? {
        didSet {
            if let imageUrl = imageUrl {
                SDWebImageDownloader.shared().downloadImage(with: imageUrl, options: .lowPriority, progress: nil, completed: { [weak self] (image, _, _, _) in
                    if let strongSelf = self, let image = image {
                        var scaledImageRect = CGRect.zero
                        let aspectWidth = strongSelf.imageSize.width / image.size.width
                        let aspectHeight = strongSelf.imageSize.height / image.size.height
                        let aspectRatio = (aspectWidth < aspectHeight ? aspectWidth : aspectHeight)
                        scaledImageRect.size.width = image.size.width * aspectRatio
                        scaledImageRect.size.height = image.size.height * aspectRatio
                        scaledImageRect.origin.x = (strongSelf.imageSize.width - scaledImageRect.size.width) / 2
                        scaledImageRect.origin.y = (strongSelf.imageSize.height - scaledImageRect.size.height) / 2
                        UIGraphicsBeginImageContext(strongSelf.imageSize)
                        UIColor.black.set()
                        UIRectFill(CGRect(x: 0, y: 0, width: strongSelf.imageSize.width, height: strongSelf.imageSize.height))
                        image.draw(in: scaledImageRect)
                        strongSelf.image = UIGraphicsGetImageFromCurrentImageContext() ?? image
                        UIGraphicsEndImageContext()
                    }
                })
            }
        }
    }
    
    var startTime: Double = 0
    var isCastAsset = false
    var customData: Any?
    
    var castMediaInfo: GCKMediaInformation {
        let metadata = GCKMediaMetadata(metadataType: .movie)
        metadata.setString(title ?? "", forKey: kGCKMetadataKeyTitle)
        if let url = imageUrl {
            metadata.addImage(GCKImage(url: url, width: 0, height: 0))
        }
        
        return GCKMediaInformation(
            contentID: url.absoluteString,
            streamType: .buffered,
            contentType: "video/mp4",
            metadata: metadata,
            streamDuration: 0,
            customData: customData
        )
    }
    
    init(url: URL, title: String? = nil, imageUrl: URL? = nil, startTime: Double = 0) {
        self.url = url
        urlAsset = AVURLAsset(url: url)
        self.title = title
        self.imageUrl = imageUrl
        self.startTime = startTime
    }
    
}
