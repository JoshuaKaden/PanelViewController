//
//  PanelViewController.swift
//  PanelViewController
//
//  Created by Kaden, Joshua on 1/24/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

enum PaneState {
    case closed, mid, open
}

class PanelViewController: UIViewController {
    
    // MARK: - Public Properties
    
    var closedHeight = CGFloat(60)
    var midY: CGFloat?
    var openTopMargin = CGFloat(90)

    // MARK: - Private Properties
    
    private lazy var animator = { UIDynamicAnimator(referenceView: view) }()
    private var isFirstLayout = true
    private let mainViewController: UIViewController
    private lazy var paneBehavior = { PaneBehavior(item: paneView) }()
    private let panelViewController: UIViewController
    private(set) var paneState = PaneState.closed
    private let paneView = DraggableView()
    private var stretchAllowance: CGFloat { return (view.bounds.height - openTopMargin) + closedHeight }

    private var targetPoint: CGPoint {
        let size = view.bounds.size
        switch paneState {
        case .closed:
            return CGPoint(x: size.width / 2, y: size.height + (paneView.bounds.size.height / 2 - closedHeight))
        case .mid:
            let y: CGFloat
            if let midY = midY {
                y = midY
            } else {
                y = view.bounds.height / 2
            }
            return CGPoint(x: size.width / 2, y: (paneView.bounds.size.height / 2) + y)
        case .open:
            return CGPoint(x: size.width / 2, y: (paneView.bounds.size.height / 2) + openTopMargin)
        }
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
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isFirstLayout {
            isFirstLayout = false
            let size = view.bounds.size
            paneView.frame = CGRect(x: 0, y: size.height - closedHeight, width: size.width, height: (size.height + stretchAllowance) - openTopMargin)
        }
        
        mainViewController.view.frame = view.bounds
        panelViewController.view.frame = CGRect(x: 0, y: closedHeight, width: paneView.bounds.size.width, height: paneView.bounds.size.height - closedHeight - stretchAllowance)
    }
    
    // MARK: - Private
    
    fileprivate func animatePane(velocity: CGPoint) {
        paneBehavior.targetPoint = targetPoint
        paneBehavior.velocity = velocity
        animator.addBehavior(paneBehavior)
        
        updatePanelViewHeight()
    }
    
    private func calculatePaneViewHeight(state: PaneState) -> CGFloat {
        let paneViewHeight: CGFloat
        let size = view.bounds.size
        switch paneState {
        case .closed, .open:
            paneViewHeight = (size.height + stretchAllowance) - openTopMargin
        case .mid:
            paneViewHeight = ((midY ?? size.height / 2) + stretchAllowance)
        }
        return paneViewHeight
    }
    
    private func updatePanelViewHeight(paneViewHeight: CGFloat? = nil) {
        let superHeight = paneViewHeight ?? calculatePaneViewHeight(state: paneState)
        panelViewController.view.frame = CGRect(x: 0, y: closedHeight, width: paneView.bounds.width, height: superHeight - closedHeight - stretchAllowance)
    }
}

// MARK: - DraggableViewDelegate

extension PanelViewController: DraggableViewDelegate {
    
    func draggingBegan(view: DraggableView) {
        animator.removeAllBehaviors()
        
        let paneViewHeight = calculatePaneViewHeight(state: .open)
        self.updatePanelViewHeight(paneViewHeight: paneViewHeight)
    }
    
    func draggingEnded(view: DraggableView, velocity: CGPoint) {
        if velocity.y >= 0 {
            switch paneState {
            case .closed:
                // no op
                break
            case .mid:
                paneState = .closed
            case .open:
                paneState = .mid
            }
        } else {
            switch paneState {
            case .closed:
                paneState = .mid
            case .mid:
                paneState = .open
            case .open:
                // no op
                break
            }
        }
        animatePane(velocity: velocity)
    }
}
