//
//  AppDelegate.swift
//  Q42Stats-Demo
//
//  Created by Tom Lokhorst on 2020-02-12.
//  Copyright © 2020 Q42. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    window = UIWindow()
    window?.rootViewController = UIViewController()
    window?.rootViewController?.view.backgroundColor = .white
    window?.makeKeyAndVisible()

    Q42Stats(options: .all)
      .collect(window: window, completion: Q42Stats.submit(configuration: .demoApp, sha256: sha256))

    return true
  }
}

extension Q42Stats.Configuration {
  static let demoApp = Q42Stats.Configuration(
    firebaseProject: "foobar",
    firebaseCollection: "somecollection",
    minimumSubmitInterval: 60*60*24*7.5,
    sharedSecret: "random-string-used-for-creating-a-checksum"
  )
}

func sha256(string: String) -> String {
  let data = string.data(using: .utf8)!
  var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
  data.withUnsafeBytes {
    _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
  }
  return Data(hash).map { String(format: "%02hhx", $0) }.joined()
}
