//
//  ButtonContainerView.swift
//  PanelViewController
//
//  Created by Kaden, Joshua on 4/30/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

final class ButtonContainerView: UIView {
    private let button = UIButton()
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        guard let _ = newWindow else { return }
        
        button.backgroundColor = .white
        button.setTitle("Center", for: .normal)
        button.setTitleColor(.black, for: .normal)
        addSubview(button)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let buttonX = bounds.width - 100 - 8
        let buttonFrame = CGRect(x: buttonX, y: 8, width: 100, height: 44)
        button.frame = buttonFrame
    }
}
