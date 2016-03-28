//
//  MenuItemCell.swift
//  NextGen
//
//  Created by Alec Ananian on 3/25/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import UIKit
import QuartzCore

class MenuItemCell: UITableViewCell {
    
    static let NibName = "MenuItemCell"
    static let ReuseIdentifier = "MenuItemCellReuseIdentifier"
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var menuItem: MenuItem? {
        didSet {
            titleLabel.text = menuItem?.title
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        menuItem = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateCellStyle()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        updateCellStyle()
    }
    
    func updateCellStyle() {
        titleLabel.textColor = (self.selected ? UIColor(netHex: 0xffcd14) : UIColor.whiteColor())
    }

}
