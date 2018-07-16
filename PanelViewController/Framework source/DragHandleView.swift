//
//  DragHandleView.swift
//  PanelViewController
//
//  Created by Ruparelia, Kaushil on 3/1/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

class DragHandleView: UIView {
    
    var handleColor: UIColor? {
        get { return handleView.backgroundColor }
        set { handleView.backgroundColor = newValue }
    }
    
    var separatorColor: UIColor = .clear {
        didSet {
            handleSeparatorView.backgroundColor = separatorColor
        }
    }
    
    private let handleView = UIView()
    private let handleSeparatorView = UIView()
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        guard let _ = newWindow else { return }
        
        handleView.layer.cornerRadius = 3
        addSubview(handleView)
        
        //Set up separator
        addSubview(handleSeparatorView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let dragHandleWidth = CGFloat(44)
        handleView.frame = CGRect(x: (bounds.width / 2) - (dragHandleWidth / 2), y: 8, width: dragHandleWidth, height: 5)
        
        //Added y as height - 11 as in PVC we have the header to be 10 points more in height than what is set, to hide the corner radius at the bottom
        handleSeparatorView.frame = CGRect(x: 0, y: height - 11, width: width, height: 1)
    }
}
