//
//  PassThroughView.swift
//  PanelViewController
//
//  Created by Rynn, David on 5/3/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

class PassThroughView: UIView {
    
    /// Default Opacity of the pass through view when the PVC animates to open state
    static let defaultOverlayFinalOpacity: CGFloat = 0.6
    
    /// Default Color of the pass through view when the PVC animates to open state
    static let defaultOverlayColor = UIColor.black
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }

}
