import Foundation
import UserNotifications

struct HawlLocalNotification: Equatable {
    let identifier: String
    let holdingID: UUID
    let daysBefore: Int
    let title: String
    let body: String
    let fireDate: Date
    let timeZoneIdentifier: String
}

struct HawlReminderPlanner {
    static let reminderOffsets = [30, 7, 1, 0]
    static let notificationPrefix = "hawl."
    static let maximumPendingNotifications = 64

    func reminders(
        for holding: Holding,
        dueDate: HawlDueDate,
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> [HawlLocalNotification] {
        var cairo = Calendar(identifier: .gregorian)
        cairo.timeZone = TimeZone(identifier: "Africa/Cairo") ?? .current
        let dueDay = cairo.startOfDay(for: dueDate.date)

        var local = Calendar(identifier: .gregorian)
        local.timeZone = timeZone

        return Self.reminderOffsets.compactMap { offset in
            guard let reminderDay = cairo.date(byAdding: .day, value: -offset, to: dueDay) else {
                return nil
            }
            let civilDate = cairo.dateComponents([.year, .month, .day], from: reminderDay)
            var localComponents = DateComponents()
            localComponents.year = civilDate.year
            localComponents.month = civilDate.month
            localComponents.day = civilDate.day
            localComponents.hour = 9
            localComponents.minute = 0
            guard let fireDate = local.date(from: localComponents), fireDate > now else {
                return nil
            }

            let identifier = Self.notificationPrefix + holding.id.uuidString + "." + String(offset)
            let dueLabel = dueDay.formatted(date: .long, time: .omitted)
            let title = offset == 0 ? "Hawl is due today" : "Hawl reminder"
            let asset = Self.assetLabel(holding)
            let body = offset == 0
                ? "\(asset): Hawl is due today (\(dueLabel)). Review your Zakat calculation."
                : "\(asset): Hawl is in \(offset) days (\(dueLabel)). Review your Zakat calculation."
            return HawlLocalNotification(
                identifier: identifier,
                holdingID: holding.id,
                daysBefore: offset,
                title: title,
                body: body,
                fireDate: fireDate,
                timeZoneIdentifier: timeZone.identifier
            )
        }
    }

    private static func assetLabel(_ holding: Holding) -> String {
        switch holding.kind {
        case .cash: return "Cash \(holding.currency ?? "EGP")"
        case .gold: return "Gold \(holding.carat ?? 24)K"
        case .silver: return "Silver"
        case .investment: return holding.name ?? "Investment"
        }
    }
}

protocol HawlNotificationCenterProtocol {
    func requestAuthorization() async throws -> Bool
    func add(_ notification: HawlLocalNotification) async throws
    func pendingIdentifiers() async -> [String]
    func removePending(withIdentifiers identifiers: [String]) async
}

struct SystemHawlNotificationCenter: HawlNotificationCenterProtocol {
    let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async throws -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return try await center.requestAuthorization(options: [.alert, .sound])
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func add(_ notification: HawlLocalNotification) async throws {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: notification.timeZoneIdentifier) ?? .current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notification.fireDate)
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: notification.identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    func pendingIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }

    func removePending(withIdentifiers identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

struct HawlNotificationScheduler {
    enum ScheduleResult: Equatable {
        case permissionDenied
        case scheduled(count: Int)
        case partiallyScheduled(count: Int, failedIdentifiers: [String])
        case limited(count: Int, omittedCount: Int)
    }

    private let notificationCenter: HawlNotificationCenterProtocol
    private let planner: HawlReminderPlanner

    init(
        notificationCenter: HawlNotificationCenterProtocol = SystemHawlNotificationCenter(),
        planner: HawlReminderPlanner = HawlReminderPlanner()
    ) {
        self.notificationCenter = notificationCenter
        self.planner = planner
    }

    func schedule(
        holdings: [Holding],
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) async throws -> ScheduleResult {
        let notifications = holdings.flatMap { holding -> [HawlLocalNotification] in
            guard let due = HawlCalculator.dueDateResult(startDate: holding.hawlStartDate) else { return [] }
            return planner.reminders(for: holding, dueDate: due, now: now, timeZone: timeZone)
        }
        return try await schedule(notifications)
    }

    func schedule(_ notifications: [HawlLocalNotification]) async throws -> ScheduleResult {
        let existing = await notificationCenter.pendingIdentifiers()
            .filter { $0.hasPrefix(HawlReminderPlanner.notificationPrefix) }

        if notifications.isEmpty {
            await notificationCenter.removePending(withIdentifiers: existing)
            return .scheduled(count: 0)
        }

        guard try await notificationCenter.requestAuthorization() else {
            return .permissionDenied
        }

        let prioritized = notifications.sorted { $0.fireDate < $1.fireDate }
        let selected = Array(prioritized.prefix(HawlReminderPlanner.maximumPendingNotifications))
        let omittedCount = max(0, prioritized.count - selected.count)

        await notificationCenter.removePending(withIdentifiers: existing)
        var scheduledCount = 0
        var failed: [String] = []
        for notification in selected {
            do {
                try await notificationCenter.add(notification)
                scheduledCount += 1
            } catch {
                failed.append(notification.identifier)
            }
        }

        if !failed.isEmpty {
            return .partiallyScheduled(count: scheduledCount, failedIdentifiers: failed)
        }
        if omittedCount > 0 {
            return .limited(count: scheduledCount, omittedCount: omittedCount)
        }
        return .scheduled(count: scheduledCount)
    }

    func cancel(holdingID: UUID) async {
        let prefix = HawlReminderPlanner.notificationPrefix + holdingID.uuidString + "."
        let identifiers = await notificationCenter.pendingIdentifiers().filter { $0.hasPrefix(prefix) }
        await notificationCenter.removePending(withIdentifiers: identifiers)
    }

    func cancelAll() async {
        let identifiers = await notificationCenter.pendingIdentifiers()
            .filter { $0.hasPrefix(HawlReminderPlanner.notificationPrefix) }
        await notificationCenter.removePending(withIdentifiers: identifiers)
    }
}
