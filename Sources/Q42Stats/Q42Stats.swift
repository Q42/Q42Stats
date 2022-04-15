//
//  Q42Stats.swift
//
//  Created by Tom Lokhorst on 2020-02-10.
//  Copyright © 2020 Q42. All rights reserved.
//

import UIKit
import StoreKit
import PassKit
import WatchConnectivity

/// Collect stats for Q42 internal usage, shared accross multiple iOS projects.
///
public class Q42Stats: NSObject {
  public struct Configuration {
    let firebaseProject: String
    let firebaseCollection: String
    let minimumSubmitInterval: TimeInterval
    let sharedSecret: String

    var firebaseURL: URL? { URL(string: "https://firestore.googleapis.com/v1/projects/" + firebaseProject + "/databases/(default)/documents/" + firebaseCollection + "?mask.fieldPaths=_") }

    public init(firebaseProject: String, firebaseCollection: String, minimumSubmitInterval: TimeInterval, sharedSecret: String) {
      self.firebaseProject = firebaseProject
      self.firebaseCollection = firebaseCollection
      self.minimumSubmitInterval = minimumSubmitInterval
      self.sharedSecret = sharedSecret
    }
  }

  public struct StatsOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let accessibility = StatsOptions(rawValue: 1 << 0)
    public static let applePay      = StatsOptions(rawValue: 1 << 1)
    public static let preferences   = StatsOptions(rawValue: 1 << 2)
    public static let screen        = StatsOptions(rawValue: 1 << 3)
    public static let system        = StatsOptions(rawValue: 1 << 4)
    public static let watch         = StatsOptions(rawValue: 1 << 5)

