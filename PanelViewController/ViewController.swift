//
//  ViewController.swift
//  PanelViewController
//
//  Created by Kaden, Joshua on 1/24/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    
    private let canTapToCloseSwitch = UISwitch()
    private let canTapToOpenSwitch = UISwitch()
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
        add(textField: closedBottomMarginTextField, text: String(describing: PanelViewController.defaultClosedBottomMargin), title: NSLocalizedString("Closed bottom margin:", comment: ""))
        addMidStateControls()
        addTapControls()
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
        stackView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: view.bounds.width - 16, height: 35 * CGFloat(rowCount)))
        stackView.center = CGPoint(x: view.center.x, y: view.center.y)
    }
    
    @objc func didTapStart(_ sender: UIButton) {
        view.endEditing(true)
        
        let panelVC = buildPanelViewController()
        
        guard let listVC = panelVC.slidingViewController as? ListViewController else {
            return
        }
        
        let vc: UIViewController
        if containerizeSwitch.isOn {
            let containerVC = ContainerViewController(panelViewController: panelVC)
            listVC.dataSource = containerVC
            vc = containerVC
        } else {
            vc = panelVC
            listVC.dataSource = self
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func add(textField: UITextField, text: String? = nil, title: String, placeholder: String? = nil) {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.frame = CGRect(x: 0, y: 0, width: 150, height: 35)
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
    
    private func addTapControls() {
        let canTapToCloseLabel = UILabel()
        canTapToCloseLabel.text = NSLocalizedString("Can tap to close:", comment: "")
        canTapToCloseLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        stackView.addArrangedSubview(canTapToCloseLabel)
        
        canTapToCloseSwitch.isOn = true
        stackView.addArrangedSubview(canTapToCloseSwitch)

        let canTapToOpenLabel = UILabel()
        canTapToOpenLabel.text = NSLocalizedString("Can tap to open:", comment: "")
        canTapToOpenLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        stackView.addArrangedSubview(canTapToOpenLabel)
        
        canTapToOpenSwitch.isOn = true
        stackView.addArrangedSubview(canTapToOpenSwitch)
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
        
        vc.canTapToClose = canTapToCloseSwitch.isOn
        vc.canTapToOpen = canTapToOpenSwitch.isOn
        
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
        headerView.buttonAction = {
            let alertVC = UIAlertController(title: "Button", message: "The button was tapped", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default) { (action) in
                alertVC.dismiss(animated: true, completion: nil)
            }
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
        }
        // PanelViewController will adjust the origin and width as it sees fit. It will preserve whatever height you set.
        headerView.frame = CGRect(x: 0, y: 0, width: 0, height: 60)
        vc.floatingHeaderView = headerView
    }
}

// MARK: - ListViewControllerDataSource

extension ViewController: ListViewControllerDataSource {
    var allRecords: [String] {
        return ["Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota", "Kappa", "Lambda", "Mu", "Nu", "Xi", "Omicron", "Pi", "Rho", "Sigma", "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega"]
    }

    var records: [String] { return allRecords }
}

// MARK: - UITextFieldDelegate

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
