//
//  PanelViewController.swift
//  PanelViewController
//
//  Created by Kaden, Joshua on 1/24/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

/**
 The three possible states of the panel that contains the sliding view controller.
 */
enum PanelState {
    case closed, mid, open
}

/**
 A UIViewController that contains a back view controller, and a sliding view controller.
 
 The sliding view controller is on a panel that can be dragged up and down, over the back view controller.
 
 You can instantiate this directly, or subclass; either via code or on a storyboard.
 */
class PanelViewController: UIViewController {
    
    // MARK: - Public Properties
    
    /**
     The height of the panel when it is closed.
     
     Increasing this value will increase the height of the drag area.
     
     The default value is `60`.
     */
    @IBInspectable var closedHeight: CGFloat = PanelViewController.defaultClosedHeight
    
    /**
     The distance between the bottom of the drag area and the bottom of the view.
     
     Increasing this value will show a portion of the sliding view controller when the panel state is `.closed`.
     
     The default value is `0`.
     */
    @IBInspectable var closedBottomMargin: CGFloat = PanelViewController.defaultClosedBottomMargin
    
    /**
     If you have defined a `floatingHeaderView`, this property will determine the minimum `Y` for this view.
     
     The floating header view will move with the panel, but it will not move to a `Y` position that is less than this property.
     
     This is useful if you want a button to appear over the drag area, but you want it to be hidden based on the panel's height.
     
     If this value is `nil`, then half the view's height is used.
     
     The default value is `nil`.
     */
    var floatingHeaderMinY: CGFloat?
    
    /**
     This view will be shown above the drag area, and will move with it.
     
     Its origin will be adjusted, and its width. Its height will be preserved, so make sure to set the desired height yourself.
     
     It can function as a "pass-through" view for touches: Override `point(inside: with:)`, returning `false` for the areas you wish to pass through.
     
     If this value is `nil`, then no floating header will be displayed.
     
     The default value is `nil`.
     */
    var floatingHeaderView: UIView? {
        get { return paneView.floatingHeaderView }
        set { paneView.floatingHeaderView = newValue }
    }
    
    /**
     The distance between the panel and the top of the view when the panel state equals `.mid`.
     
     If this value is `nil`, then half the view's height is used.
     
     The default value is `nil`.
     */
    var midTopMargin: CGFloat?
    
    /**
     The distance between the panel and the top of the view when the panel state equals `.open`.
     
     The default value is `90`.
     */
	@IBInspectable var openTopMargin: CGFloat = PanelViewController.defaultOpenTopMargin
    
    /**
     The background color of the panel's drag area.
     */
    var panelBackgroundColor: UIColor? {
        get { return paneView.backgroundColor }
        set {
            paneView.backgroundColor = newValue
            dragHandleView.backgroundColor = newValue
        }
    }
    
    /**
     The background color of the panel's drag area handle.
     */
    var panelHandleColor: UIColor? {
        get { return dragHandleView.handleColor }
        set { dragHandleView.handleColor = newValue }
    }
    
    /**
     If `true`, there are three possible states for the panel: open, closed, and mid.
     
     If `false`, the panel is either open or closed.
     */
    @IBInspectable var showsMidState: Bool = true
    
    /**
     The intitial panel state. The default is `.closed`.
     */
    var startingState: PanelState = .closed
	
    //start point for backView to begin darkening
    var darkeningMinY: CGFloat = 0

    // MARK: - Public Static Properties
    
    static let defaultClosedHeight = CGFloat(60)
    static let defaultClosedBottomMargin = CGFloat(0)
    static let defaultOpenTopMargin = CGFloat(90)
    
    // MARK: - Private Properties
    
