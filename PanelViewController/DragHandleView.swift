//
//  DragHandleView.swift
//  PanelViewController
//
//  Created by Ruparelia, Kaushil on 3/1/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

class DragHandleView: UIView {
    
    let handleView = UIView();
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(handleView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addSubview(handleView)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
