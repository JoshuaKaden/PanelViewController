//
//  PanelViewController.swift
//  PanelViewController
//
//  Created by Kaden, Joshua on 1/24/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

enum PaneState {
    case closed, open
}

class PanelViewController: UIViewController {
    
    // MARK: - Public Properties
    
    var closedHeight = CGFloat(55)
    var openTopMargin = CGFloat(55)

    // MARK: - Private Properties
    
    private lazy var animator = { UIDynamicAnimator(referenceView: view) }()
    private var isFirstLayout = true
    private let mainViewController: UIViewController
    private lazy var paneBehavior = { PaneBehavior(item: paneView) }()
    private let panelViewController: UIViewController
    private(set) var paneState = PaneState.closed
    private let paneView = DraggableView()
    
    private var targetPoint: CGPoint {
        let size = view.bounds.size
        if paneState == .closed {
            return CGPoint(x: size.width / 2, y: size.height + (paneView.bounds.size.height / 2 - closedHeight))
        }
        return CGPoint(x: size.width / 2, y: size.height / 2 + openTopMargin)
    }
    
    // MARK: - Lifecycle
    
    init(mainViewController: UIViewController, panelViewController: UIViewController) {
        self.mainViewController = mainViewController
        self.panelViewController = panelViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        // Currently, not able to invoke via a storyboard.
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        mainViewController.leaveParentViewController()
        panelViewController.leaveParentViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        adoptChildViewController(mainViewController)
        adoptChildViewController(panelViewController, targetView: paneView)
        
        paneView.backgroundColor = .lightGray
        paneView.delegate = self
        paneView.layer.cornerRadius = 8
        view.addSubview(paneView)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        view.addGestureRecognizer(recognizer)
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isFirstLayout {
            isFirstLayout = false
            let size = view.bounds.size
            paneView.frame = CGRect(x: 0, y: size.height - closedHeight, width: size.width, height: size.height - openTopMargin)
        }
        
        mainViewController.view.frame = view.bounds
        panelViewController.view.frame = CGRect(x: 0, y: closedHeight, width: paneView.bounds.size.width, height: paneView.bounds.size.height - closedHeight)
    }
    
    // MARK: - Actions
    
    @objc func didTap(_ recognizer: UITapGestureRecognizer) {
        if paneState == .closed {
            paneState = .open
        } else {
            paneState = .closed
        }
        animatePane(velocity: paneBehavior.velocity)
    }
    
    // MARK: - Private
    
    fileprivate func animatePane(velocity: CGPoint) {
        paneBehavior.targetPoint = targetPoint
        paneBehavior.velocity = velocity
        animator.addBehavior(paneBehavior)
    }
}

// MARK: - DraggableViewDelegate

extension PanelViewController: DraggableViewDelegate {
    
    func draggingBegan(view: DraggableView) {
        animator.removeAllBehaviors()
    }
    
    func draggingEnded(view: DraggableView, velocity: CGPoint) {
        if velocity.y >= 0 {
            paneState = .closed
        } else {
            paneState = .open
        }
        animatePane(velocity: velocity)
    }
}
