//
//  ShoppingSceneDetailCollectionViewCell.swift
//

import Foundation
import UIKit
import NextGenDataManager

enum ShoppingProductImageType {
    case product
    case scene
}

class ShoppingSceneDetailCollectionViewCell: SceneDetailCollectionViewCell {
    
    static let ReuseIdentifier = "ShoppingSceneDetailCollectionViewCellReuseIdentifier"
    
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var bullseyeImageView: UIImageView!
    @IBOutlet weak private var extraDescriptionLabel: UILabel!
    
    var productImageType = ShoppingProductImageType.product
    
    private var imageURL: URL? {
        set {
            if let url = newValue {
                imageView.contentMode = UIViewContentMode.scaleAspectFit
                imageView.sd_setImage(with: url, completed: { [weak self] (image, _, _, _) in
                    self?.imageView.backgroundColor = image?.getPixelColor(CGPoint.zero)
                })
            } else {
                imageView.sd_cancelCurrentImageLoad()
                imageView.image = nil
                imageView.backgroundColor = UIColor.clear
            }
        }
        
        get {
            return nil
        }
    }
    
    private var extraDescription: String? {
        set {
            extraDescriptionLabel?.text = newValue
        }
        
        get {
            return extraDescriptionLabel?.text
        }
    }
    
    private var currentProduct: ProductItem? {
        didSet {
            if currentProduct?.id != oldValue?.id {
                descriptionText = currentProduct?.brand
                extraDescription = currentProduct?.name
                imageURL = (productImageType == .scene ? currentProduct?.sceneImageURL : currentProduct?.productImageURL)
            }
            
            if currentProduct == nil {
                currentProductFrameTime = -1
            }
        }
    }
    
    private var currentProductFrameTime = -1.0
    private var currentProductSessionDataTask: URLSessionDataTask?
    var products: [ProductItem]? {
        didSet {
            currentProduct = products?.first
        }
    }
    
    override func currentTimeDidChange() {
        if let productAPIUtil = NGDMConfiguration.productAPIUtil {
            DispatchQueue.global(qos: .userInteractive).async {
                if self.timedEvent != nil && self.timedEvent!.isType(.product) {
                    let newFrameTime = productAPIUtil.closestFrameTime(self.currentTime)
                    if newFrameTime != self.currentProductFrameTime {
                        self.currentProductFrameTime = newFrameTime
                        
                        if let currentTask = self.currentProductSessionDataTask {
                            currentTask.cancel()
                        }
                        
                        self.currentProductSessionDataTask = productAPIUtil.getFrameProducts(self.currentProductFrameTime, completion: { [weak self] (products) -> Void in
                            self?.currentProductSessionDataTask = nil
                            DispatchQueue.main.async {
                                self?.products = products
                            }
                        })
                    }
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        products = nil
        bullseyeImageView.isHidden = true
        
        if let task = currentProductSessionDataTask {
            task.cancel()
            currentProductSessionDataTask = nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if productImageType == .scene {
            bullseyeImageView.isHidden = false
            if let product = currentProduct {
                var bullseyeFrame = bullseyeImageView.frame
                let bullseyePoint = CGPoint(x: imageView.frame.width * product.bullseyePoint.x, y: imageView.frame.height * product.bullseyePoint.y)
                bullseyeFrame.origin = CGPoint(x: bullseyePoint.x + imageView.frame.minX - (bullseyeFrame.width / 2), y: bullseyePoint.y + imageView.frame.minY - (bullseyeFrame.height / 2))
                bullseyeImageView.frame = bullseyeFrame
                
                bullseyeImageView.layer.shadowColor = UIColor.black.cgColor;
                bullseyeImageView.layer.shadowOffset = CGSize(width: 1, height: 1);
                bullseyeImageView.layer.shadowOpacity = 0.75;
                bullseyeImageView.layer.shadowRadius = 2;
                bullseyeImageView.clipsToBounds = false;
            }
        } else {
            bullseyeImageView.isHidden = true
        }
    }
    
}
