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
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let closedHeightLabel = UILabel()
        closedHeightLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        closedHeightLabel.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
        closedHeightLabel.text = NSLocalizedString("Closed height:", comment: "")
        
        closedHeightTextField.delegate = self
        closedHeightTextField.leftView = closedHeightLabel
        closedHeightTextField.leftViewMode = .always
        closedHeightTextField.returnKeyType = .done
        closedHeightTextField.text = String(describing: PanelViewController.defaultClosedHeight)
        stackView.addArrangedSubview(closedHeightTextField)

        let openTopMarginLabel = UILabel()
        openTopMarginLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        openTopMarginLabel.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
        openTopMarginLabel.text = NSLocalizedString("Open top margin:", comment: "")
        
        openTopMarginTextField.delegate = self
        openTopMarginTextField.leftView = openTopMarginLabel
        openTopMarginTextField.leftViewMode = .always
        openTopMarginTextField.returnKeyType = .done
        openTopMarginTextField.text = String(describing: PanelViewController.defaultOpenTopMargin)
        stackView.addArrangedSubview(openTopMarginTextField)
        
        let showsMidStateLabel = UILabel()
        showsMidStateLabel.text = NSLocalizedString("Shows mid state:", comment: "")
        showsMidStateLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        stackView.addArrangedSubview(showsMidStateLabel)
        
        showsMidStateSwitch.isOn = false
        stackView.addArrangedSubview(showsMidStateSwitch)
        
        let midTopMarginLabel = UILabel()
        midTopMarginLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        midTopMarginLabel.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
        midTopMarginLabel.text = NSLocalizedString("Mid top margin:", comment: "")
        
        midTopMarginTextField.delegate = self
        midTopMarginTextField.leftView = midTopMarginLabel
        midTopMarginTextField.leftViewMode = .always
        midTopMarginTextField.placeholder = NSLocalizedString("1/2 superview height", comment: "")
        midTopMarginTextField.returnKeyType = .done
        stackView.addArrangedSubview(midTopMarginTextField)
        
        let startButton = UIButton()
        startButton.addTarget(self, action: #selector(didTapStart(_:)), for: .touchUpInside)
        startButton.setTitle(NSLocalizedString("Start", comment: ""), for: .normal)
        startButton.setTitleColor(.blue, for: .normal)
        stackView.addArrangedSubview(startButton)
        
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
        let vc = buildPanelViewController()
        navigationController?.pushViewController(vc, animated: true)
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