    public static let all: StatsOptions = [
      .accessibility, .applePay, .preferences,
      .screen, .system, .watch
    ]
  }

  private static var shared: Q42Stats?
  private static let statsVersion = "iOS 2020-07-01"

  private static let instanceIdKey = "nl.q42.stats.instanceID"
  private static let timestampOfPreviousSubmitKey = "nl.q42.stats.timestampOfPreviousSubmitKey"

  public let options: StatsOptions
  private(set) var collected: [String: String] = [:]

  public init(options: StatsOptions) {
    self.options = options

    super.init()

    Q42Stats.shared = self
  }

  private static func seedPreviousSubmitMomentIfNeeded(minimumSubmitInterval: TimeInterval) {
    guard UserDefaults.standard.double(forKey: Q42Stats.timestampOfPreviousSubmitKey) == 0 else { return }

    let randomizedFactor = Double.random(in: 0.2...1.2)
    let simulatedTimeIntervalSinceNowOfPreviousSubmit: TimeInterval = randomizedFactor * minimumSubmitInterval
    let simulatedTimestampOfPreviousSubmit = Date().timeIntervalSince1970 - simulatedTimeIntervalSinceNowOfPreviousSubmit
    UserDefaults.standard.set(simulatedTimestampOfPreviousSubmit, forKey: Q42Stats.timestampOfPreviousSubmitKey)
  }

  public static func submit(configuration: Configuration, sha256 hashFunc: @escaping (String) -> String) -> ([String: String]) -> Void {
    return { stats in
      guard let firebaseURL = configuration.firebaseURL else { assertionFailure("Q42Stats: Invalid endpoint"); return }

      seedPreviousSubmitMomentIfNeeded(minimumSubmitInterval: configuration.minimumSubmitInterval)

      // Check and update timestamp to rate limit submits
      let timestamp = Date().timeIntervalSince1970
      guard timestamp - UserDefaults.standard.double(forKey: timestampOfPreviousSubmitKey) > configuration.minimumSubmitInterval else {
        print("Q42Stats: Already submitted stats in the last \(configuration.minimumSubmitInterval) seconds, not collecting stats!")
        return
      }
      UserDefaults.standard.set(timestamp, forKey: timestampOfPreviousSubmitKey)

      // Create Firestore compatible payload
      let payload: Data
      do {
        payload = try JSONEncoder().encode(StatsPayload(stats: stats, hashFunc: hashFunc, secret: configuration.sharedSecret))
      } catch {
        assertionFailure("🙂 Q42Stats: Could not create payload");
        return
      }

      // Build request and submit
      var request = URLRequest(url: firebaseURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = payload

      let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode < 300, error == nil else {
          print("🙂 Q42Stats: Failed to reach backend to submit stats. Status code: \((response as? HTTPURLResponse)?.statusCode ?? -1) Error: \(error?.localizedDescription ?? "None")")
          return
        }

        if let data = data, let dataString = String(data: data, encoding: .utf8) {
          print("🙂 Q42Stats: Yay! Status code: \((response as? HTTPURLResponse)?.statusCode ?? -1) Data: \(dataString))")
        } else {
          print("🙂 Q42Stats: Sad! Status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }
      }
      task.resume()
    }
  }

  private func _log(key: String, value: String) {
    collected[key] = value
  }

  /// Start collection of statistics.
  ///
  /// - Note: Must be called from the main queue
  public func collect(window: UIWindow?, completion: @escaping ([String: String]) -> Void) {
    collected = [:]

    _log(key: "Stats version", value: Q42Stats.statsVersion)
    _log(key: "Stats instance ID", value: "\(getInstanceId())")
    _log(key: "Stats timestamp", value: "\(Date().timeIntervalSince1970)")

    if let bundleIdentifier = Bundle.main.bundleIdentifier {
      _log(key: "App bundle identifier", value: bundleIdentifier)
    }

    if options.contains(.accessibility) {
      let any = UIAccessibility.usesAnyAccessibilitySetting()
      _log(key: "Accessibility uses any accessibility setting", value: any.description)

      if #available(iOS 10.0, *) {
        // As the docs describe in the discussion `isAssistiveTouchRunning` will only be the correct value if `isGuidedAccessEnabled` is `true`
        // See: https://developer.apple.com/documentation/uikit/uiaccessibility/1648479-isassistivetouchrunning
        _log(key: "Accessibility isAssistiveTouchRunning with isGuidedAccessEnabled", value: UIAccessibility.isGuidedAccessEnabled ? UIAccessibility.isAssistiveTouchRunning.description : "Unknown")
      }
      _log(key: "Accessibility isBoldTextEnabled", value: UIAccessibility.isBoldTextEnabled.description)
      _log(key: "Accessibility isClosedCaptioningEnabled", value: UIAccessibility.isClosedCaptioningEnabled.description)
      _log(key: "Accessibility isDarkerSystemColorsEnabled", value: UIAccessibility.isDarkerSystemColorsEnabled.description)
      _log(key: "Accessibility isGrayscaleEnabled", value: UIAccessibility.isGrayscaleEnabled.description)
      _log(key: "Accessibility isGuidedAccessEnabled", value: UIAccessibility.isGuidedAccessEnabled.description)
      _log(key: "Accessibility isInvertColorsEnabled", value: UIAccessibility.isInvertColorsEnabled.description)
      _log(key: "Accessibility isMonoAudioEnabled", value: UIAccessibility.isMonoAudioEnabled.description)
      _log(key: "Accessibility isReduceTransparencyEnabled", value: UIAccessibility.isReduceTransparencyEnabled.description)
      _log(key: "Accessibility isShakeToUndoEnabled", value: UIAccessibility.isShakeToUndoEnabled.description)
      _log(key: "Accessibility isSpeakScreenEnabled", value: UIAccessibility.isSpeakScreenEnabled.description)
      _log(key: "Accessibility isSpeakSelectionEnabled", value: UIAccessibility.isSpeakSelectionEnabled.description)
      _log(key: "Accessibility isSwitchControlRunning", value: UIAccessibility.isSwitchControlRunning.description)
      _log(key: "Accessibility isVoiceOverRunning", value: UIAccessibility.isVoiceOverRunning.description)
    }

    if options.contains(.applePay) {
      if #available(iOS 10.0, *) {
        let canMakePayments = PKPaymentAuthorizationViewController
          .canMakePayments(usingNetworks: PKPaymentRequest.availableNetworks())
        _log(key: "Apple Pay available", value: canMakePayments.description)
      } else {
        _log(key: "Apple Pay available", value: false.description)
      }

      if #available(iOS 12.0, *) {
        let canMakeMaestroPayments = PKPaymentAuthorizationViewController
          .canMakePayments(usingNetworks: [PKPaymentNetwork.maestro])
        _log(key: "Apple Pay w/Maestro available", value: canMakeMaestroPayments.description)
      } else {
        _log(key: "Apple Pay w/Maestro available", value: false.description)
      }
    }

    if options.contains(.preferences) {
      if #available(iOS 13.0, *) {
        let style = UITraitCollection.current.userInterfaceStyle
        _log(key: "Preference UI style", value: style.description)
        _log(key: "Preference daytime", value: dayNight())

        let category = UITraitCollection.current.preferredContentSizeCategory
        _log(key: "Preference preferred content size", value: category.description)
      }
    }

    if options.contains(.screen) {
      let idiom = UIDevice.current.userInterfaceIdiom
      _log(key: "Screen device idiom", value: idiom.description)

      if #available(iOS 13.0, *) {
        let gamut = UITraitCollection.current.displayGamut
        _log(key: "Screen display gamut", value: gamut.description)
      }

      let scale = ceil(UIScreen.main.scale)
      _log(key: "Screen scale", value: "@\(Int(scale))x")

      let isZoomed: Bool
      if UIScreen.main.nativeBounds.width == 1080 { // iPhone 6 Plus
        isZoomed = UIScreen.main.bounds.width == 375
      } else {
        isZoomed = UIScreen.main.nativeScale > UIScreen.main.scale
      }
      _log(key: "Screen zoomed", value: isZoomed.description)

      if #available(iOS 13.0, *) {
        let display = UIScreen.main.bounds.size
          .rotate(window?.windowScene?.interfaceOrientation)
        _log(key: "Screen width", value: Int(display.width).description)

        let orientation = window?.windowScene?.interfaceOrientation
        _log(key: "Screen orientation", value: orientation?.portaitLandscape ?? "unknown")
      }

      if let window = window {
        let full = window.bounds.width == UIScreen.main.bounds.width
          || window.bounds.width == UIScreen.main.bounds.height
        _log(key: "Screen in split-screen", value: (!full).description)

        let windowWidth = Int(window.bounds.width).description
        _log(key: "Screen window width", value: windowWidth)
      }
    }

    if options.contains(.system) {
      _log(key: "System model id", value: UIDevice.current.modelIdentifier)
      _log(key: "System model name", value: UIDevice.current.modelName)

      let dutchRegion = Locale.preferredLanguages.contains { $0.hasSuffix("-NL") }
        || Locale.current.regionCode == "NL"
      _log(key: "System Dutch region", value: dutchRegion.description)

      let preferredLanguage = Locale.preferredLanguages.first ?? ""
      _log(key: "System Preferred language", value: preferredLanguage)

      _log(key: "System OS major version", value: ProcessInfo().operatingSystemVersion.majorVersion.description)
    }

    if options.contains(.watch) {
      let watchSupported = WCSession.isSupported()
      _log(key: "Watch supported", value: watchSupported.description)

      if watchSupported {
        WCSession.default.delegate = self
        WCSession.default.activate()
      } else {
        _log(key: "Watch paired", value: false.description)
      }
    }

    // Wait 5 seconds (for Apple Watch to pair)
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
      completion(self.collected)
    }
  }

  private func getInstanceId() -> String {
    if let instanceId = UserDefaults.standard.string(forKey: Q42Stats.instanceIdKey) {
      return instanceId
    }

    let instanceId = UUID().uuidString
    UserDefaults.standard.set(instanceId, forKey: Q42Stats.instanceIdKey)
    return instanceId
  }
}

