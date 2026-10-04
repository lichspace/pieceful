import XCTest

final class NavigationUITests: XCTestCase {
    func testPuzzleSelectionOpensDifficultyOptionsWithoutIntermediateScreen() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["动物"].waitForExistence(timeout: 3))
        app.buttons["动物"].tap()

        XCTAssertTrue(app.buttons["森林里的小熊猫"].waitForExistence(timeout: 3))
        app.buttons["森林里的小熊猫"].tap()

        XCTAssertTrue(app.buttons["12 片"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "24 片")).firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "48 片")).firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "96 片")).firstMatch.exists)
    }

    func testPuzzleScreenExposesReferenceAndPlayControls() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["动物"].tap()
        app.buttons["森林里的小熊猫"].tap()
        app.buttons["12 片"].tap()

        XCTAssertTrue(app.buttons["原图"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["暂停"].exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "提示")).firstMatch.exists)
    }

    func testSettingsExposeAudioAndEffectsControls() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["设置"].tap()

        XCTAssertTrue(app.switches["配乐"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.switches["音效"].exists)
        XCTAssertTrue(app.switches["拼图特效"].exists)
    }
}
