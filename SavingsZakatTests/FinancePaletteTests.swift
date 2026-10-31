import XCTest
import SwiftUI
import UIKit
@testable import SavingsZakat

final class FinancePaletteTests: XCTestCase {
    func testPrimaryAndSecondaryAccentsMeetTextContrastInBothAppearances() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let surface = UIColor(FinancePalette.whiteSurface).resolvedColor(with: traits)
            let primary = UIColor(FinancePalette.royalBlue).resolvedColor(with: traits)
            let secondary = UIColor(FinancePalette.violet).resolvedColor(with: traits)

            XCTAssertGreaterThanOrEqual(contrastRatio(primary, surface), 4.5,
                                        "Royal blue must meet WCAG AA text contrast in \(style)")
            XCTAssertGreaterThanOrEqual(contrastRatio(secondary, surface), 4.5,
                                        "Violet must meet WCAG AA text contrast in \(style)")
        }
    }

    func testGoldAccentMeetsNonTextContrastInBothAppearances() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let surface = UIColor(FinancePalette.paleBlue).resolvedColor(with: traits)
            let gold = UIColor(FinancePalette.gold).resolvedColor(with: traits)

            XCTAssertGreaterThanOrEqual(contrastRatio(gold, surface), 3.0,
                                        "Gold asset accent must meet WCAG non-text contrast in \(style)")
        }
    }

    private func contrastRatio(_ first: UIColor, _ second: UIColor) -> CGFloat {
        let firstLuminance = relativeLuminance(first)
        let secondLuminance = relativeLuminance(second)
        let lighter = max(firstLuminance, secondLuminance)
        let darker = min(firstLuminance, secondLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        func linearize(_ component: CGFloat) -> CGFloat {
            component <= 0.04045
                ? component / 12.92
                : pow((component + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linearize(red)
            + 0.7152 * linearize(green)
            + 0.0722 * linearize(blue)
    }
}
