//
//  InlineMessageViewController.swift
//  Example
//
//  Created by Ankmara on 01.06.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//
import Foundation
import UIKit
import WebKit
import ExponeaSDK

class InlineCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupInlineView(_ inlineView: UIView) {
        contentView.addSubview(inlineView)
        inlineView.translatesAutoresizingMaskIntoConstraints = false
        inlineView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        inlineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5).isActive = true
        inlineView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        inlineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5).isActive = true
    }
}

struct TableTest {
    var height: CGFloat
    let tag: Int
}

class InlineMessageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let data: [String] = [
        "Product 01",
        "Product 02",
        "Product 03",
        "Product 04"
    ]
    private let data2: [String] = [
        "Product 05",
        "Product 06",
        "Product 07",
        "Product 08"
    ]
    private let data3: [String] = [
        "Product 05",
        "Product 06",
        "Product 07",
        "Product 08",
        "Product 05",
        "Product 06",
        "Product 07",
        "Product 08",
        "Product 05",
        "Product 06",
        "Product 07",
        "Product 08"
    ]

    func numberOfSections(in tableView: UITableView) -> Int {
        4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return data.count
        case 1:
            return 1
        case 2:
            return data2.count
        case 3:
            return data3.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 1:
            let height = InlineMessageManager.manager.getUsedInline(placeholder: "example_list", indexPath: indexPath)?.height ?? 0
            return height
        default:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell") ?? UITableViewCell()
            cell.textLabel?.text = data[safeIndex: indexPath.row]
            return cell
        case 1:
            let cell = InlineCell(style: .default, reuseIdentifier: "InlineCell")
            let view = InlineMessageManager.manager.prepareInlineView(placeholderId: "example_list", indexPath: indexPath)
            cell.setupInlineView(view)
            return cell
        case 2:
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell") ?? UITableViewCell()
            cell.textLabel?.text = data2[safeIndex: indexPath.row]
            return cell
        case 3:
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell") ?? UITableViewCell()
            cell.textLabel?.text = data3[safeIndex: indexPath.row]
            return cell
        default:
            return UITableViewCell()
        }
    }

    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()

    lazy var placeholder = StaticInlineView(placeholder: "example_top")
    lazy var placeholderExample = StaticInlineView(placeholder: "ph_x_example_iOS")

    @objc func endEditing() {
        view.endEditing(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
    
        refreshControl.addTarget(self, action: #selector(refresh), for: .primaryActionTriggered)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.register(InlineCell.self, forCellReuseIdentifier: "InlineCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        
        InlineMessageManager.manager.refreshCallback = { [weak self] indexPath in
            onMain {
                self?.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
            }
        }
        
        view.backgroundColor = .black
        
        view.addSubview(placeholder)
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        placeholder.topAnchor.constraint(equalTo: view.topAnchor, constant: 80).isActive = true
        placeholder.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        placeholder.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        
        view.addSubview(placeholderExample)
        placeholderExample.translatesAutoresizingMaskIntoConstraints = false
        placeholderExample.topAnchor.constraint(equalTo: placeholder.bottomAnchor, constant: 5).isActive = true
        placeholderExample.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        placeholderExample.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: placeholderExample.bottomAnchor, constant: 5).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .refresh, target: self, action: #selector(reloadStaticView))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    @objc func refresh() {
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    @objc func reloadStaticView() {
        placeholder.reload()
        placeholderExample.reload()
    }
}
