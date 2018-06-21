//
//  ListViewController.swift
//  PanelViewController
//
//  Created by Kaden, Joshua on 1/24/18.
//  Copyright © 2018 NYC DoITT. All rights reserved.
//

import UIKit

protocol ListViewControllerDataSource: class {
    var records: [String] { get }
}

final class ListViewController: UIViewController {
    weak var dataSource: ListViewControllerDataSource?
    private let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        view.addSubview(tableView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
}

extension ListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let dequeued = tableView.dequeueReusableCell(withIdentifier: "cell") {
            cell = dequeued
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
            cell.accessoryType = .disclosureIndicator
        }
        
        if let records = dataSource?.records {
            cell.textLabel?.text = records[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.records.count ?? 0
    }
}

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
//        let vc = DetailViewController()
//        vc.greekLetter = records[indexPath.row]
//        navigationController?.pushViewController(vc, animated: true)
    }
}
