//
//  CustomScrubber.swift
//

import UIKit

class VideoPlayerScrubber: UISlider {
    
    /*private struct Constants {
        static let ThumbRectAdjustment: CGFloat = 0
    }*/
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)!
        
        setup()
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        
        setup()
    }
    
    private func setup() {
        let scrubberImage = UIImage(named: "Scrubber Image")
        self.setThumbImage(scrubberImage, for: .normal)
        self.setThumbImage(scrubberImage, for: .highlighted)
        self.minimumTrackTintColor = UIColor.themePrimary
    }
    
}
