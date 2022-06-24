Q42Stats
=======

Collect stats for Q42 internal usage, shared accross multiple iOS projects.

## Instalation

1. Use SPM or CocoaPods to add  `Q42Stats` into your iOS project
2. Implement your configuration and a SHA256 implementation (see reference implementations below)
3. Include stats collection & submission in your AppDelegate/WindowSceneDelegate like so:

```swift
Q42Stats(options: .all)
  .collect(window: window, completion: Q42Stats.submit(configuration: .myApp))
```

Note: Make sure you have the correct consent from the user before you call `.collect()`.

### CocoaPods

Add to your `Podfile` the following line:

`pod 'Q42Stats', git: 'https://github.com/Q42/Q42Stats.git'`

Also make sure you require iOS 11 or higher as the minimum target using: `platform :ios, '11.0'`

### Swift Package Manager

Add this repo as a dependency through Xcode: `https://github.com/Q42/Q42Stats.git`

## Reference implementations

### Example configuration implementation

```swift
extension Q42Stats.Configuration {
  static let myApp = Q42Stats.Configuration(
    apiKey: "secret",
    firestoreCollection: "somecollection",
    minimumSubmitInterval: 60*60*24*7.5
  )
}
```
