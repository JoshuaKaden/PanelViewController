//
//  OverlayView.swift
//  PanelViewController
//
//  Created by Rynn, David on 5/3/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

class OverlayView: UIView {
    
//    var opacity: CGFloat = 0

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        backgroundColor = backgroundColor?.withAlphaComponent(opacity)
    }

}
