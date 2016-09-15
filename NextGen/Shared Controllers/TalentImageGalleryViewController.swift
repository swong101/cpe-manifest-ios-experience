//
//  TalentImageGalleryViewController.swift
//

import UIKit
import NextGenDataManager

class TalentImageGalleryViewController: SceneDetailViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak fileprivate var galleryScrollView: ImageGalleryScrollView!
    @IBOutlet weak fileprivate var galleryCollectionView: UICollectionView!
    
    var talent: NGDMTalent!
    var initialPage = 0
    
    fileprivate var galleryDidScrollToPageObserver: NSObjectProtocol?
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        galleryScrollView.cleanInvisibleImages()
    }

    override func viewDidLoad() {
        self.title = String.localize("talentdetail.gallery")
        
        super.viewDidLoad()
        
        galleryScrollView.currentPage = initialPage
        galleryScrollView.removeToolbar()
        
        galleryDidScrollToPageObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: ImageGalleryNotification.DidScrollToPage), object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            if let strongSelf = self, let page = (notification as NSNotification).userInfo?["page"] as? Int {
                let pageIndexPath = IndexPath(item: page, section: 0)
                strongSelf.galleryCollectionView.selectItem(at: pageIndexPath, animated: false, scrollPosition: UICollectionViewScrollPosition())
                
                var cellIsShowing = false
                for cell in strongSelf.galleryCollectionView.visibleCells {
                    if let indexPath = strongSelf.galleryCollectionView.indexPath(for: cell) , (indexPath as NSIndexPath).row == page {
                        cellIsShowing = true
                        break
                    }
                }
                
                if !cellIsShowing {
                    strongSelf.galleryCollectionView.scrollToItem(at: pageIndexPath, at: .centeredHorizontally, animated: true)
                }
            }
        })
        
        galleryCollectionView.register(UINib(nibName: "SimpleImageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: SimpleImageCollectionViewCell.BaseReuseIdentifier)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var pictures = [NGDMPicture]()
        if let talentImages = talent.images {
            for talentImage in talentImages {
                if let imageURL = talentImage.imageURL {
                    pictures.append(NGDMPicture(imageURL: imageURL))
                }
            }
        }
        
        let gallery = NGDMGallery(pictures: pictures)
        galleryScrollView.loadGallery(gallery)
        galleryScrollView.gotoPage(initialPage, animated: false)
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return talent.images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SimpleImageCollectionViewCell.BaseReuseIdentifier, for: indexPath) as! SimpleImageCollectionViewCell
        cell.showsSelectedBorder = true
        cell.isSelected = ((indexPath as NSIndexPath).row == galleryScrollView.currentPage)
        cell.imageURL = talent.images?[indexPath.row].thumbnailImageURL
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        galleryScrollView.gotoPage((indexPath as NSIndexPath).row, animated: true)
    }

}
