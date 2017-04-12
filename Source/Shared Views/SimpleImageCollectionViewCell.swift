//
//  SimpleImageCollectionViewCell.swift
//

import UIKit

open class SimpleImageCollectionViewCell: UICollectionViewCell {

    public static let NibName = "SimpleImageCollectionViewCell"
    public static let BaseReuseIdentifier = "SimpleImageCollectionViewCellReuseIdentifier"

    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var playButton: UIButton?

    public var showsSelectedBorder = false

    open var imageURL: URL? {
        set {
            DispatchQueue.global(qos: .userInitiated).async {
                if let url = newValue {
                    self.imageView.sd_setImage(with: url)
                } else {
                    self.imageView.sd_cancelCurrentImageLoad()

                    DispatchQueue.main.async {
                        self.imageView.image = nil
                    }
                }
            }
        }

        get {
            return nil
        }
    }

    open var playButtonVisible: Bool {
        set {
            playButton?.isHidden = !newValue
        }

        get {
            return playButton != nil && !playButton!.isHidden
        }
    }

    override open var isSelected: Bool {
        didSet {
            if self.isSelected && showsSelectedBorder {
                self.layer.borderWidth = 2
                self.layer.borderColor = UIColor.white.cgColor
            } else {
                self.layer.borderWidth = 0
                self.layer.borderColor = nil
            }
        }
    }

    override open func prepareForReuse() {
        super.prepareForReuse()

        self.isSelected = false

        imageURL = nil
        playButtonVisible = false
    }

}
