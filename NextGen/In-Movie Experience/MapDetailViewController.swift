//
//  MapDetailViewController.swift
//

import UIKit
import MapKit
import NextGenDataManager

class MapDetailViewController: SceneDetailViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak private var mapView: MultiMapView!
    @IBOutlet private var mapContainerAspectRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak private var mediaCollectionView: UICollectionView?
    @IBOutlet weak private var descriptionLabel: UILabel?
    
    @IBOutlet weak var locationDetailView: UIView!
    @IBOutlet weak var videoContainerView: UIView!
    private var videoPlayerViewController: VideoPlayerViewController?
    
    @IBOutlet weak var galleryScrollView: ImageGalleryScrollView!
    
    private var mapTypeDidChangeObserver: NSObjectProtocol?
    
    private var marker: MultiMapMarker!
    private var location: NGDMLocation {
        return timedEvent!.location!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        galleryScrollView.cleanInvisibleImages()
    }
    
    deinit {
        let center = NotificationCenter.default
        
        if let observer = mapTypeDidChangeObserver {
            center.removeObserver(observer)
            mapTypeDidChangeObserver = nil
        }
        
        mapView.destroy()
    }
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if location.mediaCount > 0 {
            mediaCollectionView?.register(UINib(nibName: "SimpleMapCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: SimpleMapCollectionViewCell.ReuseIdentifier)
            mediaCollectionView?.register(UINib(nibName: "SimpleImageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: SimpleImageCollectionViewCell.BaseReuseIdentifier)
        } else {
            mediaCollectionView?.removeFromSuperview()
            mapContainerAspectRatioConstraint.isActive = false
        }
        
        if let text = location.description {
            descriptionLabel?.text = text
            descriptionLabel?.isHidden = false
        } else {
            descriptionLabel?.removeFromSuperview()
        }
        
        mapView.delegate = self
        
        mapTypeDidChangeObserver = NotificationCenter.default.addObserver(forName: .locationsMapTypeDidChange, object: nil, queue: OperationQueue.main, using: { (notification) in
            if let mapType = notification.userInfo?[NotificationConstants.mapType] as? MultiMapType {
                NextGenHook.logAnalyticsEvent(.imeLocationAction, action: .setMapType, itemName: (mapType == .satellite ? NextGenAnalyticsLabel.satellite : NextGenAnalyticsLabel.road))
            }
        })
        
        galleryScrollView.allowsFullScreen = false
        galleryScrollView.removeToolbar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let center = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        mapView.setLocation(center, zoomLevel: location.zoomLevel, animated: false)
        marker = mapView.addMarker(center, title: location.name, subtitle: location.address, icon: location.iconImage, autoSelect: true)
        mapView.addControls()
        mapView.maxZoomLevel = (location.zoomLocked ? location.zoomLevel : -1)
    }
    
    fileprivate func animateToCenter() {
        let center = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        mapView.setLocation(center, zoomLevel: location.zoomLevel, animated: true)
        mapView.selectedMarker = marker
    }
    
    // MARK: Actions
    private func playVideo(_ videoURL: URL) {
        closeDetailView()
        
        if let videoPlayerViewController = UIStoryboard.getNextGenViewController(VideoPlayerViewController.self) as? VideoPlayerViewController {
            videoPlayerViewController.mode = VideoPlayerMode.supplementalInMovie
            
            videoPlayerViewController.view.frame = videoContainerView.bounds
            videoContainerView.addSubview(videoPlayerViewController.view)
            self.addChildViewController(videoPlayerViewController)
            videoPlayerViewController.didMove(toParentViewController: self)
            
            videoPlayerViewController.playAsset(withURL: videoURL)
            
            locationDetailView.isHidden = false
            self.videoPlayerViewController = videoPlayerViewController
        }
    }
    
    private func showGallery(_ gallery: NGDMGallery) {
        closeDetailView()
        
        galleryScrollView.gallery = gallery
        galleryScrollView.isHidden = false
        
        locationDetailView.isHidden = false
    }
    
    private func closeDetailView() {
        locationDetailView.isHidden = true
        
        galleryScrollView.destroyGallery()
        galleryScrollView.isHidden = true
        
        videoPlayerViewController?.willMove(toParentViewController: nil)
        videoPlayerViewController?.view.removeFromSuperview()
        videoPlayerViewController?.removeFromParentViewController()
        videoPlayerViewController = nil
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return location.mediaCount > 0 ? (location.mediaCount + 1) : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (indexPath as NSIndexPath).row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SimpleMapCollectionViewCell.ReuseIdentifier, for: indexPath) as! SimpleMapCollectionViewCell
            cell.setLocation(CLLocationCoordinate2DMake(location.latitude, location.longitude), zoomLevel: location.zoomLevel - 4)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SimpleImageCollectionViewCell.BaseReuseIdentifier, for: indexPath) as! SimpleImageCollectionViewCell
        
        if let experience = location.mediaAtIndex(indexPath.row - 1) {
            cell.playButtonVisible = experience.isType(.audioVisual)
            cell.imageURL = experience.imageURL
        } else {
            cell.playButtonVisible = false
            cell.imageURL = nil
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row == 0 {
            closeDetailView()
            animateToCenter()
            NextGenHook.logAnalyticsEvent(.imeLocationAction, action: .selectMap, itemId: location.analyticsIdentifier)
        } else if let experience = location.mediaAtIndex(indexPath.row - 1) {
            if let url = experience.videoURL {
                playVideo(url)
                NextGenHook.logAnalyticsEvent(.imeLocationAction, action: .selectVideo, itemId: experience.videoID)
            } else if let gallery = experience.gallery {
                showGallery(gallery)
                NextGenHook.logAnalyticsEvent(.imeLocationAction, action: .selectImageGallery, itemId: gallery.analyticsIdentifier)
            }
        }
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width / (DeviceType.IS_IPAD ? 4 : 2.5)), height: collectionView.frame.height)
    }
    
}

extension MapDetailViewController: MultiMapViewDelegate {
    
    func mapView(_ mapView: MultiMapView, didTapMarker marker: MultiMapMarker) {
        animateToCenter()
    }
    
}