extension Q42Stats: WCSessionDelegate {
  @available(iOS 9.3, *)
  public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    DispatchQueue.main.async {
      self._log(key: "Watch paired", value: session.isPaired.description)
    }
  }

  public func sessionDidBecomeInactive(_ session: WCSession) {}
  public func sessionDidDeactivate(_ session: WCSession) {}
}

@available(iOS 9.3, *)
private extension WCSessionActivationState {
  var description: String {
    switch self {
    case .notActivated: return "notActivated"
    case .inactive: return "inactive"
    case .activated: return "activated"
    @unknown default: return "unknown"
    }
  }
}

private extension UIUserInterfaceIdiom {
  var description: String {
    switch self {
    case .phone: return "phone"
    case .pad: return "pad"
    case .carPlay: return "carPlay"
    case .tv: return "tv"
    case .unspecified: return "unspecified"
    case .mac: return "mac"
    @unknown default: return "unknown"
    }
  }
}

private extension UIInterfaceOrientation {
  var portaitLandscape: String? {
    switch self {
    case .landscapeLeft: return "landscape"
    case .landscapeRight: return "landscape"
    case .portrait: return "portrait"
    case .portraitUpsideDown: return "portrait"
    default: return nil
    }
  }
}

@available(iOS 12.0, *)
private extension UIUserInterfaceStyle {
  var description: String {
    switch self {
    case .dark: return "dark"
    case .light: return "light"
    case .unspecified: return "unspecified"
    @unknown default: return "unknown"
    }
  }
}

