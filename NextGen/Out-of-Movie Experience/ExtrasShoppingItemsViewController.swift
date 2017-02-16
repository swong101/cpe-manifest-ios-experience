//
//  ExtrasShoppingItemsViewController.swift
//

import UIKit
import NextGenDataManager

class ExtrasShoppingItemsViewController: ExtrasExperienceViewController {
    
    fileprivate struct Constants {
        static let ItemSpacing: CGFloat = 12
        static let LineSpacing: CGFloat = 12
        static let Padding: CGFloat = 15
        static let ItemAspectRatio: CGFloat = 338 / 230
    }
    
    @IBOutlet weak private var productsCollectionView: UICollectionView!
    
    var products: [ProductItem]?{
        didSet {
            productsCollectionView.reloadData()
            if let products = products, products.count > 0 {
                let newIndex = IndexPath(item: 0, section: 0)
                self.productsCollectionView.scrollToItem(at: newIndex, at: .top, animated: false)
            }
        }
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        productsCollectionView.register(UINib(nibName: ShoppingSceneDetailCollectionViewCell.NibName, bundle: nil), forCellWithReuseIdentifier: ShoppingSceneDetailCollectionViewCell.ReuseIdentifier)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        productsCollectionView.collectionViewLayout.invalidateLayout()
    }
    
}

extension ExtrasShoppingItemsViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (products?.count ?? 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShoppingSceneDetailCollectionViewCell.ReuseIdentifier, for: indexPath) as! ShoppingSceneDetailCollectionViewCell
        cell.titleLabel?.removeFromSuperview()
        cell.productImageType = .scene
        if let products = products, products.count > indexPath.row {
            cell.products = [products[indexPath.row]]
        }
        
        return cell
    }
    
}

extension ExtrasShoppingItemsViewController: UICollectionViewDelegate {
    
     func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let shoppingDetailViewController = UIStoryboard.getNextGenViewController(ShoppingDetailViewController.self) as? ShoppingDetailViewController, let cell = collectionView.cellForItem(at: indexPath) as? ShoppingSceneDetailCollectionViewCell {
            shoppingDetailViewController.experience = experience
            shoppingDetailViewController.products = cell.products
            shoppingDetailViewController.modalPresentationStyle = (DeviceType.IS_IPAD ? .overCurrentContext : .overFullScreen)
            shoppingDetailViewController.modalTransitionStyle = .crossDissolve
            self.present(shoppingDetailViewController, animated: true, completion: nil)
        }
    }
    
}

extension ExtrasShoppingItemsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var itemWidth: CGFloat
        if DeviceType.IS_IPAD {
            itemWidth = (collectionView.frame.width / 2) - (Constants.ItemSpacing * 2)
        } else {
            itemWidth = collectionView.frame.width
        }
        
        return CGSize(width: itemWidth, height: itemWidth / Constants.ItemAspectRatio)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.LineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.ItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(Constants.Padding, Constants.Padding, Constants.Padding, Constants.Padding)
    }
    
}
