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

    // MARK: - Public Static Properties
    
    static let defaultClosedHeight = CGFloat(60)
    static let defaultClosedBottomMargin = CGFloat(0)
    static let defaultOpenTopMargin = CGFloat(90)
    
    // MARK: - Private Properties
    
    private lazy var animator = { UIDynamicAnimator(referenceView: view) }()
    private let dragHandleView = DragHandleView()
    private var isAnimating = false
    fileprivate var isDragging = false
    private var isFirstLayout = true
    private(set) var mainViewController: UIViewController?
    private lazy var paneBehavior = { PaneBehavior(item: paneView) }()
    private(set) var panelViewController: UIViewController?
    private(set) var paneState = PaneState.closed
    private var previousPaneState = PaneState.closed
    private let paneView = DraggableView()
    @IBInspectable private var  mainViewControllerStoryBoardID : String?
    @IBInspectable private var  panelViewControllerStoryBoardID : String?
    private var stretchAllowance: CGFloat { return (view.bounds.height - openTopMargin) + closedHeight }

    private var targetPoint: CGPoint {
        let size = view.bounds.size
        switch paneState {
        case .closed:
            return CGPoint(x: size.width / 2, y: size.height + (paneView.bounds.size.height / 2 - closedHeight - closedBottomMargin))
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

        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guard let mainVCID = self.mainViewControllerStoryBoardID else {
            fatalError("Main View Controller ID not specified in Properties Inspector")
        }
        
        guard let panelVCID = self.panelViewControllerStoryBoardID else {
            fatalError("Panel View Controller ID not specified in Properties Inspector")
        }
        
        self.mainViewController = self.storyboard?.instantiateViewController(withIdentifier: mainVCID)
        self.panelViewController = self.storyboard?.instantiateViewController(withIdentifier: panelVCID)
    }
    
    deinit {
        mainViewController?.leaveParentViewController()
        panelViewController?.leaveParentViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapPaneView(_:)))
        dragHandleView.addGestureRecognizer(tap)
        paneView.backgroundColor = .lightGray
        paneView.delegate = self
        paneView.layer.cornerRadius = 8
        view.addSubview(paneView)
        
        if dragHandleView.handleColor == nil {
            dragHandleView.handleColor = .darkGray
        }
        paneView.addSubview(dragHandleView)
		
        //We are consciously unwrapping the main and panel view controllers as they would have to be compulsorily instantiated through the custom init or through the awakeFromNib()
        adoptChildViewController(mainViewController!)
        adoptChildViewController(panelViewController!, targetView: paneView)
        
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
            paneY = viewSize.height - closedHeight - closedBottomMargin
        case .mid:
            paneY = midTopMargin ?? viewSize.height / 2
        case .open:
            paneY = openTopMargin
        }
        
        if isFirstLayout {
            isFirstLayout = false
            paneView.frame = CGRect(x: 0, y: paneY, width: viewSize.width, height: (viewSize.height + 88) - paneY)
        }
        
        mainViewController?.view.frame = view.bounds
        if isDragging {
            panelViewController?.view.frame = CGRect(x: 0, y: closedHeight, width: paneView.bounds.width, height: viewSize.height - closedHeight)
        } else {
            panelViewController?.view.frame = CGRect(x: 0, y: closedHeight, width: paneView.bounds.width, height: viewSize.height - closedHeight - paneY)
        }

        dragHandleView.frame = CGRect(x: 0, y: 0, width: paneView.frame.size.width, height: closedHeight)
    }
    
    // MARK: - Handlers
    
    @objc func didTapPaneView(_ sender: UITapGestureRecognizer) {
        var paneFrame = paneView.frame
        paneFrame.size.height = view.bounds.height + 88
        paneView.frame = paneFrame
        
        panelViewController?.view.frame = CGRect(x: 0, y: closedHeight, width: paneView.bounds.width, height: view.bounds.height - closedHeight)
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
        
        panelViewController?.view.frame = CGRect(x: 0, y: closedHeight, width: paneView.bounds.width, height: view.bounds.height - closedHeight)
        
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
    }
    
    func draggingEnded(view: DraggableView, velocity: CGPoint) {
        isDragging = false
        performStateChange(velocity: velocity)
    }
}
