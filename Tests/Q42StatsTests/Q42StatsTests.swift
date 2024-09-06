import XCTest
@testable import Q42Stats

final class Q42StatsTests: XCTestCase {
    func testCollectAccessibilityStatistics() throws {
        let stats = Q42Stats(options: [.accessibility])
        let expectation = expectation(description: "Stats collection")
        stats.collect(window: nil) { result in
            expectation.fulfill()
            XCTAssertNotNil(result["Accessibility_isAssistiveTouchRunning_with_isGuidedAccessEnabled"])
            XCTAssertNotNil(result["Accessibility_uses_any_accessibility_setting"])
            XCTAssertNotNil(result["Accessibility_isBoldTextEnabled"])
            XCTAssertNotNil(result["Accessibility_isClosedCaptioningEnabled"])
            XCTAssertNotNil(result["Accessibility_isDarkerSystemColorsEnabled"])
            XCTAssertNotNil(result["Accessibility_isGrayscaleEnabled"])
            XCTAssertNotNil(result["Accessibility_isGuidedAccessEnabled"])
            XCTAssertNotNil(result["Accessibility_isInvertColorsEnabled"])
            XCTAssertNotNil(result["Accessibility_isMonoAudioEnabled"])
            XCTAssertNotNil(result["Accessibility_isReduceTransparencyEnabled"])
            XCTAssertNotNil(result["Accessibility_isShakeToUndoEnabled"])
            XCTAssertNotNil(result["Accessibility_isSpeakScreenEnabled"])
            XCTAssertNotNil(result["Accessibility_isSpeakSelectionEnabled"])
            XCTAssertNotNil(result["Accessibility_isSwitchControlRunning"])
            XCTAssertNotNil(result["Accessibility_isVoiceOverRunning"])
        }
        waitForExpectations(timeout: 5.0)
    }
}
