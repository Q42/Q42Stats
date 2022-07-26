Q42Stats
=======

Collect stats for Q42 internal usage, shared accross multiple iOS projects.

## Installation

1. Use the Swift package manager to add  `Q42Stats` into your iOS project
2. Implement your configuration and a SHA256 implementation (see reference implementations below)
3. Include stats collection & submission in your AppDelegate/WindowSceneDelegate like so:

```swift
Q42Stats(options: .all)
  .collect(window: window, completion: Q42Stats.submit(configuration: .myApp))
```

Note: Make sure you have the correct consent from the user before you call `.collect()`.

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

## Data collected
Q42Stats does not collect personal data, the data collected can not be related to an identified or identifiable individual. It is good practice to inform users of data collection, consent is not required within European law. This has been verified by legal counsel.

### Accessibliity

| Key | Value | Notes |
|-|-|-|
| `isSwitchControlRunning` | boolean | Control the device by a switch such as a foot pedal |
| `isBoldTextEnabled` | boolean | Improves the contrast of the letters against the background |
| `isReduceTransparencyEnabled` | boolean | Makes system windows, overlays and other transparent elements opaque or less transparent |
| `isMonoAudioEnabled` | boolean | Sends the left and right channels of stereo sound through both channels |
| `isClosedCaptioningEnabled` | boolean | Automatically activates closed captions for videos in the user’s preferred language when facilitated by the creator of the video |
| `isDarkerSystemColorsEnabled` | boolean | Increases the contrast between the various elements on the screen |
| `isGuidedAccessEnabled` | boolean | Limits a device to a single app and lets a user control which features are available. E.g. turned on when accidental gestures might distract a user |
| `isAssistiveTouchRunning_with_isGuidedAccessEnabled` | string | `isAssistiveTouchRunning` will only be the correct value if `isGuidedAccessEnabled` is `true`. See: [Apple's developer documentation](https://developer.apple.com/documentation/uikit/uiaccessibility/1648479-isassistivetouchrunning) |
| `uses_any_accessibility_setting` | boolean | True if one or more  accessibility settings are activated |
| `isVoiceOverRunning` | boolean | With VoiceOver—a gesture-based screen reader—you can use an iPhone even if you can’t see the screen. VoiceOver gives audible descriptions of what’s on your screen |
| `isInvertColorsEnabled` | boolean | Indicates whether the Classic Invert setting is in an enabled state |
| `isSpeakSelectionEnabled` | boolean | Allows text to be read aloud. When you select a piece of text, the option to have it read aloud appears |
| `isShakeToUndoEnabled` | boolean | Undoes the last text entry when the phone is shaken, making it easy to delete text. People turn off this option if there is a risk that they will activate it unintentionally |
| `isSpeakScreenEnabled` | boolean | Ensures that everything on the screen is read aloud when you swipe down with two fingers |
| `isGrayscaleEnabled` | boolean | Turn on black and white mode |

### Preferences

| Key | Value | Notes |
|-|-|-|
| `daytime` | string | Coarse estimation of time of day “day”, “night”, “twilight”. Returns “unknown” when user is not in Amsterdam TimeZone |
| `UI_style` | string | Indicate the interface style for the app “unspecified”, “light”, or “dark” |
| `preferred_content_size` | string | The preferred size of your content, more commonly known as the font-size. For a full list of possible values see [Apple’s developer documentation](https://developer.apple.com/documentation/uikit/uicontentsizecategory) |

### Screen

| Key | Value | Notes |
|-|-|-|
| `window_width` | integer | Width of app’s viewport. This can differ from screen width when in split screen mode, for example |
| `width` | integer | Device’s screen width |
| `display_gamut` | string | The colorspace that is used, representing the colors that can be represented on screen. Possible values: “Uspecified”, “SRGB”, “P3” |
| `device_idiom` | string | Kind of User Interface being used, e.g. iPhone, iPad, Mac, AppleTV |
| `zoomed` | boolean | True if the entire screen or a part of the screen is magnified |
| `in_split_screen` | boolean | Indicates if apps are displayed in split screen mode |
| `orientation` | string | Indicates if device is in landscape or in portrait mode |
| `scale` | string | The natural scale factor associated with the screen. For Retina displays, the scale factor may be 3.0 or 2.0. For standard-resolution displays, the scale factor is 1.0 |

### System

| Key | Value | Notes |
|-|-|-|
| `Dutch_region` | boolean | Indicates if preferred language is dutch or the current region code is “NL” |
| `Preferred_language` | string | Language setting of the device e.g. nl, en, … |
| `OS_major_version` | string | Current version of the operating system in use e.g. 13, 14 or 15 |
| `model_name` | string | A more human-readable model name of the device e.g. “iPad Pro”, “iPhone XR” or “iPhone 13” |
| `model_id` | string | Device model as a string. The format is something like “iPhone12,1” which stands for iPhone 11. Or "iPhone13,3" which stands for iPhone 12 Pro |

### Apple Pay

| Key | Value | Notes |
|-|-|-|
| `available` | boolean | True if a user can make payments with Apple Pay |
| `with_Maestro_available` | boolean | True if maestro is available to make payments with |

### Watch

| Key | Value | Notes |
|-|-|-|
| `supported` | boolean | Boolean value indicating if the current device supports watch connectivity |
| `paired` | boolean | True if an Apple Watch is paired |

### App

| Key | Value | Notes |
|-|-|-|
| `bundle_identifier` | string | Identifier for the app for which data is collected |

### Stats

| Key | Value | Notes |
|-|-|-|
| `stats_timestamp` | string | |
| `stats_version` | string | |
