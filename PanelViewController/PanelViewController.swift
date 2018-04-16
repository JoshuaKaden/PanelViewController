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

enum PaneBehaviorType: CustomStringConvertible {
    case length, resistance, damping, frequency
    
    var description: String {
        switch self {
        case .length:
            return "Length"
        case .resistance:
            return "Resistance"
        case .damping:
            return "Damping"
        case .frequency:
            return "Frequency"
        }
    }
    
}

struct SliderStruct {
    let slider: UISlider
    let label: UILabel
    let type: PaneBehaviorType
}

class PanelViewController: UIViewController {
    
    // MARK: - Public Properties
    
    @IBInspectable var closedHeight: CGFloat = PanelViewController.defaultClosedHeight
    @IBInspectable var closedBottomMargin: CGFloat = PanelViewController.defaultClosedBottomMargin
    var midTopMargin: CGFloat?
	@IBInspectable var openTopMargin: CGFloat = PanelViewController.defaultOpenTopMargin
    var panelBackgroundColor: UIColor? {
        get { return paneView.backgroundColor }
        set { paneView.backgroundColor = newValue }
    }
    var panelHandleColor: UIColor? {
        get { return dragHandleView.backgroundColor }
        set { dragHandleView.backgroundColor = newValue }
    }
    @IBInspectable var showsMidState: Bool = true

    // MARK: - Public Static Properties
    
    static let defaultClosedHeight = CGFloat(60)
    static let defaultClosedBottomMargin = CGFloat(0)
    static let defaultOpenTopMargin = CGFloat(90)
    
    // MARK: - Private Properties
    
    private lazy var animator = { UIDynamicAnimator(referenceView: view) }()
    private let dragHandleView = UIView()
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
    @IBOutlet weak var slider1: UISlider!
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var slider2: UISlider!
    
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var slider3: UISlider!
 
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var slider4: UISlider!
    
    @IBOutlet weak var label4: UILabel!
    private var sliderStructs: [ SliderStruct] = []
    
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
		
        //We are consciously unwrapping the main and panel view controllers as they would have to be compulsorily instantiated through the custom init or through the awakeFromNib()
        adoptChildViewController(mainViewController!)
        adoptChildViewController(panelViewController!, targetView: paneView)
        //expiremental

        sliderStructs = [ SliderStruct(slider: slider1, label: label1, type: .length),
                          SliderStruct(slider: slider2, label: label2, type: .resistance),
                          SliderStruct(slider: slider3, label: label3, type: .damping),
                          SliderStruct(slider: slider4, label: label4, type: .frequency) ]
        sliderStructs.forEach {
            view.bringSubview(toFront: $0.slider)
            view.bringSubview(toFront: $0.label)
        }

    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isFirstLayout {
            isFirstLayout = false
            let size = view.bounds.size
            paneView.frame = CGRect(x: 0, y: size.height - closedHeight - closedBottomMargin, width: size.width, height: (size.height + stretchAllowance) - openTopMargin)
        }
        
        mainViewController?.view.frame = view.bounds
        updatePanelViewHeight()
        
        let dragHandleWidth = CGFloat(44)
        dragHandleView.frame = CGRect(x: (paneView.bounds.width / 2) - (dragHandleWidth / 2), y: 8, width: dragHandleWidth, height: 5)
        sliderStructs.forEach { $0.label.text = sliderLabelText(type: $0.type, stringValue: String($0.slider.value))  }
    }
    
    // MARK: - Handlers
    
    @IBAction func didMoveSlider1(_ sender: UISlider) {
        paneBehavior.attachmentBehavior.length = CGFloat(slider1.value)
        label1.text = sliderLabelText(type: .length, stringValue: String(slider1.value))
    }
    @IBAction func didMoveSlider2(_ sender: UISlider) {
        paneBehavior.itemBehavior.resistance = CGFloat(slider2.value)
        label2.text = sliderLabelText(type: .resistance, stringValue: String(slider2.value))

    }
    @IBAction func didMoveSlider3(_ sender: UISlider) {
        paneBehavior.attachmentBehavior.damping = CGFloat(slider3.value)
        label3.text = sliderLabelText(type: .damping, stringValue: String(slider3.value))
    }
    @IBAction func didMoveSlider4(_ sender: UISlider) {
        paneBehavior.attachmentBehavior.frequency = CGFloat(slider4.value)
        label4.text = sliderLabelText(type: .frequency, stringValue: String(slider4.value))
    }
    
    func sliderLabelText(type: PaneBehaviorType, stringValue: String) -> String {
        //was getting compiler errors with other methods so used this
        let firstString = String(describing: type)
        return "\(firstString): \(stringValue)"
    }
    
    @objc func didTapPaneView(_ sender: UITapGestureRecognizer) {
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
        panelViewController?.view.frame = CGRect(x: 0, y: closedHeight, width: paneView.bounds.width, height: panelHeight - closedHeight - stretchAllowance)
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
