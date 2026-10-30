import XCTest
@testable import SavingsZakat

final class HawlNotificationSchedulerTests: XCTestCase {
    func testPlannerCreatesThirtySevenOneAndDueDayReminders() {
        let holding = sampleHolding()
        let due = HawlDueDate(date: date("2026-03-01"), status: .estimated)
        let planner = HawlReminderPlanner()

        let reminders = planner.reminders(
            for: holding,
            dueDate: due,
            now: date("2026-01-01"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        XCTAssertEqual(reminders.map(\.daysBefore), [30, 7, 1, 0])
        XCTAssertEqual(Set(reminders.map(\.identifier)).count, 4)
        XCTAssertTrue(reminders.allSatisfy { $0.identifier.hasPrefix("hawl.\(holding.id.uuidString).") })
    }

    func testPlannerSkipsReminderDatesThatHaveAlreadyPassed() {
        let reminders = HawlReminderPlanner().reminders(
            for: sampleHolding(),
            dueDate: HawlDueDate(date: date("2026-03-01"), status: .estimated),
            now: date("2026-02-15"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        XCTAssertEqual(reminders.map(\.daysBefore), [7, 1, 0])
    }

    func testReminderUsesNineAMInSelectedLocalTimeZone() throws {
        let holding = sampleHolding()
        let due = HawlDueDate(date: date("2026-03-01"), status: .estimated)
        let planner = HawlReminderPlanner()
        let cairo = try XCTUnwrap(TimeZone(identifier: "Africa/Cairo"))
        let utc = TimeZone(secondsFromGMT: 0)!

        let cairoReminder = try XCTUnwrap(planner.reminders(for: holding, dueDate: due, now: date("2026-01-01"), timeZone: cairo).first)
        let utcReminder = try XCTUnwrap(planner.reminders(for: holding, dueDate: due, now: date("2026-01-01"), timeZone: utc).first)

        var cairoCalendar = Calendar(identifier: .gregorian)
        cairoCalendar.timeZone = cairo
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = utc
        XCTAssertEqual(cairoCalendar.component(.hour, from: cairoReminder.fireDate), 9)
        XCTAssertEqual(utcCalendar.component(.hour, from: utcReminder.fireDate), 9)
        XCTAssertNotEqual(cairoReminder.fireDate, utcReminder.fireDate)
    }

    func testDeniedPermissionLeavesExistingRemindersUntouched() async throws {
        let center = MockHawlNotificationCenter(authorized: false)
        let existing = notification(holdingID: UUID(), offset: 7, fireDate: date("2026-02-01"))
        center.notifications[existing.identifier] = existing
        let scheduler = HawlNotificationScheduler(notificationCenter: center)

        let result = try await scheduler.schedule([notification(holdingID: UUID(), offset: 1, fireDate: date("2026-02-02"))])

        XCTAssertEqual(result, .permissionDenied)
        XCTAssertEqual(center.notifications[existing.identifier], existing)
        XCTAssertEqual(center.notifications.count, 1)
    }

    func testReschedulingAfterDateCorrectionReplacesOldDatesWithStableIdentifiers() async throws {
        let center = MockHawlNotificationCenter()
        let scheduler = HawlNotificationScheduler(notificationCenter: center)
        let holdingID = UUID()
        let original = notification(holdingID: holdingID, offset: 7, fireDate: date("2026-02-01"))
        let corrected = notification(holdingID: holdingID, offset: 7, fireDate: date("2026-02-03"))

        let firstResult = try await scheduler.schedule([original])
        let correctedResult = try await scheduler.schedule([corrected])
        XCTAssertEqual(firstResult, .scheduled(count: 1))
        XCTAssertEqual(correctedResult, .scheduled(count: 1))

        XCTAssertEqual(center.notifications.count, 1)
        XCTAssertEqual(center.notifications[corrected.identifier]?.fireDate, corrected.fireDate)
    }

    func testCancelForOneHoldingDoesNotCancelOtherHoldings() async {
        let center = MockHawlNotificationCenter()
        let firstID = UUID()
        let secondID = UUID()
        let first = notification(holdingID: firstID, offset: 7, fireDate: date("2026-02-01"))
        let second = notification(holdingID: secondID, offset: 7, fireDate: date("2026-02-02"))
        center.notifications[first.identifier] = first
        center.notifications[second.identifier] = second
        let scheduler = HawlNotificationScheduler(notificationCenter: center)

        await scheduler.cancel(holdingID: firstID)

        XCTAssertNil(center.notifications[first.identifier])
        XCTAssertEqual(center.notifications[second.identifier], second)
    }

    func testCancelAllOnlyRemovesHawlNotifications() async {
        let center = MockHawlNotificationCenter()
        let hawl = notification(holdingID: UUID(), offset: 1, fireDate: date("2026-02-01"))
        let other = HawlLocalNotification(
            identifier: "other-feature-reminder",
            holdingID: UUID(),
            daysBefore: 0,
            title: "Other",
            body: "Other",
            fireDate: date("2026-02-02"),
            timeZoneIdentifier: "UTC"
        )
        center.notifications[hawl.identifier] = hawl
        center.notifications[other.identifier] = other
        let scheduler = HawlNotificationScheduler(notificationCenter: center)

        await scheduler.cancelAll()

        XCTAssertNil(center.notifications[hawl.identifier])
        XCTAssertEqual(center.notifications[other.identifier], other)
    }

    func testPartialSchedulingReportsFailedIdentifiers() async throws {
        let center = MockHawlNotificationCenter()
        let first = notification(holdingID: UUID(), offset: 7, fireDate: date("2026-02-01"))
        let second = notification(holdingID: UUID(), offset: 1, fireDate: date("2026-02-02"))
        center.failedIdentifiers = [second.identifier]
        let scheduler = HawlNotificationScheduler(notificationCenter: center)

        let result = try await scheduler.schedule([first, second])

        XCTAssertEqual(result, .partiallyScheduled(count: 1, failedIdentifiers: [second.identifier]))
        XCTAssertEqual(center.notifications.count, 1)
    }


    func testSchedulerRespectsIOSPendingNotificationLimit() async throws {
        let center = MockHawlNotificationCenter()
        let scheduler = HawlNotificationScheduler(notificationCenter: center)
        let notifications = (0..<80).map { index in
            notification(
                holdingID: UUID(),
                offset: index % 4,
                fireDate: date("2026-02-01").addingTimeInterval(TimeInterval(index * 60))
            )
        }

        let result = try await scheduler.schedule(notifications)

        XCTAssertEqual(result, .limited(count: 64, omittedCount: 16))
        XCTAssertEqual(center.notifications.count, 64)
        XCTAssertEqual(
            center.notifications.values.map(\.fireDate).max(),
            notifications.sorted { $0.fireDate < $1.fireDate }[63].fireDate
        )
    }

    private func sampleHolding() -> Holding {
        let start = date("2025-01-01")
        return Holding(
            id: UUID(), kind: .cash, amount: 100, currency: "EGP", grams: nil, carat: nil,
            acquiredDate: start, hawlStartDate: start, purpose: .investment
        )
    }

    private func notification(holdingID: UUID, offset: Int, fireDate: Date) -> HawlLocalNotification {
        HawlLocalNotification(
            identifier: "hawl.\(holdingID.uuidString).\(offset)",
            holdingID: holdingID,
            daysBefore: offset,
            title: "Hawl reminder",
            body: "Test",
            fireDate: fireDate,
            timeZoneIdentifier: "UTC"
        )
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: value)!
    }
}

private final class MockHawlNotificationCenter: HawlNotificationCenterProtocol {
    var authorized: Bool
    var notifications: [String: HawlLocalNotification] = [:]
    var failedIdentifiers: Set<String> = []

    init(authorized: Bool = true) {
        self.authorized = authorized
    }

    func requestAuthorization() async throws -> Bool {
        authorized
    }

    func add(_ notification: HawlLocalNotification) async throws {
        if failedIdentifiers.contains(notification.identifier) {
            throw MockError.addFailed
        }
        notifications[notification.identifier] = notification
    }

    func pendingIdentifiers() async -> [String] {
        Array(notifications.keys)
    }

    func removePending(withIdentifiers identifiers: [String]) async {
        for identifier in identifiers {
            notifications.removeValue(forKey: identifier)
        }
    }

    private enum MockError: Error {
        case addFailed
    }
}
