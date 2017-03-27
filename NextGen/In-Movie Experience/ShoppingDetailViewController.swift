//
//  ShoppingDetailViewController.swift
//

import UIKit
import NextGenDataManager

enum ShoppingDetailMode {
    case ime
    case extras
    
    var analyticsEvent: NextGenAnalyticsEvent {
        if self == .ime {
            return .imeShopAction
        }
        
        return .extrasShopAction
    }
}

class ShoppingDetailViewController: SceneDetailViewController {
    
    @IBOutlet weak private var productMatchContainerView: UIView!
    @IBOutlet weak private var productMatchIcon: UIView!
    @IBOutlet weak private var productMatchLabel: UILabel!
    @IBOutlet weak private var productImageView: UIImageView!
    @IBOutlet weak private var productBrandLabel: UILabel!
    @IBOutlet weak private var productNameLabel: UILabel!
    @IBOutlet weak private var productPriceLabel: UILabel!
    @IBOutlet weak private var shopButton: UIButton!
    @IBOutlet weak private var emailButton: UIButton!
    @IBOutlet private var productNameToExactMatchConstraint: NSLayoutConstraint!
    @IBOutlet private var shopToProductPriceConstraint: NSLayoutConstraint!
    
    var mode = ShoppingDetailMode.extras
    var products: [ProductItem]?
    private var closeDetailsViewObserver: NSObjectProtocol?
    
    deinit {
        if let observer = closeDetailsViewObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    var currentProduct: ProductItem? {
        didSet {
            if currentProduct != oldValue {
                if let product = currentProduct, product.hasExactMatchData {
                    productNameToExactMatchConstraint.isActive = true
                    productMatchContainerView.isHidden = false
                    productMatchIcon.backgroundColor = (product.isExactMatch ? UIColor(netHex: 0x2c97de) : UIColor(netHex: 0xf1c115))
                    productMatchLabel.text = (product.isExactMatch ? String.localize("shopping.exact_match") : String.localize("shopping.close_match"))
                } else {
                    productNameToExactMatchConstraint.isActive = false
                    productMatchContainerView.isHidden = true
                }
                
                productBrandLabel.text = currentProduct?.brand
                productNameLabel.text = currentProduct?.name
                
                if let price = currentProduct?.displayPrice {
                    shopToProductPriceConstraint.isActive = true
                    productPriceLabel.isHidden = false
                    productPriceLabel.text = price
                } else {
                    shopToProductPriceConstraint.isActive = false
                    productPriceLabel.isHidden = true
                }
                
                if let imageURL = currentProduct?.productImageURL {
                    productImageView.sd_setImage(with: imageURL)
                } else {
                    productImageView.sd_cancelCurrentImageLoad()
                    productImageView.image = nil
                    productImageView.backgroundColor = UIColor.clear
                }
            }
        }
    }
    
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Localizations
        shopButton.setTitle(String.localize("shopping.shop_button").uppercased(), for: .normal)
        emailButton.setTitle(String.localize("shopping.send_button").uppercased(), for: .normal)
        
        // Notifications
        closeDetailsViewObserver = NotificationCenter.default.addObserver(forName: .shoppingShouldCloseDetails, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            self?.onClose()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        currentProduct = products?.first
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        productMatchIcon.layer.cornerRadius = (productMatchIcon.frame.width / 2)
    }
    
    // MARK: Actions
    @IBAction private func onShop(_ sender: AnyObject) {
        if let product = currentProduct, let externalURL = product.externalURL {
            NotificationCenter.default.post(name: .videoPlayerShouldPause, object: nil)
            externalURL.promptLaunch(cancelHandler: {
                NotificationCenter.default.post(name: .videoPlayerCanResume, object: nil)
            })
            
            NextGenHook.logAnalyticsEvent(mode.analyticsEvent, action: .selectShopProduct, itemName: product.name)
        }
    }
    
    @IBAction private func onSendLink(_ sender: AnyObject) {
        if let button = sender as? UIButton, let product = currentProduct {
            NotificationCenter.default.post(name: .videoPlayerShouldPause, object: nil)
            let activityViewController = UIActivityViewController(activityItems: [product.shareText], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = button
            activityViewController.completionWithItemsHandler = { (_, _, _, _) in
                NotificationCenter.default.post(name: .videoPlayerCanResume, object: nil)
            }
            
            self.present(activityViewController, animated: true, completion: nil)
            NextGenHook.logAnalyticsEvent(mode.analyticsEvent, action: .selectShareProductLink, itemName: product.name)
        }
    }
    
}
