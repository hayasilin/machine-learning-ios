//
//  MainTabBarController.swift
//  MLDemo
//
//  Created by KuanWei on 2020/3/14.
//  Copyright © 2020 Cracktheterm. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let coreMLBasicVC = CoreMLBasicViewController()
        coreMLBasicVC.tabBarItem = UITabBarItem(tabBarSystemItem: .featured, tag: 0)

        let coreMLAdvancedVC = CoreMLAdvancedViewController()
        coreMLAdvancedVC.tabBarItem = UITabBarItem(tabBarSystemItem: .topRated, tag: 1)

        viewControllers = [coreMLBasicVC, coreMLAdvancedVC]
    }
}
