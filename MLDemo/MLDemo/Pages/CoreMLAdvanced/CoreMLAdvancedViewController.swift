//
//  CoreMLAdvancedViewController.swift
//  MLDemo
//
//  Created by KuanWei on 2020/3/14.
//  Copyright © 2020 Cracktheterm. All rights reserved.
//

import UIKit

class CoreMLAdvancedViewController: UITableViewController {

enum SettingsFunctions {
        case faceDetection
        case barcodeDetection
        case textDetection
        case horizonDetection
        case objectTracking
        case naturalLanguage

        var title: String? {
            switch self {
            case .faceDetection:
                return "faceDetection"
            case .barcodeDetection:
                return "barcodeDetection"
            case .textDetection:
                return "textDetection"
            case .horizonDetection:
                return "horizonDetection"
            case .objectTracking:
                return "objectTracking"
            case .naturalLanguage:
                return "naturalLanguage"
            }
        }
    }

    lazy var dataSource: [SettingsFunctions] = [
        .faceDetection,
        .barcodeDetection,
        .textDetection,
        .horizonDetection,
        .objectTracking,
        .naturalLanguage,
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
        case .faceDetection:
            viewController = FaceDetectionViewController()

        case .barcodeDetection:
            viewController = CaptureClassificationViewController()

        case .textDetection:
            viewController = ImageSimilarityViewController()

        case .horizonDetection:
            viewController = ObjectDetectionViewController()

        case .objectTracking:
            viewController = StyleTransferViewController()

        case .naturalLanguage:
            viewController = TextClassificationViewController()
        }

        navigationController?.pushViewController(viewController, animated: true)
    }
}
