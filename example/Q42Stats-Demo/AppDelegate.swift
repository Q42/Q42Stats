//
//  AppDelegate.swift
//  Q42Stats-Demo
//
//  Created by Tom Lokhorst on 2020-02-12.
//  Copyright © 2020 Q42. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow()
        window?.rootViewController = UIViewController()
        window?.rootViewController?.view.backgroundColor = .white
        window?.makeKeyAndVisible()

        Q42Stats(options: .all)
            .collect(window: window, completion: Q42Stats.submit(configuration: .demoApp))

        return true
    }
}

extension Q42Stats.Configuration {
    static let demoApp = Q42Stats.Configuration(
        apiKey: "secret",
        firestoreCollection: "somecollection",
        minimumSubmitInterval: 60 * 60 * 24 * 7.5
    )
}