@available(iOS 10.0, *)
private extension UIDisplayGamut {
  var description: String {
    switch self {
    case .P3: return "P3"
    case .SRGB: return "SRGB"
    case .unspecified: return "unspecified"
    @unknown default: return "unknown"
    }
  }
}

private extension CGSize {
  func rotate(_ orientation: UIInterfaceOrientation?) -> CGSize {
    switch orientation {
    case .landscapeLeft?: return CGSize(width: height, height: width)
    case .landscapeRight?: return CGSize(width: height, height: width)
    default: return self
    }
  }
}

private extension UIContentSizeCategory {

  var description: String {
    switch self {
    case UIContentSizeCategory.extraSmall: return "extraSmall"
    case UIContentSizeCategory.small: return "small"
    case UIContentSizeCategory.medium: return "medium"
    case UIContentSizeCategory.large: return "large"
    case UIContentSizeCategory.extraLarge: return "extraLarge"
    case UIContentSizeCategory.extraExtraLarge: return "extraExtraLarge"
    case UIContentSizeCategory.extraExtraExtraLarge: return "extraExtraExtraLarge"
    case UIContentSizeCategory.accessibilityMedium: return "accessibilityMedium"
    case UIContentSizeCategory.accessibilityLarge: return "accessibilityLarge"
    case UIContentSizeCategory.accessibilityExtraLarge: return "accessibilityExtraLarge"
    case UIContentSizeCategory.accessibilityExtraExtraLarge: return "accessibilityExtraExtraLarge"
    case UIContentSizeCategory.accessibilityExtraExtraExtraLarge: return "accessibilityExtraExtraExtraLarge"
    default:
      if #available(iOS 10.0, *) {
        if case UIContentSizeCategory.unspecified = self {
          return "unspecified"
        }
      }
      return "unknown"
    }
  }
}

@available(iOS 13.0, *)
private extension UIAccessibilityContrast {
  var description: String {
    switch self {
    case .unspecified: return "unspecified"
    case .normal: return "normal"
    case .high: return "high"
    @unknown default: return "unknown"
    }
  }
}

@available(iOS 13.0, *)
private extension UILegibilityWeight {
  var description: String {
    switch self {
    case .unspecified: return "unspecified"
    case .regular: return "regular"
    case .bold: return "bold"
    @unknown default: return "unknown"
    }
  }
}

private extension UIAccessibility {
  static func usesAnyAccessibilitySetting() -> Bool {
    var enabled = false

    if #available(iOS 10.0, *) {
      enabled = enabled || isAssistiveTouchRunning
    }
    enabled = enabled || isBoldTextEnabled
    enabled = enabled || isClosedCaptioningEnabled
    enabled = enabled || isDarkerSystemColorsEnabled
    enabled = enabled || isGrayscaleEnabled
    enabled = enabled || isGuidedAccessEnabled
    enabled = enabled || isInvertColorsEnabled
    enabled = enabled || isMonoAudioEnabled
    enabled = enabled || isReduceTransparencyEnabled
    enabled = enabled || isSpeakScreenEnabled
    enabled = enabled || isSpeakSelectionEnabled
    enabled = enabled || isSwitchControlRunning
    enabled = enabled || isVoiceOverRunning

    enabled = enabled || !isShakeToUndoEnabled

    if #available(iOS 13.0, *) {
      if UITraitCollection.current.preferredContentSizeCategory != .large {
        enabled = true
      }
    }

    return enabled
  }
}

