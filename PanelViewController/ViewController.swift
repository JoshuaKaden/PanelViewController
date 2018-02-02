//
//  ViewController.swift
//  PanelViewController
//
//  Created by Kaden, Joshua on 1/24/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    
    private let startButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startButton.addTarget(self, action: #selector(didTapStart(_:)), for: .touchUpInside)
        startButton.setTitle(NSLocalizedString("Start", comment: ""), for: .normal)
        startButton.setTitleColor(.blue, for: .normal)
        view.addSubview(startButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        startButton.frame = view.bounds
    }
    
    @objc func didTapStart(_ sender: UIButton) {
        let vc = buildPanelViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func buildPanelViewController() -> PanelViewController {
        let mapVC = MapViewController()
        let listVC = ListViewController()
        
        let vc = PanelViewController(mainViewController: mapVC, panelViewController: listVC)
//        vc.closedHeight = 66
//        vc.openTopMargin = view.bounds.height / 2
//        vc.midTopMargin = view.bounds.height / 3
//        vc.showsMidState = false
        return vc
    }
}
