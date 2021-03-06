//
//  AppController.swift
//  FBTT
//
//  Created by Christoph on 1/11/19.
//  Copyright © 2019 Verse Communications Inc. All rights reserved.
//

import Foundation
import UIKit

class AppController: UIViewController {

    static let shared = AppController()

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.background.default
    }

    /// Because controllers are nested and presented when the keyboard is also being presented,
    /// Autolayout may not have had a chance to do its thing.  So, it is forced here to ensure
    /// that the view hierarchy has been sized correctly before presenting.
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        viewControllerToPresent.view.setNeedsLayout()
        viewControllerToPresent.view.layoutIfNeeded()
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    // MARK: Root view controller

    func setRootViewController(_ controller: UIViewController, animated: Bool = true) {
        self.removeRootViewController()
        controller.willMove(toParent: self)
        self.addChild(controller)
        controller.view.frame = self.view.bounds
        self.view.addSubview(controller.view)
        controller.didMove(toParent: self)
    }

    private func removeRootViewController() {
        self.view.subviews.forEach { $0.removeFromSuperview() }
        self.children.forEach { $0.removeFromParent() }
    }

    // MARK: Main tab view controller

    func showMainViewController(with controller: UIViewController? = nil, animated: Bool = true) {
        let controller = MainViewController()
        self.setRootViewController(controller, animated: animated)
    }

    var mainViewController: MainViewController? {
        return self.children.first as? MainViewController
    }

    // MARK: Onboarding view controller

    func showOnboardingViewController(_ status: Onboarding.Status = .notStarted,
                                      _ simulate: Bool = false,
                                      animated: Bool = true)
    {
        let controller = OnboardingViewController(status: status, simulate: simulate)
        self.setRootViewController(controller, animated: animated)
    }

    // MARK: Menu view controller

    func showMenuViewController(animated: Bool = true) {
        let controller = MenuViewController()
        controller.modalPresentationStyle = .overCurrentContext
        self.mainViewController?.present(controller, animated: false) {
            controller.open()
        }
    }

    // MARK: Settings view controller

    func showSettingsViewController() {
        let nc = UINavigationController(rootViewController: SettingsViewController())
        self.mainViewController?.present(nc, animated: true)
    }
}
