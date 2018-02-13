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
    private let midTopMarginTextField = UITextField()
    private let openTopMarginTextField = UITextField()
    private let showsMidStateSwitch = UISwitch()
    private let containerizeSwitch = UISwitch()
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        add(textField: closedHeightTextField, text: String(describing: PanelViewController.defaultClosedHeight), title: NSLocalizedString("Closed height:", comment: ""))
        add(textField: openTopMarginTextField, text: String(describing: PanelViewController.defaultOpenTopMargin), title: NSLocalizedString("Open top margin:", comment: ""))
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
        stackView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: view.bounds.width - 32, height: 44 * 6))
        stackView.center = CGPoint(x: view.center.x, y: view.center.y - 80)
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
        label.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
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
    }
    
    private func addStartButton() {
        let startButton = UIButton()
        startButton.addTarget(self, action: #selector(didTapStart(_:)), for: .touchUpInside)
        startButton.setTitle(NSLocalizedString("Start", comment: ""), for: .normal)
        startButton.setTitleColor(.blue, for: .normal)
        stackView.addArrangedSubview(startButton)
    }
    
    private func buildPanelViewController() -> PanelViewController {
        let mapVC = MapViewController()
        let listVC = ListViewController()
        
        let vc = PanelViewController(mainViewController: mapVC, panelViewController: listVC)
        
        if let closedHeight = Double(closedHeightTextField.text ?? "") {
            vc.closedHeight = CGFloat(closedHeight)
        }
        
        if let openTopMargin = Double(openTopMarginTextField.text ?? "") {
            vc.openTopMargin = CGFloat(openTopMargin)
        }
        
        vc.showsMidState = showsMidStateSwitch.isOn
        
        if let midTopMargin = Double(midTopMarginTextField.text ?? "") {
            vc.midTopMargin = CGFloat(midTopMargin)
        }
        return vc
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
