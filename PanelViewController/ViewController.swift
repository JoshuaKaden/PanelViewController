//
//  ViewController.swift
//  PanelViewController
//
//  Created by Kaden, Joshua on 1/24/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    
    private let closedHeightTextField = UITextField()
    private let closedBottomMarginTextField = UITextField()
    private let containerizeSwitch = UISwitch()
    private let midTopMarginTextField = UITextField()
    private let openTopMarginTextField = UITextField()
    private let showsMidStateSwitch = UISwitch()
    private let stackView = UIStackView()
    private let startingStateControl = UISegmentedControl(items: ["Closed", "Open", "Mid"])
    
    @IBInspectable var panelVCID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        add(textField: closedHeightTextField, text: String(describing: PanelViewController.defaultClosedHeight), title: NSLocalizedString("Closed height:", comment: ""))
        add(textField: openTopMarginTextField, text: String(describing: PanelViewController.defaultOpenTopMargin), title: NSLocalizedString("Open top margin:", comment: ""))
        add(textField: closedBottomMarginTextField, text: String(describing: PanelViewController.defaultClosedBottomMargin), title: NSLocalizedString("Closed Bottom Margin:", comment: ""))
        addMidStateControls()
        add(textField: midTopMarginTextField, title: NSLocalizedString("Mid top margin:", comment: ""), placeholder: NSLocalizedString("1/2 superview height", comment: ""))
        addContainerizeControls()
        addStartButton()
        
        stackView.axis = .vertical
        stackView.distribution = .equalCentering
        stackView.spacing = 8
        view.addSubview(stackView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let rowCount = stackView.arrangedSubviews.count
        stackView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: view.bounds.width - 32, height: 35 * CGFloat(rowCount)))
        stackView.center = CGPoint(x: view.center.x, y: view.center.y)
    }
    
    @objc func didTapStart(_ sender: UIButton) {
        view.endEditing(true)
        
        let panelVC = buildPanelViewController()
        
        let vc: UIViewController
        if containerizeSwitch.isOn {
            vc = ContainerViewController(panelViewController: panelVC)
        } else {
            vc = panelVC
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func add(textField: UITextField, text: String? = nil, title: String, placeholder: String? = nil) {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.frame = CGRect(x: 0, y: 0, width: 140, height: 44)
        label.text = title
        
        textField.delegate = self
        textField.leftView = label
        textField.leftViewMode = .always
        textField.placeholder = placeholder
        textField.returnKeyType = .done
        textField.text = text
        stackView.addArrangedSubview(textField)
    }
    
    private func addContainerizeControls() {
        let containerizeLabel = UILabel()
        containerizeLabel.text = NSLocalizedString("Containerize:", comment: "")
        containerizeLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        stackView.addArrangedSubview(containerizeLabel)
        
        containerizeSwitch.isOn = false
        stackView.addArrangedSubview(containerizeSwitch)
    }
    
    private func addMidStateControls() {
        let showsMidStateLabel = UILabel()
        showsMidStateLabel.text = NSLocalizedString("Shows mid state:", comment: "")
        showsMidStateLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        stackView.addArrangedSubview(showsMidStateLabel)
        
        showsMidStateSwitch.isOn = false
        stackView.addArrangedSubview(showsMidStateSwitch)
        
        let startingStateLabel = UILabel()
        startingStateLabel.text = NSLocalizedString("Starting state:", comment: "")
        startingStateLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        stackView.addArrangedSubview(startingStateLabel)
        
        startingStateControl.selectedSegmentIndex = 0
        stackView.addArrangedSubview(startingStateControl)
    }
    
    private func addStartButton() {
        let startButton = UIButton()
        startButton.addTarget(self, action: #selector(didTapStart(_:)), for: .touchUpInside)
        startButton.setTitle(NSLocalizedString("Start", comment: ""), for: .normal)
        startButton.setTitleColor(.blue, for: .normal)
        stackView.addArrangedSubview(startButton)
    }
    
    private func buildPanelViewController() -> PanelViewController {
        let vc: PanelViewController
        
        if let panelID = panelVCID,
            let storyboard = navigationController?.storyboard,
            let panelVC = storyboard.instantiateViewController(withIdentifier: panelID) as? PanelViewController
        {
            vc = panelVC
        } else {
            vc = PanelViewController(backViewController: MapViewController(), slidingViewController: ListViewController())
        }
        
        configure(panelViewController: vc)
        return vc
    }
    
    private func configure(panelViewController vc: PanelViewController) {
        if let closedHeight = Double(closedHeightTextField.text ?? "") {
            vc.closedHeight = CGFloat(closedHeight)
        }
        
        if let openTopMargin = Double(openTopMarginTextField.text ?? "") {
            vc.openTopMargin = CGFloat(openTopMargin)
        }
        
        
        if let closedBottomMargin = Double(closedBottomMarginTextField.text ?? "") {
            vc.closedBottomMargin = CGFloat(closedBottomMargin)
        }
        
        vc.showsMidState = showsMidStateSwitch.isOn
        
        if let midTopMargin = Double(midTopMarginTextField.text ?? "") {
            vc.midTopMargin = CGFloat(midTopMargin)
        }
        
        switch startingStateControl.selectedSegmentIndex {
        case 0:
            vc.startingState = .closed
        case 1:
            vc.startingState = .open
        case 2:
            vc.startingState = .mid
        default:
            break
        }
        
        let headerView = ButtonContainerView()
        headerView.frame = CGRect(x: 0, y: 0, width: 0, height: 60)
        vc.floatingHeaderView = headerView
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
