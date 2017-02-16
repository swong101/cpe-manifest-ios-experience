//
//  ExtrasViewController.swift
//


import UIKit
import NextGenDataManager

class ExtrasViewController: ExtrasExperienceViewController {
    
    fileprivate struct Constants {
        static let CollectionViewItemSpacing: CGFloat = (DeviceType.IS_IPAD ? 12 : 5)
        static let CollectionViewLineSpacing: CGFloat = (DeviceType.IS_IPAD ? 12 : 25)
        static let CollectionViewPadding: CGFloat = (DeviceType.IS_IPAD ? 15 : 10)
        static let CollectionViewItemAspectRatio: CGFloat = 318 / 224
    }
    
    fileprivate struct SegueIdentifier {
        static let ShowTalent = "ShowTalentSegueIdentifier"
        static let ShowGallery = "ExtrasGallerySegue"
        static let ShowList = "ExtrasListSegue"
        static let ShowMap = "ExtrasMapSegue"
        static let ShowShopping = "ExtrasShoppingSegue"
        static let ShowTalentSelector = "TalentSelectorSegueIdentifier"
    }
    
    @IBOutlet weak private var talentTableView: UITableView?
    @IBOutlet weak private var talentDetailView: UIView?
    @IBOutlet private var extrasCollectionView: UICollectionView!
    
    private var talentDetailViewController: TalentDetailViewController?
    fileprivate var selectedIndexPath: IndexPath?
    
    fileprivate var showActorsInGrid: Bool {
        return !DeviceType.IS_IPAD && NGDMManifest.sharedInstance.hasActors
    }
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        experience = NGDMManifest.sharedInstance.outOfMovieExperience!
        
        if let talentTableView = talentTableView {
            if let actors = NGDMManifest.sharedInstance.mainExperience?.orderedActors , actors.count > 0 {
                talentTableView.register(UINib(nibName: "TalentTableViewCell-Wide", bundle: nil), forCellReuseIdentifier: TalentTableViewCell.ReuseIdentifier)
                talentTableView.contentInset = UIEdgeInsetsMake(15, 0, 0, 0)
            } else {
                talentTableView.removeFromSuperview()
                self.talentTableView = nil
            }
        }
        
        extrasCollectionView.register(UINib(nibName: "TitledImageCell", bundle: nil), forCellWithReuseIdentifier: TitledImageCell.ReuseIdentifier)
        
        showHomeButton()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        extrasCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    
    // MARK: Actions
    override func close() {
        if talentDetailView != nil && !talentDetailView!.isHidden {
            hideTalentDetailView()
        } else {
            super.close()
        }
    }
    
    
    // MARK: Talent Details
    fileprivate func showTalentDetailView() {
        if selectedIndexPath != nil, let talent = (talentTableView?.cellForRow(at: selectedIndexPath!) as? TalentTableViewCell)?.talent, let talentDetailView = talentDetailView, let talentDetailViewController = UIStoryboard.getNextGenViewController(TalentDetailViewController.self) as? TalentDetailViewController {
            talentDetailViewController.talent = talent
            
            talentDetailViewController.view.frame = talentDetailView.bounds
            talentDetailView.addSubview(talentDetailViewController.view)
            self.addChildViewController(talentDetailViewController)
            talentDetailViewController.didMove(toParentViewController: self)
            
            showBackButton()
            
            if talentDetailView.isHidden {
                talentDetailView.alpha = 0
                talentDetailView.isHidden = false
                
                UIView.animate(withDuration: 0.25, animations: {
                    talentDetailView.alpha = 1
                })
            } else {
                talentDetailViewController.view.alpha = 0
                UIView.animate(withDuration: 0.25, animations: {
                    talentDetailViewController.view.alpha = 1
                })
            }
            
            self.talentDetailViewController = talentDetailViewController
            NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectTalent, itemId: talent.id)
        }
    }
    
    fileprivate func hideTalentDetailView(completed: (() -> Void)? = nil) {
        if talentDetailViewController != nil {
            if selectedIndexPath != nil {
                talentTableView?.deselectRow(at: selectedIndexPath!, animated: true)
                selectedIndexPath = nil
            }
            
            if completed == nil {
                showHomeButton()
            }
            
            UIView.animate(withDuration: 0.25, animations: {
                if completed != nil {
                    self.talentDetailViewController?.view.alpha = 0
                } else {
                    self.talentDetailView?.alpha = 0
                }
            }, completion: { (Bool) -> Void in
                if completed == nil {
                    self.talentDetailView?.isHidden = true
                }
                
                self.talentDetailViewController?.willMove(toParentViewController: nil)
                self.talentDetailViewController?.view.removeFromSuperview()
                self.talentDetailViewController?.removeFromParentViewController()
                self.talentDetailViewController = nil
                completed?()
            })
        } else {
            completed?()
        }
    }
    
    // MARK: Storyboard
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? ExtrasExperienceViewController, let experience = sender as? NGDMExperience {
            viewController.experience = experience
        }
    }
    
}