extension UIDevice {
  var modelIdentifier: String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
    return identifier
  }

  /// Returns the human-readable model name of the device.
  /// Falls back to the model identifier when no matching model name is known.
  public var modelName: String {
    /// Reference: https://www.theiphonewiki.com/wiki/Models
    let names = [
      "i386": "Simulator",
      "x86_64": "Simulator",

      "iPod1,1": "iPod Touch",
      "iPod2,1": "iPod Touch (2nd generation)",
      "iPod3,1": "iPod Touch (3rd generation)",
      "iPod4,1": "iPod Touch (4th generation)",
      "iPod5,1": "iPod Touch (5th generation)",
      "iPod7,1": "iPod Touch (6th generation)",
      "iPod9,1": "iPod Touch (7th generation)",

      "iPad1,1": "iPad",
      "iPad2,1": "iPad 2",
      "iPad2,2": "iPad 2",
      "iPad2,3": "iPad 2",
      "iPad2,4": "iPad 2",
      "iPad2,5": "iPad mini",
      "iPad2,6": "iPad mini",
      "iPad2,7": "iPad mini",
      "iPad3,1": "iPad (3rd generation)",
      "iPad3,2": "iPad (3rd generation)",
      "iPad3,3": "iPad (3rd generation)",
      "iPad3,4": "iPad (4rd generation)",
      "iPad3,5": "iPad (4rd generation)",
      "iPad3,6": "iPad (4rd generation)",
      "iPad4,1": "iPad Air",
      "iPad4,2": "iPad Air",
      "iPad4,3": "iPad Air",
      "iPad4,4": "iPad mini 2",
      "iPad4,5": "iPad mini 2",
      "iPad4,6": "iPad mini 2",
      "iPad4,7": "iPad mini 3",
      "iPad4,8": "iPad mini 3",
      "iPad4,9": "iPad mini 3",
      "iPad5,1": "iPad mini 4",
      "iPad5,2": "iPad mini 4",
      "iPad5,3": "iPad Air 2",
      "iPad5,4": "iPad Air 2",
      "iPad6,11": "iPad 5",
      "iPad6,12": "iPad 5",
      "iPad6,3": "iPad Pro (9.7\")",
      "iPad6,4": "iPad Pro (9.7\")",
      "iPad6,7": "iPad Pro (12.9\")",
      "iPad6,8": "iPad Pro (12.9\")",
      "iPad7,1": "iPad Pro (12.9\") (2nd generation)",
      "iPad7,11": "iPad 7",
      "iPad7,12": "iPad 7",
      "iPad7,2": "iPad Pro (12.9\") (2nd generation)",
      "iPad7,3": "iPad Pro (10.5\")",
      "iPad7,4": "iPad Pro (10.5\")",
      "iPad7,5": "iPad 6",
      "iPad7,6": "iPad 6",
      "iPad8,1": "iPad Pro (11\")",
      "iPad8,10": "iPad Pro (11\") (2nd generation)",
      "iPad8,11": "iPad Pro (12.9\") (4th generation)",
      "iPad8,12": "iPad Pro (12.9\") (4th generation)",
      "iPad8,2": "iPad Pro (11\")",
      "iPad8,3": "iPad Pro (11\")",
      "iPad8,4": "iPad Pro (11\")",
      "iPad8,5": "iPad Pro (12.9\") (3rd generation)",
      "iPad8,6": "iPad Pro (12.9\") (3rd generation)",
      "iPad8,7": "iPad Pro (12.9\") (3rd generation)",
      "iPad8,8": "iPad Pro (12.9\") (3rd generation)",
      "iPad8,9": "iPad Pro (11\") (2nd generation)",
      "iPad11,1": "iPad mini 5",
      "iPad11,2": "iPad mini 5",
      "iPad11,3": "iPad Air 3",
      "iPad11,4": "iPad Air 3",
      "iPad11,6": "iPad (8th generation)",
      "iPad11,7": "iPad (8th generation)",
      "iPad12,1": "iPad (9th generation)",
      "iPad12,2": "iPad (9th generation)",
      "iPad13,1": "iPad Air (4th generation)",
      "iPad13,10": "iPad Pro (12.9-inch) (5th generation)",
      "iPad13,11": "iPad Pro (12.9-inch) (5th generation)",
      "iPad13,2": "iPad Air (4th generation)",
      "iPad13,4": "iPad Pro (11-inch) (3rd generation)",
      "iPad13,5": "iPad Pro (11-inch) (3rd generation)",
      "iPad13,6": "iPad Pro (11-inch) (3rd generation)",
      "iPad13,7": "iPad Pro (11-inch) (3rd generation)",
      "iPad13,8": "iPad Pro (12.9-inch) (5th generation)",
      "iPad13,9": "iPad Pro (12.9-inch) (5th generation)",
      "iPad14,1": "iPad mini (6th generation)",
      "iPad14,2": "iPad mini (6th generation)",

      "iPhone1,1": "iPhone",
      "iPhone1,2": "iPhone 3G",
      "iPhone2,1": "iPhone 3GS",
      "iPhone3,1": "iPhone 4",          // (GSM)
      "iPhone3,3": "iPhone 4",          // (CDMA/Verizon/Sprint)
      "iPhone4,1": "iPhone 4S",         //
      "iPhone5,1": "iPhone 5",          // (model A1428, AT&T/Canada)
      "iPhone5,2": "iPhone 5",          // (model A1429, everything else)

      "iPhone5,3": "iPhone 5c",         // (model A1456, A1532 | GSM)
      "iPhone5,4": "iPhone 5c",         // (model A1507, A1516, A1526 (China), A1529 | Global)
      "iPhone6,1": "iPhone 5s",         // (model A1433, A1533 | GSM)
      "iPhone6,2": "iPhone 5s",         // (model A1457, A1518, A1528 (China), A1530 | Global)
      "iPhone7,1": "iPhone 6 Plus",     //
      "iPhone7,2": "iPhone 6",          //
      "iPhone8,1": "iPhone 6S",         //
      "iPhone8,2": "iPhone 6S Plus",    //
      "iPhone8,4": "iPhone SE",         //
      "iPhone9,1": "iPhone 7",          //
      "iPhone9,2": "iPhone 7 Plus",     //
      "iPhone9,3": "iPhone 7",          //
      "iPhone9,4": "iPhone 7 Plus",     //
      "iPhone10,1": "iPhone 8",          // CDMA
      "iPhone10,2": "iPhone 8 Plus",     // CDMA
      "iPhone10,3": "iPhone X",          // CDMA
      "iPhone10,4": "iPhone 8",          // GSM
      "iPhone10,5": "iPhone 8 Plus",     // GSM
      "iPhone10,6": "iPhone X",          // GSM
      "iPhone11,2": "iPhone XS",         //
      "iPhone11,4": "iPhone XS Max",     //
      "iPhone11,6": "iPhone XS Max",     // China
      "iPhone11,8": "iPhone XR",         //
      "iPhone12,1": "iPhone 11",         //
      "iPhone12,3": "iPhone 11 Pro",     //
      "iPhone12,5": "iPhone 11 Pro Max", //
      "iPhone12,8": "iPhone SE (2nd generation)", //
      "iPhone13,1": "iPhone 12 mini",    //
      "iPhone13,2": "iPhone 12",         //
      "iPhone13,3": "iPhone 12 Pro",     //
      "iPhone13,4": "iPhone 12 Pro Max", //
      "iPhone14,2": "iPhone 13 Pro",     //
      "iPhone14,3": "iPhone 13 Pro Max", //
      "iPhone14,4": "iPhone 13 mini",    //
      "iPhone14,5": "iPhone 13",         //
    ]

    let id = modelIdentifier
    return names[id] ?? id
  }
}

