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
    
    var closedHeight = PanelViewController.defaultClosedHeight
    var midTopMargin: CGFloat?
	var openTopMargin = PanelViewController.defaultOpenTopMargin
    var panelBackgroundColor: UIColor? {
        get { return paneView.backgroundColor }
        set { paneView.backgroundColor = newValue }
    }
    var panelHandleColor: UIColor? {
        get { return dragHandleView.backgroundColor }
        set { dragHandleView.backgroundColor = newValue }
    }
    var showsMidState = true

    // MARK: - Public Static Properties
    
    static let defaultClosedHeight = CGFloat(60)
    static let defaultOpenTopMargin = CGFloat(90)
    
    // MARK: - Private Properties
    
    private lazy var animator = { UIDynamicAnimator(referenceView: view) }()
    private let dragHandleView = UIView()
    fileprivate var isDragging = false
    private var isFirstLayout = true
    private let mainViewController: UIViewController
    private lazy var paneBehavior = { PaneBehavior(item: paneView) }()
    private let panelViewController: UIViewController
    private(set) var paneState = PaneState.closed
    private var previousPaneState = PaneState.closed
    private let paneView = DraggableView()
    private var stretchAllowance: CGFloat { return (view.bounds.height - openTopMargin) + closedHeight }

    private var targetPoint: CGPoint {
        let size = view.bounds.size
        switch paneState {
        case .closed:
            return CGPoint(x: size.width / 2, y: size.height + (paneView.bounds.size.height / 2 - closedHeight))
        case .mid:
            let y: CGFloat
            if let midTopMargin = midTopMargin {
                y = midTopMargin
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapPaneView(_:)))
        paneView.addGestureRecognizer(tap)
        paneView.backgroundColor = .lightGray
        paneView.delegate = self
        paneView.layer.cornerRadius = 8
        view.addSubview(paneView)
        
        if dragHandleView.backgroundColor == nil {
            dragHandleView.backgroundColor = .darkGray
        }
        dragHandleView.layer.cornerRadius = 3
        paneView.addSubview(dragHandleView)
		
        adoptChildViewController(mainViewController)
        adoptChildViewController(panelViewController, targetView: paneView)
        
        view.bringSubview(toFront: paneView)
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
        updatePanelViewHeight()
        
        let dragHandleWidth = CGFloat(44)
        dragHandleView.frame = CGRect(x: (paneView.bounds.width / 2) - (dragHandleWidth / 2), y: 8, width: dragHandleWidth, height: 5)
    }
    
    // MARK: - Handlers
    
    @objc func didTapPaneView(_ sender: UITapGestureRecognizer) {
        if showsMidState {
            let velocity = calculateVelocity()
            performStateChange(velocity: velocity)
            return
        }
        performStateChange(velocity: paneBehavior.velocity)
    }
    
    // MARK: - Public Methods
    
    func changeState(to newState: PaneState, animated: Bool = true) {
        if newState == .mid && !showsMidState {
            return
        }
        previousPaneState = paneState
        paneState = newState
        if animated {
            animatePane(velocity: calculateVelocity())
        } else {
            updatePanelViewHeight()
            var frame = paneView.frame
            switch newState {
            case .closed:
                frame.origin.y = view.frame.height - closedHeight
            case .mid:
                guard showsMidState else { return }
                frame.origin.y = midTopMargin ?? view.bounds.height / 2
            case .open:
                frame.origin.y = openTopMargin
            }
            paneView.frame = frame
        }
    }
    
    // MARK: - Private Methods
    
    fileprivate func animatePane(velocity: CGPoint) {
        paneBehavior.targetPoint = targetPoint
        paneBehavior.velocity = velocity
        animator.addBehavior(paneBehavior)
        
        delay(0.1) {
            [weak self] in
            self?.updatePanelViewHeight()
        }
    }
    
    private func calculatePanelViewHeight(state: PaneState) -> CGFloat {
        let panelViewHeight: CGFloat
        let size = view.bounds.size
        switch paneState {
        case .closed, .open:
            panelViewHeight = (size.height + stretchAllowance) - openTopMargin
        case .mid:
            if let midTopMargin = midTopMargin {
                panelViewHeight = (size.height - midTopMargin) + stretchAllowance
            } else {
                panelViewHeight = (size.height / 2) + stretchAllowance
            }
        }
        return panelViewHeight
    }
    
    private func calculateVelocity() -> CGPoint {
        let directionY: CGFloat
        switch previousPaneState {
        case .closed:
            directionY = -1
        case .mid:
            if paneState == .closed {
                directionY = -1
            } else {
                directionY = 1
            }
        case .open:
            directionY = 1
        }
        return CGPoint(x: 0, y: directionY)
    }
    
    fileprivate func performStateChange(velocity: CGPoint) {
        togglePaneState(velocity: velocity)
        animatePane(velocity: velocity)
    }
    
    private func togglePaneState(velocity: CGPoint) {
        if showsMidState {
            updatePaneState(velocity: velocity)
            return
        }
        if paneState == .open {
            paneState = .closed
        } else {
            paneState = .open
        }
    }
    
    private func updatePanelViewHeight() {
        let panelHeight: CGFloat
        if isDragging {
            panelHeight = calculatePanelViewHeight(state: .open)
        } else {
            panelHeight = calculatePanelViewHeight(state: paneState)
        }
        panelViewController.view.frame = CGRect(x: 0, y: closedHeight, width: paneView.bounds.width, height: panelHeight - closedHeight - stretchAllowance)
    }
    
    fileprivate func updatePaneState(velocity: CGPoint) {
        previousPaneState = paneState
        
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
            return
        }
        
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
}

// MARK: - DraggableViewDelegate

extension PanelViewController: DraggableViewDelegate {
    
    func draggingBegan(view: DraggableView) {
        animator.removeAllBehaviors()
        isDragging = true
        updatePanelViewHeight()
    }
    
    func draggingEnded(view: DraggableView, velocity: CGPoint) {
        performStateChange(velocity: velocity)
        isDragging = false
    }
}
