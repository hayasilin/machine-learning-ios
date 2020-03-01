//
//  MainViewController.swift
//  MLDemo
//
//  Created by KuanWei on 2020/3/1.
//  Copyright © 2020 Cracktheterm. All rights reserved.
//

import UIKit

class MainViewController: UITableViewController {

    enum SettingsFunctions {
        case imageClassication
        case captureClassification
        case imageSimilarity
        case objectDetection
        case styleTransfer
        case activityClassification
        case textClassification

        var title: String? {
            switch self {
            case .imageClassication:
                return "imageClassication"
            case .captureClassification:
                return "captureClassification"
            case .imageSimilarity:
                return "imageSimilarity"
            case .objectDetection:
                return "objectDetection"
            case .styleTransfer:
                return "styleTransfer"
            case .activityClassification:
                return "activityClassification"
            case .textClassification:
                return "textClassification"
            }
        }
    }

    lazy var dataSource: [SettingsFunctions] = [
        .imageClassication,
        .captureClassification,
        .imageSimilarity,
        .objectDetection,
        .styleTransfer,
        .activityClassification,
        .textClassification
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)

        cell.textLabel?.text = dataSource[indexPath.row].title

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        var viewController: UIViewController = UIViewController()

        switch dataSource[indexPath.row] {
        case .imageClassication:
            viewController = ImageClassificationViewController()

        case .captureClassification:
            viewController = CaptureClassificationViewController()

        case .textClassification:
            viewController = TextClassificationViewController()

        default:
            break
        }

        navigationController?.pushViewController(viewController, animated: true)
    }
}
