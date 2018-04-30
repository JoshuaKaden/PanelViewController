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
    var buttonAction: (() -> Void)?
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        guard let _ = newWindow else { return }
        
        button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
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
    
    @objc func didTapButton(_ sender: UIButton) {
        if let buttonAction = buttonAction {
            buttonAction()
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if button.point(inside: convert(point, to: button), with: event) {
            return true
        }
        
        return false
    }

}
