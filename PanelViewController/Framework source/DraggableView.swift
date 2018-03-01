//
//  DraggableView.swift
//  PanelViewController
//
//  Created by Kaden, Joshua on 1/24/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

protocol DraggableViewDelegate: class {
    func draggingBegan(view: DraggableView)
    func draggingEnded(view: DraggableView, velocity: CGPoint)
}

class DraggableView: UIView {
    weak var delegate: DraggableViewDelegate?
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        guard let _ = newWindow else { return }
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        addGestureRecognizer(recognizer)
    }
    
    @objc func didPan(_ recognizer: UIPanGestureRecognizer) {
        guard let targetView = superview else { return }
        let point = recognizer.translation(in: targetView)

        var frame = self.frame
        frame.size.height = targetView.bounds.height - frame.minY
        self.frame = frame
        
        center = CGPoint(x: center.x, y: center.y + point.y)
        
        recognizer.setTranslation(CGPoint.zero, in: targetView)
        switch recognizer.state {
        case .began:
            delegate?.draggingBegan(view: self)
        case .ended:
            let velocity = recognizer.velocity(in: targetView)
            delegate?.draggingEnded(view: self, velocity: CGPoint(x: 0, y: velocity.y))
        default:
            // no op
            break
        }
    }
}
