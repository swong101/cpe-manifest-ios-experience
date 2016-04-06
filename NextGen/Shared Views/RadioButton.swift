//
//  RadioButton.swift
//  NextGen
//
//  Created by Sedinam Gadzekpo on 2/11/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import UIKit


class RadioButton: UIButton{
    
    var section:Int?
    var index:Int?
    var selection = CAShapeLayer()
    
    
    
    override var selected: Bool {
        didSet {
            toggleButon()
        }

    }



    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    
    func initialize(){
        
        self.userInteractionEnabled = true
        self.clipsToBounds = true
        self.layer.borderWidth = 3
        self.layer.cornerRadius = 0.5*40
        self.layer.borderColor = UIColor.grayColor().CGColor
        self.layer.backgroundColor = UIColor.clearColor().CGColor
        
        selection.frame = CGRectMake(5, 5, 30, 30)
        selection.borderWidth = 3
        selection.cornerRadius = 0.5*30
        selection.borderColor = UIColor.clearColor().CGColor
        self.layer.addSublayer(selection)
    }
    
    

    
    func toggleButon() {
        if self.selected {
            highlight()
 
        } else{
            removeHighlight()

    }
    }
    
    func highlight(){
        //self.selected = !self.selected

        selection.backgroundColor = UIColor.init(red: 255/255, green: 205/255, blue: 77/255, alpha: 1).CGColor
        self.layer.borderColor = UIColor.whiteColor().CGColor
        
        
    }
    
    func removeHighlight(){
        //self.selected = !self.selected
 
        selection.backgroundColor = UIColor.clearColor().CGColor
        self.layer.borderColor = UIColor.grayColor().CGColor
        
    }
    
    
}
