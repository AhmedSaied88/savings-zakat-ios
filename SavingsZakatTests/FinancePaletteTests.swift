import XCTest
import SwiftUI
import UIKit
@testable import SavingsZakat

final class FinancePaletteTests: XCTestCase {
    func testPrimaryAndSecondaryAccentsMeetTextContrastInBothAppearances() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let surfaces = [
                UIColor(FinancePalette.whiteSurface).resolvedColor(with: traits),
                UIColor(FinancePalette.canvas).resolvedColor(with: traits),
                UIColor(FinancePalette.paleBlue).resolvedColor(with: traits)
            ]
            let textAccents = [
                UIColor(FinancePalette.royalBlue).resolvedColor(with: traits),
                UIColor(FinancePalette.violet).resolvedColor(with: traits)
            ]

            for accent in textAccents {
                for surface in surfaces {
                    XCTAssertGreaterThanOrEqual(contrastRatio(accent, surface), 4.5,
                                                "Primary and secondary text accents must meet WCAG AA in \(style)")
                }
            }
        }
    }

    func testSemanticStatusColorsMeetTextContrastInBothAppearances() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let surfaces = [
                UIColor(FinancePalette.whiteSurface).resolvedColor(with: traits),
                UIColor(FinancePalette.canvas).resolvedColor(with: traits),
                UIColor(FinancePalette.paleBlue).resolvedColor(with: traits)
            ]
            let statusColors = [
                UIColor(FinancePalette.income).resolvedColor(with: traits),
                UIColor(FinancePalette.expense).resolvedColor(with: traits),
                UIColor(FinancePalette.warning).resolvedColor(with: traits),
                UIColor(FinancePalette.danger).resolvedColor(with: traits)
            ]

            for statusColor in statusColors {
                for surface in surfaces {
                    XCTAssertGreaterThanOrEqual(contrastRatio(statusColor, surface), 4.5,
                                                "Semantic status text must meet WCAG AA in \(style)")
                }
            }
        }
    }

    func testGoldAccentMeetsNonTextContrastInBothAppearances() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let surfaces = [
                UIColor(FinancePalette.paleBlue).resolvedColor(with: traits),
                UIColor(FinancePalette.whiteSurface).resolvedColor(with: traits),
                UIColor(FinancePalette.canvas).resolvedColor(with: traits)
            ]
            let gold = UIColor(FinancePalette.gold).resolvedColor(with: traits)

            for surface in surfaces {
                XCTAssertGreaterThanOrEqual(contrastRatio(gold, surface), 3.0,
                                            "Gold asset accent must meet WCAG non-text contrast in \(style)")
            }
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
