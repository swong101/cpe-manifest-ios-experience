//
//  GalleryDetailViewController.swift
//  NextGen
//
//  Created by Sedinam Gadzekpo on 2/29/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import UIKit


class GalleryDetailViewController: UIViewController{
    
    
    @IBOutlet weak var pageControl: UIPageControl!
    var galleryID = 0
    
    func imageGalleryViewController() -> ImageGalleryViewController? {
        for viewController in self.childViewControllers {
            if viewController is ImageGalleryViewController {
                return viewController as? ImageGalleryViewController
            }
        }
        
        return nil
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let experience = NextGenDataManager.sharedInstance.outOfMovieExperienceCategories()[4]
        let thisExperience = experience.childExperiences()[self.galleryID]
        let imageGallery = thisExperience.imageGallery()
        let imageViewController = imageGalleryViewController()
        
        imageViewController?.imageGallery = imageGallery
        self.pageControl.numberOfPages = (thisExperience.imageGallery()?.pictures().count)!
        NSNotificationCenter.defaultCenter().addObserverForName("updateControl", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            if let userInfo = notification.userInfo {
                self.pageControl.currentPage = userInfo["index"] as! Int

               
            }
        }
    }
    
    
    
    @IBAction func close(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
