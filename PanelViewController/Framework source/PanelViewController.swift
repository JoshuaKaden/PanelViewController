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
    
    @IBInspectable var closedHeight: CGFloat = PanelViewController.defaultClosedHeight
    @IBInspectable var closedBottomMargin: CGFloat = PanelViewController.defaultClosedBottomMargin
    
    var floatingHeaderMinY: CGFloat?
    
    var floatingHeaderView: UIView? {
        get { return paneView.floatingHeaderView }
        set { paneView.floatingHeaderView = newValue }
    }
    
    var midTopMargin: CGFloat?
	@IBInspectable var openTopMargin: CGFloat = PanelViewController.defaultOpenTopMargin
    
    var panelBackgroundColor: UIColor? {
        get { return paneView.backgroundColor }
        set {
            paneView.backgroundColor = newValue
            dragHandleView.backgroundColor = newValue
        }
    }
    
    var panelHandleColor: UIColor? {
        get { return dragHandleView.handleColor }
        set { dragHandleView.handleColor = newValue }
    }
    
    @IBInspectable var showsMidState: Bool = true
    var startingState: PaneState = .closed

    // MARK: - Public Static Properties
    
    static let defaultClosedHeight = CGFloat(60)
    static let defaultClosedBottomMargin = CGFloat(0)
    static let defaultOpenTopMargin = CGFloat(90)
    
    // MARK: - Private Properties
    
    private lazy var animator = { UIDynamicAnimator(referenceView: view) }()
    private(set) var backViewController: UIViewController?
    @IBInspectable private var backViewControllerStoryBoardID : String?
    private let dragHandleView = DragHandleView()
    private var floatingHeaderHeight: CGFloat { return floatingHeaderView?.bounds.height ?? 0 }
    private var isAnimating = false
    fileprivate var isDragging = false
    private var isFirstLayout = true
    private lazy var paneBehavior = { PaneBehavior(item: paneView) }()
    private(set) var paneState: PaneState = .closed
    private var previousPaneState: PaneState = .closed
    private let paneView = DraggableView()
    private(set) var slidingViewController: UIViewController?
    @IBInspectable private var slidingViewControllerStoryBoardID : String?
    private var stretchAllowance: CGFloat { return (view.bounds.height - openTopMargin) + closedHeight }

    private var targetPoint: CGPoint {
        let size = view.bounds.size
        switch paneState {
        case .closed:
            return CGPoint(x: size.width / 2, y: size.height + (paneView.bounds.size.height / 2 - closedHeight - closedBottomMargin - floatingHeaderHeight))
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
    
    init(backViewController: UIViewController, slidingViewController: UIViewController) {
        self.backViewController = backViewController
        self.slidingViewController = slidingViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guard let mainVCID = self.backViewControllerStoryBoardID else {
            fatalError("Main View Controller ID not specified in Properties Inspector")
        }
        
        guard let panelVCID = self.slidingViewControllerStoryBoardID else {
            fatalError("Panel View Controller ID not specified in Properties Inspector")
        }
        
        self.backViewController = self.storyboard?.instantiateViewController(withIdentifier: mainVCID)
        self.slidingViewController = self.storyboard?.instantiateViewController(withIdentifier: panelVCID)
    }
    
    deinit {
        backViewController?.leaveParentViewController()
        slidingViewController?.leaveParentViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if startingState == .mid && !showsMidState {
            startingState = .closed
        }
        
        paneState = startingState
        previousPaneState = startingState
        
        paneView.delegate = self
        view.addSubview(paneView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapPaneView(_:)))
        dragHandleView.addGestureRecognizer(tap)
        dragHandleView.layer.cornerRadius = 8
        if panelBackgroundColor == nil {
            dragHandleView.backgroundColor = .lightGray
        }
        if dragHandleView.handleColor == nil {
            dragHandleView.handleColor = .darkGray
        }
        paneView.addSubview(dragHandleView)
		
        //We are consciously unwrapping the main and panel view controllers as they would have to be compulsorily instantiated through the custom init or through the awakeFromNib()
        adoptChildViewController(backViewController!)
        adoptChildViewController(slidingViewController!, targetView: paneView)
        
        view.bringSubview(toFront: paneView)
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isAnimating { return }
        
        let viewSize = view.bounds.size
        var paneY: CGFloat = 0
        switch paneState {
        case .closed:
            paneY = viewSize.height - closedHeight - closedBottomMargin - floatingHeaderHeight
        case .mid:
            paneY = midTopMargin ?? viewSize.height / 2
        case .open:
            paneY = openTopMargin
        }
        
        if isFirstLayout {
            isFirstLayout = false
            paneView.frame = CGRect(x: 0, y: paneY, width: viewSize.width, height: (viewSize.height + 88) - paneY)
        }
        
        backViewController?.view.frame = view.bounds
        
        let offset: CGFloat
        offset = floatingHeaderHeight
        
        if isDragging {
            slidingViewController?.view.frame = CGRect(x: 0, y: closedHeight + offset, width: paneView.bounds.width, height: viewSize.height - closedHeight)
        } else {
            slidingViewController?.view.frame = CGRect(x: 0, y: closedHeight + offset, width: paneView.bounds.width, height: viewSize.height - closedHeight - paneY)
        }

        dragHandleView.frame = CGRect(x: 0, y: offset, width: paneView.frame.size.width, height: closedHeight + offset)
        floatingHeaderView?.frame = CGRect(x: 0, y: 0, width: paneView.bounds.width, height: floatingHeaderHeight)
        
        paneView.frame = CGRect(x: 0, y: paneView.frame.origin.y, width: paneView.frame.size.width, height: paneView.frame.size.height)
    }
    
    // MARK: - Handlers
    
    @objc func didTapPaneView(_ sender: UITapGestureRecognizer) {
        var paneFrame = paneView.frame
        paneFrame.size.height = view.bounds.height + 88
        paneView.frame = paneFrame
        
        slidingViewController?.view.frame = CGRect(x: 0, y: closedHeight + floatingHeaderHeight, width: paneView.bounds.width, height: view.bounds.height - closedHeight - floatingHeaderHeight)
        delay(0.33) {
            self.view.setNeedsLayout()
        }
        
        let velocity: CGPoint
        if showsMidState {
            velocity = calculateVelocity()
        } else {
            velocity = paneBehavior.velocity
        }
        performStateChange(velocity: velocity)
    }
    
    // MARK: - Public Methods
    
    func changeState(to newState: PaneState) {
        if newState == .mid && !showsMidState {
            return
        }
        
        previousPaneState = paneState
        paneState = newState
        animatePane(velocity: calculateVelocity())
    }
    
    // MARK: - Private Methods
    
    fileprivate func animatePane(velocity: CGPoint) {
        var paneFrame = paneView.frame
        paneFrame.size.height = view.bounds.height + 88
        paneView.frame = paneFrame
        
        slidingViewController?.view.frame = CGRect(x: 0, y: closedHeight + floatingHeaderHeight, width: paneView.bounds.width, height: view.bounds.height - closedHeight - floatingHeaderHeight)
        
        paneBehavior.targetPoint = targetPoint
        paneBehavior.velocity = velocity
        
        isAnimating = true
        animator.addBehavior(paneBehavior)
        
        delay(0.33) {
            self.isAnimating = false
            self.view.setNeedsLayout()
        }
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
        
        slidingViewController?.view.frame = CGRect(x: 0, y: closedHeight, width: paneView.bounds.width, height: view.bounds.height - closedHeight)
    }
    
    func draggingEnded(view: DraggableView, velocity: CGPoint) {
        isDragging = false
        performStateChange(velocity: velocity)
    }
}
