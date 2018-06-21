//
//  ContainerViewController.swift
//  PanelViewController
//
//  Created by Kaden, Joshua on 2/12/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

final class ContainerViewController: UIViewController {
    private let animateDownButton = UIButton()
    private let animateUpButton = UIButton()
    private let midTopMarginTextField = UITextField()
    private let panelViewController: PanelViewController
    private let stackView = UIStackView()

    init(panelViewController: PanelViewController) {
        self.panelViewController = panelViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        panelViewController = PanelViewController(coder: aDecoder)!
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .darkGray
        
        adoptChildViewController(panelViewController)
        panelViewController.view?.clipsToBounds = true
        
        animateUpButton.addTarget(self, action: #selector(didTapAnimateUp(_:)), for: .touchUpInside)
        animateUpButton.setTitle(NSLocalizedString("Animate Up", comment: ""), for: .normal)
        animateUpButton.setTitleColor(.white, for: .normal)
        view.addSubview(animateUpButton)

        animateDownButton.addTarget(self, action: #selector(didTapAnimateDown(_:)), for: .touchUpInside)
        animateDownButton.setTitle(NSLocalizedString("Animate Down", comment: ""), for: .normal)
        animateDownButton.setTitleColor(.white, for: .normal)
        view.addSubview(animateDownButton)
        
        view.addSubview(stackView)
        
        add(textField: midTopMarginTextField, text: "nil", title: NSLocalizedString("Mid top margin:", comment: ""), placeholder: NSLocalizedString("1/2 superview height", comment: ""))
    }
    
    deinit {
        panelViewController.leaveParentViewController()
    }
    
    @objc func didTapAnimateDown(_ sender: UIButton) {
        let newState: PanelState
        switch panelViewController.panelState {
        case .closed:
            return
        case .mid:
            newState = .closed
        case .open:
            if panelViewController.showsMidState {
                newState = .mid
            } else {
                newState = .closed
            }
        }
        panelViewController.changeState(to: newState)
    }
    
    @objc func didTapAnimateUp(_ sender: UIButton) {
        let newState: PanelState
        switch panelViewController.panelState {
        case .closed:
            if panelViewController.showsMidState {
                newState = .mid
            } else {
                newState = .open
            }
        case .mid:
            newState = .open
        case .open:
            return
        }
        panelViewController.changeState(to: newState)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let panelView = panelViewController.view else {
            return
        }
        panelView.frame = view.frame.insetBy(dx: 24, dy: 120)
        panelView.center = view.center
        
        midTopMarginTextField.text = String(describing: panelViewController.midTopMargin ?? panelView.height / 2)
        
        animateUpButton.frame = CGRect(x: 0, y: (panelView.frame.maxY) + 16, width: view.frame.width / 2, height: 44)
        animateDownButton.frame = CGRect(x: animateUpButton.frame.maxX, y: animateUpButton.frame.minY, width: view.frame.width / 2, height: 44)
        
        stackView.y = panelView.y - 35
        stackView.width = view.width - 16
        stackView.height = 35
        stackView.centerHorizontallyInSuperview()
    }
    
    private func add(textField: UITextField, text: String? = nil, title: String, placeholder: String? = nil) {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.frame = CGRect(x: 0, y: 0, width: 150, height: 35)
        label.text = title
        label.textColor = .white
        
        textField.delegate = self
        textField.leftView = label
        textField.leftViewMode = .always
        textField.placeholder = placeholder
        textField.returnKeyType = .done
        textField.text = text
        textField.textColor = .white
        stackView.addArrangedSubview(textField)
    }
}

// MARK: - ListViewControllerDataSource

extension ContainerViewController: ListViewControllerDataSource {
    var allRecords: [String] {
        return ["Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota", "Kappa", "Lambda", "Mu", "Nu", "Xi", "Omicron", "Pi", "Rho", "Sigma", "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega"]
    }
    
    var records: [String] { return allRecords }
}

extension ContainerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let newString = textField.text, let newFloat = NumberFormatter().number(from: newString)?.floatValue {
            let newMargin = CGFloat(newFloat)
            panelViewController.midTopMargin = newMargin
        } else {
            panelViewController.midTopMargin = nil
        }
        
        view.setNeedsLayout()
        
        textField.resignFirstResponder()
        return false
    }
}
