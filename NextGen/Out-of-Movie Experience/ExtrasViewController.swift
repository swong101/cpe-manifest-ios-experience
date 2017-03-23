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
        return (!DeviceType.IS_IPAD && CPEXMLSuite.current!.manifest.hasActors)
    }
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        experience = CPEXMLSuite.current!.manifest.outOfMovieExperience
        
        if let talentTableView = talentTableView, CPEXMLSuite.current!.manifest.hasActors {
            talentTableView.register(UINib(nibName: "TalentTableViewCell-Wide", bundle: nil), forCellReuseIdentifier: TalentTableViewCell.ReuseIdentifier)
            talentTableView.contentInset = UIEdgeInsetsMake(15, 0, 0, 0)
        } else {
            talentTableView?.removeFromSuperview()
            talentTableView = nil
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
        if let viewController = segue.destination as? ExtrasExperienceViewController, let experience = sender as? Experience {
            viewController.experience = experience
        }
    }
    
}

extension ExtrasViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CPEXMLSuite.current!.manifest.numActors
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TalentTableViewCell.ReuseIdentifier) as! TalentTableViewCell
        if let actors = CPEXMLSuite.current!.manifest.actors, actors.count > indexPath.row {
            cell.talent = actors[indexPath.row]
        }
        
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
        return (showActorsInGrid ? (experience.numChildExperiences + 1) : experience.numChildExperiences)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TitledImageCell.ReuseIdentifier, for: indexPath) as! TitledImageCell
        
        var childExperienceIndex = indexPath.row
        if showActorsInGrid {
            if childExperienceIndex == 0 {
                cell.experience = nil
                cell.title = String.localize("label.actors")
                cell.imageURL = CPEXMLSuite.current!.manifest.actors?.first?.thumbnailImageURL
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
                self.performSegue(withIdentifier: SegueIdentifier.ShowTalentSelector, sender: CPEXMLSuite.current!.manifest.mainExperience)
                return
            }
            
            childExperienceIndex -= 1
        }
        
        if let experience = experience.childExperience(atIndex: childExperienceIndex) {
            launchExperience(experience)
        }
    }
    
    private func launchExperience(_ experience: Experience) {
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
                NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectApp, itemId: app.analyticsID)
            }
        } else {
            if let firstChildExperience = experience.childExperience(atIndex: 0) {
                if firstChildExperience.isType(.audioVisual) {
                    self.performSegue(withIdentifier: SegueIdentifier.ShowGallery, sender: experience)
                    NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectVideoGallery, itemId: experience.analyticsID)
                } else if firstChildExperience.isType(.gallery) {
                    self.performSegue(withIdentifier: SegueIdentifier.ShowGallery, sender: experience)
                    NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectImageGalleries, itemId: experience.analyticsID)
                } else if experience.numChildExperiences > 1 {
                    self.performSegue(withIdentifier: SegueIdentifier.ShowList, sender: experience)
                    NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectExperienceList, itemId: experience.analyticsID)
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
