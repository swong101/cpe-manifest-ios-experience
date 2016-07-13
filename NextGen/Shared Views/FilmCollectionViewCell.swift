//
//  FilmCollectionViewCell.swift
//

import UIKit
import NextGenDataManager

class FilmCollectionViewCell: SimpleImageCollectionViewCell {
    
    static let ReuseIdentifier = "FilmCollectionViewCellReuseIdentifier"
    
    private var getFilmImageSessionDataTask: NSURLSessionDataTask?
    
    var film: TalentFilm? {
        didSet {
            if film != nil {
                getFilmImageSessionDataTask = film!.getImageURL({ (imageURL) in
                    dispatch_async(dispatch_get_main_queue(), {
                        if let imageURL = imageURL {
                            self.imageURL = imageURL
                        } else {
                            self.image = UIImage(named: "Blank Poster")
                        }
                    })
                })
            } else {
                image = nil
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        film = nil
        
        if let task = getFilmImageSessionDataTask {
            task.cancel()
            getFilmImageSessionDataTask = nil
        }
    }
    
}