// Real hacky function for determening day/night/twilight
// With very wide margin (3 hours), because we don't know how
// iOS implements this for Dark mode switch
private func dayNight() -> String {
  guard TimeZone.current.identifier == "Europe/Amsterdam" else {
    return "unknown"
  }

  let now = Date()

  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.dateFormat = "M"
  let month = Int(formatter.string(from: now))!
  formatter.dateFormat = "H"
  let hour = Int(formatter.string(from: now))!

  // Hacky hardcoded table for sun raise/set in Amsterdam
  let sunRaiseSetHours = [
    (8, 17), // jan
    (7, 18), // feb
    (7, 19), // mar
    (6, 20), // apr
    (5, 21), // may
    (5, 22), // jun
    (5, 21), // jul
    (6, 20), // aug
    (7, 19), // sep
    (7, 18), // oct
    (8, 17), // nov
    (8, 16), // dev
  ]

  let (raise, set) = sunRaiseSetHours[month - 1]
  let twilight = abs(hour - raise) < 2 || abs(hour - set) < 2
  let daytime = raise < hour && hour < set

  return twilight ? "twilight" : daytime ? "day" : "night"
}

private struct StatsPayload: Encodable {
  let fields: [String: StatsPayloadValue]

  init(stats: [String: String], hashFunc: (String) -> String, secret: String) {
    let orderedValues = stats.keys.sorted().map { stats[$0] ?? "" }.joined(separator: "-")
    let checksum = hashFunc(orderedValues + "-" + secret)

    var fields = stats.mapValues(StatsPayloadValue.init)
    fields["Checksum"] = StatsPayloadValue(stringValue: checksum)
    self.fields = fields
  }

  struct StatsPayloadValue: Encodable {
    let stringValue: String
  }
}
