//
//  ShoppingDetailViewController.swift
//  NextGen
//
//  Created by Sedinam Gadzekpo on 3/3/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import UIKit

class ShoppingDetailCell: UICollectionViewCell {
    
    static let ReuseIdentifier = "ShoppingDetailCellReuseIdentifier"
    
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var productBrandLabel: UILabel!
    @IBOutlet weak var productNameLabel: UILabel!
    
    private var _product: TheTakeProduct?
    var product: TheTakeProduct? {
        get {
            return _product
        }
        
        set(v) {
            _product = v
            
            productBrandLabel.text = _product?.brand
            productNameLabel.text = _product?.name
            if let imageURL = _product?.imageURL {
                productImageView.setImageWithURL(imageURL, completion: { (image) -> Void in
                    self.productImageView.backgroundColor = image?.getPixelColor(CGPoint.zero)
                })
            } else {
                productImageView.image = nil
                productImageView.backgroundColor = UIColor.clearColor()
            }
        }
    }
    
    override var selected: Bool {
        didSet {
            self.layer.borderColor = UIColor.whiteColor().CGColor
            self.layer.borderWidth = (self.selected ? 1 : 0)
        }
    }
    
}

class ShoppingDetailViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var productMatchIcon: UIView!
    @IBOutlet weak var productMatchLabel: UILabel!
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var productBrandLabel: UILabel!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var productPriceLabel: UILabel!
    @IBOutlet weak var shopButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    
    @IBOutlet weak var productsCollectionView: UICollectionView!
    
    var products: [TheTakeProduct]!
    
    private var _currentProduct: TheTakeProduct?
    var currentProduct: TheTakeProduct? {
        get {
            return _currentProduct
        }

        set(v) {
            _currentProduct = v
            
            productMatchIcon.backgroundColor = _currentProduct != nil ? (_currentProduct!.exactMatch ? UIColor(netHex: 0x2c97de) : UIColor(netHex: 0xf1c115)) : UIColor.clearColor()
            productMatchLabel.text = _currentProduct != nil ? (_currentProduct!.exactMatch ? "Exact match" : "Close match") : nil
            productBrandLabel.text = _currentProduct?.brand
            productNameLabel.text = _currentProduct?.name
            productPriceLabel.text = _currentProduct?.price
            if let imageURL = _currentProduct?.imageURL {
                productImageView.setImageWithURL(imageURL, completion: { (image) -> Void in
                    self.productImageView.backgroundColor = image?.getPixelColor(CGPoint.zero)
                })
            } else {
                productImageView.image = nil
                productImageView.backgroundColor = UIColor.clearColor()
            }
        }
    }
    
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        productMatchIcon.layer.cornerRadius = CGRectGetWidth(productMatchIcon.frame) / 2
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        productsCollectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition.Top)
        collectionView(productsCollectionView, didSelectItemAtIndexPath: indexPath)
    }
    
    
    // MARK: Actions
    @IBAction func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onShop(sender: AnyObject) {
        if let product = currentProduct {
            product.theTakeURL.promptLaunchBrowser()
        }
    }
    
    @IBAction func onSendLink(sender: AnyObject) {
        if let button = sender as? UIButton, product = currentProduct {
            let activityViewController = UIActivityViewController(activityItems: [product.shareText], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = button
            self.presentViewController(activityViewController, animated: true, completion: nil)
        }
    }
    
    
    // MARK: UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ShoppingDetailCell.ReuseIdentifier, forIndexPath: indexPath) as! ShoppingDetailCell
        cell.product = products[indexPath.row]
        
        return cell
    }
    
    
    // MARK: UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let product = products[indexPath.row]
        if product != currentProduct {
            currentProduct = product
        }
    }
    
}