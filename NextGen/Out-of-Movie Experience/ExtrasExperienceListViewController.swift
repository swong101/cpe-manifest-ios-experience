//
//  ExtrasViewController.swift
//


import UIKit
import NextGenDataManager

class ExtrasExperienceListViewController: ExtrasExperienceViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private struct Constants {
        static let CollectionViewItemSpacing: CGFloat = (DeviceType.IS_IPAD ? 12 : 5)
        static let CollectionViewLineSpacing: CGFloat = (DeviceType.IS_IPAD ? 12 : 25)
        static let CollectionViewPadding: CGFloat = (DeviceType.IS_IPAD ? 15 : 10)
        static let CollectionViewItemAspectRatio: CGFloat = 318 / 224
    }
    
    private struct SegueIdentifier {
        static let ShowTalent = "ShowTalentSegueIdentifier"
        static let ShowGallery = "ExtrasGallerySegue"
        static let ShowMap = "ExtrasMapSegue"
        static let ShowShopping = "ExtrasShoppingSegue"
        static let ShowList = "ExtrasListSegue"
        static let ShowTalentSelector = "TalentSelectorSegueIdentifier"
    }
    
    @IBOutlet var extrasCollectionView: UICollectionView!
    
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extrasCollectionView.register(UINib(nibName: "TitledImageCell", bundle: nil), forCellWithReuseIdentifier: TitledImageCell.ReuseIdentifier)
        
        showBackButton()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        extrasCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return experience.numChildren
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TitledImageCell.ReuseIdentifier, for: indexPath) as! TitledImageCell
        cell.experience = experience.childExperience(atIndex: indexPath.row)
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let experience = experience.childExperience(atIndex: indexPath.row) {
            if experience.isType(.shopping) {
                self.performSegue(withIdentifier: SegueIdentifier.ShowShopping, sender: experience)
                NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectShopping)
            } else if experience.isType(.location) {
                self.performSegue(withIdentifier: SegueIdentifier.ShowMap, sender: experience)
                NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectSceneLocations)
            } else if experience.isType(.app), let app = experience.app, let url = app.url {
                let webViewController = WebViewController(title: app.title, url: url)
                webViewController.shouldDisplayFullScreen = true
                let navigationController = LandscapeNavigationController(rootViewController: webViewController)
                self.present(navigationController, animated: true, completion: nil)
                NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectApp, itemId: app.analyticsIdentifier)
            } else if experience.isType(.audioVisual) {
                self.performSegue(withIdentifier: SegueIdentifier.ShowGallery, sender: experience)
                NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectVideoGallery, itemId: experience.analyticsIdentifier)
            } else if experience.isType(.gallery) {
                self.performSegue(withIdentifier: SegueIdentifier.ShowGallery, sender: experience)
                NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectImageGalleries, itemId: experience.analyticsIdentifier)
            }
        }
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let containerWidth = collectionView.frame.width - (Constants.CollectionViewPadding * 2)
        var itemWidth: CGFloat = 0
        if DeviceType.IS_IPAD {
            itemWidth = (containerWidth / 3) - (Constants.CollectionViewItemSpacing * 2)
        } else {
            itemWidth = (containerWidth / 2) - Constants.CollectionViewItemSpacing
        }
        
        return CGSize(width: itemWidth, height: itemWidth / Constants.CollectionViewItemAspectRatio)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.CollectionViewLineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.CollectionViewItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(Constants.CollectionViewPadding, Constants.CollectionViewPadding, Constants.CollectionViewPadding, Constants.CollectionViewPadding)
    }
    
    // MARK: Storyboard
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? ExtrasExperienceViewController, let experience = sender as? NGDMExperience {
            viewController.experience = experience
        }
    }
    
}
