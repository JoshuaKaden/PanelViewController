//
//  ContainerViewController.swift
//  PanelViewController
//
//  Created by Kaden, Joshua on 2/12/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

final class ContainerViewController: UIViewController {
    private let animateDownButton = UIButton()
    private let animateUpButton = UIButton()
    private let panelViewController: PanelViewController
    
    init(panelViewController: PanelViewController) {
        self.panelViewController = panelViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        panelViewController = PanelViewController(coder: aDecoder)!
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .darkGray
        
        adoptChildViewController(panelViewController)
        panelViewController.view?.clipsToBounds = true
        
        animateUpButton.addTarget(self, action: #selector(didTapAnimateUp(_:)), for: .touchUpInside)
        animateUpButton.setTitle(NSLocalizedString("Animate Up", comment: ""), for: .normal)
        animateUpButton.setTitleColor(.white, for: .normal)
        view.addSubview(animateUpButton)

        animateDownButton.addTarget(self, action: #selector(didTapAnimateDown(_:)), for: .touchUpInside)
        animateDownButton.setTitle(NSLocalizedString("Animate Down", comment: ""), for: .normal)
        animateDownButton.setTitleColor(.white, for: .normal)
        view.addSubview(animateDownButton)
    }
    
    deinit {
        panelViewController.leaveParentViewController()
    }
    
    @objc func didTapAnimateDown(_ sender: UIButton) {
        let newState: PaneState
        switch panelViewController.paneState {
        case .closed:
            return
        case .mid:
            newState = .closed
        case .open:
            if panelViewController.showsMidState {
                newState = .mid
            } else {
                newState = .closed
            }
        }
        panelViewController.changeState(to: newState)
    }
    
    @objc func didTapAnimateUp(_ sender: UIButton) {
        let newState: PaneState
        switch panelViewController.paneState {
        case .closed:
            if panelViewController.showsMidState {
                newState = .mid
            } else {
                newState = .open
            }
        case .mid:
            newState = .open
        case .open:
            return
        }
        panelViewController.changeState(to: newState)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let panelView = panelViewController.view
        panelView?.frame = view.frame.insetBy(dx: 24, dy: 120)
        panelView?.center = view.center
        
        animateUpButton.frame = CGRect(x: 0, y: (panelView?.frame.maxY ?? 0) + 16, width: view.frame.width / 2, height: 44)
        animateDownButton.frame = CGRect(x: animateUpButton.frame.maxX, y: animateUpButton.frame.minY, width: view.frame.width / 2, height: 44)
    }
}
