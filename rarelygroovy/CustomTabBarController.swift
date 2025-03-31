//
//  CustomTabBarController.swift
//  rarelygroovy
//
//  Created by abs on 3/30/25.
//

import Foundation
import UIKit

class CustomTabBarController: UITabBarController, UITabBarControllerDelegate {
    private var lastSelectedIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        lastSelectedIndex = selectedIndex
    }

    // UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if selectedIndex == lastSelectedIndex {
            // Post notification when re-tapping the same tab
            NotificationCenter.default.post(name: Notification.Name("TabReselected"), object: nil)
        }
        lastSelectedIndex = selectedIndex
    }
}