extension ExtrasViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return NGDMManifest.sharedInstance.mainExperience?.orderedActors?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TalentTableViewCell.ReuseIdentifier) as! TalentTableViewCell
        cell.talent = NGDMManifest.sharedInstance.mainExperience?.orderedActors?[indexPath.row]
        
        return cell
    }
    
}

extension ExtrasViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath == selectedIndexPath {
            hideTalentDetailView()
            return nil
        }
        
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        hideTalentDetailView { [weak self] in
            self?.selectedIndexPath = indexPath
            self?.showTalentDetailView()
        }
    }
    
}

extension ExtrasViewController: TalentDetailViewPresenter {
    
    func talentDetailViewShouldClose() {
        hideTalentDetailView()
    }
    
}

extension ExtrasViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (showActorsInGrid ? (experience.numChildren + 1) : experience.numChildren)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TitledImageCell.ReuseIdentifier, for: indexPath) as! TitledImageCell
        
        var childExperienceIndex = indexPath.row
        if showActorsInGrid {
            if childExperienceIndex == 0 {
                cell.experience = nil
                cell.title = String.localize("label.actors")
                cell.imageURL = NGDMManifest.sharedInstance.mainExperience?.orderedActors?.first?.images?.first?.thumbnailImageURL
                cell.imageView.contentMode = .scaleAspectFit
                return cell
            }
            
            childExperienceIndex -= 1
        }
        
        cell.experience = experience.childExperience(atIndex: childExperienceIndex)
        
        return cell
    }
    
}

extension ExtrasViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var childExperienceIndex = indexPath.row
        if showActorsInGrid {
            if childExperienceIndex == 0 {
                self.performSegue(withIdentifier: SegueIdentifier.ShowTalentSelector, sender: nil)
                return
            }
            
            childExperienceIndex -= 1
        }
        
        if let experience = experience.childExperience(atIndex: childExperienceIndex) {
            launchExperience(experience)
        }
    }
    
    private func launchExperience(_ experience: NGDMExperience) {
        if experience.isType(.product) {
            self.performSegue(withIdentifier: SegueIdentifier.ShowShopping, sender: experience)
            NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectShopping)
        } else if experience.isType(.location) {
            self.performSegue(withIdentifier: SegueIdentifier.ShowMap, sender: experience)
            NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectSceneLocations)
        } else if experience.isType(.app) {
            if let app = experience.app, let url = app.url {
                let webViewController = WebViewController(title: app.title, url: url)
                webViewController.shouldDisplayFullScreen = true
                let navigationController = LandscapeNavigationController(rootViewController: webViewController)
                self.present(navigationController, animated: true, completion: nil)
                NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectApp, itemId: app.analyticsIdentifier)
            }
        } else {
            if let firstChildExperience = experience.childExperience(atIndex: 0) {
                if firstChildExperience.isType(.audioVisual) {
                    self.performSegue(withIdentifier: SegueIdentifier.ShowGallery, sender: experience)
                    NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectVideoGallery, itemId: experience.analyticsIdentifier)
                } else if firstChildExperience.isType(.gallery) {
                    self.performSegue(withIdentifier: SegueIdentifier.ShowGallery, sender: experience)
                    NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectImageGalleries, itemId: experience.analyticsIdentifier)
                } else if experience.numChildren > 1 {
                    self.performSegue(withIdentifier: SegueIdentifier.ShowList, sender: experience)
                    NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectExperienceList, itemId: experience.analyticsIdentifier)
                } else {
                    launchExperience(firstChildExperience)
                }
            }
        }
    }
    
}

extension ExtrasViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let containerWidth = collectionView.frame.width - (Constants.CollectionViewPadding * 2)
        let itemWidth: CGFloat = (containerWidth / 2) - Constants.CollectionViewItemSpacing
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
    
}