    //this view controls the darkening and screen effects over the back view
    private let backViewOverlay = PassThroughView()
    private lazy var animator = { UIDynamicAnimator(referenceView: view) }()
    private(set) var backViewController: UIViewController?
    @IBInspectable private var backViewControllerStoryBoardID : String?
    private let dragHandleView = DragHandleView()
    private var floatingHeaderHeight: CGFloat { return floatingHeaderView?.bounds.height ?? 0 }
    private var isAnimating = false
    fileprivate var isDragging = false
    private var isFirstLayout = true
    private lazy var paneBehavior = { PaneBehavior(item: paneView) }()
    private(set) var panelState: PanelState = .closed
    @objc private let paneView = DraggableView()
    private var previousPaneState: PanelState = .closed
    private(set) var slidingViewController: UIViewController?
    @IBInspectable private var slidingViewControllerStoryBoardID : String?
    private var stretchAllowance: CGFloat { return (view.bounds.height - openTopMargin) + closedHeight }

    private var targetPoint: CGPoint {
        let size = view.bounds.size
        switch panelState {
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
        
        panelState = startingState
        previousPaneState = startingState
        
        paneView.delegate = self
        view.addSubview(paneView)
        
        setupBackViewOverlay()
        
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
        
        //We are consciously force unwrapping the main and panel view controllers as they would have to be compulsorily instantiated through the custom init or through the awakeFromNib()
        adoptChildViewController(backViewController!)
        adoptChildViewController(slidingViewController!, targetView: paneView)
        
        view.bringSubview(toFront: backViewOverlay)
        view.bringSubview(toFront: paneView)
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isAnimating { return }
        
        let viewSize = view.bounds.size
        let midTopMargin = self.midTopMargin ?? viewSize.height / 2
        var paneY: CGFloat = 0
        switch panelState {
        case .closed:
            paneY = viewSize.height - closedHeight - closedBottomMargin - floatingHeaderHeight
        case .mid:
            paneY = midTopMargin
        case .open:
            paneY = openTopMargin
        }
        
        if isFirstLayout {
            isFirstLayout = false
            paneView.frame = CGRect(x: 0, y: paneY, width: viewSize.width, height: (viewSize.height + 88) - paneY)
        }
        
        backViewController?.view.frame = view.bounds
        backViewOverlay.frame = backViewController?.view.frame ?? CGRect.zero
        
        let offset: CGFloat = floatingHeaderHeight
        dragHandleView.frame = CGRect(x: 0, y: offset, width: paneView.bounds.width, height: closedHeight + offset)
        
        if let floatingHeaderView = floatingHeaderView {
            let floatingHeaderMinY = self.floatingHeaderMinY ?? view.bounds.height / 2
            let frame = CGRect(x: 0, y: 0, width: paneView.bounds.width, height: floatingHeaderHeight)
            if paneView.frame.origin.y < floatingHeaderMinY {
                let floatOffset = floatingHeaderMinY - paneView.frame.origin.y
                floatingHeaderView.frame = CGRect(x: frame.origin.x, y: floatOffset, width: frame.size.width, height: floatingHeaderHeight)
            } else {
                floatingHeaderView.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: floatingHeaderHeight)
            }
        }
        
        if isDragging {
            slidingViewController?.view.frame = CGRect(x: 0, y: closedHeight + offset, width: paneView.bounds.width, height: viewSize.height - closedHeight)
        } else {
            slidingViewController?.view.frame = CGRect(x: 0, y: closedHeight + offset, width: paneView.bounds.width, height: viewSize.height - closedHeight - paneY - offset)
        }

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
    
    /**
     Animates the pane to the specified state.
     
     - Parameter to: The desired state
     */
    func changeState(to newState: PanelState) {
        if newState == .mid && !showsMidState {
            return
        }
        
        previousPaneState = panelState
        panelState = newState
        animatePane(velocity: calculateVelocity())
    }
    
    // MARK: - Private Methods
    
    fileprivate func animatePane(velocity: CGPoint) {
        var paneFrame = paneView.frame
        paneFrame.size.height = view.bounds.height + 88
        paneView.frame = paneFrame
        // We're using targetY as a reference point for the darkening overlay
        let targetY: CGFloat
        switch panelState {
        case .closed:
            targetY = view.bounds.height - closedHeight
        case .mid:
            targetY = midTopMargin ?? view.bounds.size.height / 2
        case .open:
            targetY = openTopMargin
        }
        
        if let floatingHeaderView = floatingHeaderView {
            let frame = CGRect(x: 0, y: 0, width: paneView.bounds.width, height: floatingHeaderHeight)
            let targetY = targetPoint.y - (paneView.bounds.height / 2)
            
            let floatTargetY: CGFloat
            let floatingHeaderMinY = self.floatingHeaderMinY ?? view.bounds.height / 2
            if targetY < floatingHeaderMinY {
                floatTargetY = floatingHeaderMinY
            } else {
                floatTargetY = 0
            }
            
            UIView.animate(withDuration: 0.33, animations: {
                floatingHeaderView.frame = CGRect(x: frame.origin.x, y: floatTargetY, width: frame.size.width, height: self.floatingHeaderHeight)
                self.darkenOverlay(targetY: targetY)
            })
        } else {
            UIView.animate(withDuration: 0.33, animations: {
                self.darkenOverlay(targetY: targetY)
            })
        }
        
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
    
    private func calculateOverlayOpacity(maxOpacity: CGFloat, targetY: CGFloat) -> CGFloat {
        //if the pane should not begin darkening return no opacity
        if targetY > darkeningMinY { return 0 }
        //subtract the percentage of the sliding panel vs the minY
        let ratio = targetY / darkeningMinY
        return maxOpacity - ratio
    }

    private func calculateVelocity() -> CGPoint {
        let directionY: CGFloat
        switch previousPaneState {
        case .closed:
            directionY = -1
        case .mid:
            if panelState == .closed {
                directionY = -1
            } else {
                directionY = 1
            }
        case .open:
            directionY = 1
        }
        return CGPoint(x: 0, y: directionY)
    }
    
    private func darkenOverlay(targetY: CGFloat) {
        let overlayAlpha: CGFloat =  calculateOverlayOpacity(maxOpacity: 0.85, targetY: targetY)
        backViewOverlay.backgroundColor = UIColor.black.withAlphaComponent(overlayAlpha)
    }
    
    fileprivate func performStateChange(velocity: CGPoint) {
        togglePaneState(velocity: velocity)
        animatePane(velocity: velocity)
    }
    
    private func setupBackViewOverlay() {
        darkeningMinY = view.frame.height/2
        darkenOverlay(targetY: targetPoint.y)
        view.addSubview(backViewOverlay)
    }

    private func togglePaneState(velocity: CGPoint) {
        if showsMidState {
            updatePaneState(velocity: velocity)
            return
        }
        if panelState == .open {
            panelState = .closed
        } else {
            panelState = .open
        }
    }
    
    fileprivate func updatePaneState(velocity: CGPoint) {
        previousPaneState = panelState
        
        if velocity.y >= 0 {
            switch panelState {
            case .closed:
                // no op
                break
            case .mid:
                panelState = .closed
            case .open:
                panelState = .mid
            }
            return
        }
        
        switch panelState {
        case .closed:
            panelState = .mid
        case .mid:
            panelState = .open
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
        slidingViewController?.view.frame = CGRect(x: 0, y: closedHeight + floatingHeaderHeight, width: paneView.bounds.width, height: view.bounds.height - closedHeight)
    }
    
    func draggingChanged(view: DraggableView, location: CGPoint) {
        let thisLocation = view.convert(location, to: self.view)
        if thisLocation.y < openTopMargin {
            view.cancelDrag()
            return
        }
        darkenOverlay(targetY: thisLocation.y)
    }
    
    func draggingEnded(view: DraggableView, velocity: CGPoint) {
        isDragging = false
        performStateChange(velocity: velocity)
    }    
}
