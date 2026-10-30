import SwiftUI

private struct HawlCalendarEntry: Identifiable {
    let holding: Holding
    let due: HawlDueDate
    var id: UUID { holding.id }
}

struct HawlCalendarView: View {
    let holdings: [Holding]

    @State private var reminderStatus: String?
    @State private var isUpdatingReminders = false

    private let scheduler = HawlNotificationScheduler()

    private var upcoming: [HawlCalendarEntry] {
        holdings.compactMap { holding in
            guard let due = HawlCalculator.dueDateResult(startDate: holding.hawlStartDate) else { return nil }
            return HawlCalendarEntry(holding: holding, due: due)
        }
        .sorted { $0.due.date < $1.due.date }
    }

    var body: some View {
        List {
            Section("Upcoming Hawl dates") {
                if upcoming.isEmpty {
                    ContentUnavailableView("No Hawl dates", systemImage: "calendar",
                                           description: Text("Add an asset with a Gregorian Hawl start date to see its anniversary here."))
                } else {
                    ForEach(upcoming) { item in
                        upcomingRow(item)
                    }
                }
            }

            Section("Local reminders") {
                Text("Four reminders are planned for 30, 7 and 1 day before Hawl, and on the due date. They are scheduled for 9:00 AM local time on the corresponding Cairo civil date. Refresh reminders after adding an asset or correcting its dates; deleting an asset cancels its pending reminders.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button {
                    Task { await scheduleReminders() }
                } label: {
                    if isUpdatingReminders {
                        HStack { ProgressView(); Text("Updating reminders…") }
                    } else {
                        Label("Schedule / refresh reminders", systemImage: "bell.badge")
                    }
                }
                .disabled(isUpdatingReminders || holdings.isEmpty)
                .accessibilityIdentifier("schedule-hawl-reminders")
                Button(role: .destructive) {
                    Task {
                        await scheduler.cancelAll()
                        reminderStatus = "All pending Hawl reminders were cancelled."
                    }
                } label: {
                    Label("Cancel all Hawl reminders", systemImage: "bell.slash")
                }
                if let reminderStatus {
                    Text(reminderStatus).font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section {
                Text("Reminder delivery depends on iOS notification permission, device settings and the phone being available. Dates based on incomplete Egyptian official coverage remain Estimated.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Hawl calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func upcomingRow(_ item: HawlCalendarEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(assetName(item.holding)).font(.headline)
            Text("Hawl start: \(item.holding.hawlStartDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption).foregroundStyle(.secondary)
            Text("Due: \(item.due.date.formatted(date: .long, time: .omitted))")
                .font(.subheadline.weight(.semibold))
            Text(hijriLabel(for: item.due.date, status: item.due.status))
                .font(.caption)
                .foregroundStyle(item.due.status == .officiallyConfirmed ? Color.secondary : Color.orange)
            Text(countdown(to: item.due.date))
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }

    private func scheduleReminders() async {
        isUpdatingReminders = true
        defer { isUpdatingReminders = false }
        do {
            switch try await scheduler.schedule(holdings: holdings, timeZone: .current) {
            case .permissionDenied:
                reminderStatus = "Notifications are not permitted. Enable them in iPhone Settings to receive Hawl reminders."
            case .scheduled(let count):
                reminderStatus = count == 0 ? "No future reminder dates need scheduling." : "Scheduled \(count) local reminders."
            case .partiallyScheduled(let count, let failed):
                reminderStatus = "Scheduled \(count) reminders; \(failed.count) could not be added. Try refreshing."
            case .limited(let count, let omittedCount):
                reminderStatus = "Scheduled \(count) reminders. \(omittedCount) later reminders were omitted because of the iOS pending-notification limit."
            }
        } catch {
            reminderStatus = "Could not schedule reminders: \(error.localizedDescription)"
        }
    }

    private func assetName(_ holding: Holding) -> String {
        switch holding.kind {
        case .cash: return "Cash · \(holding.currency ?? "EGP")"
        case .gold: return "Gold · \(holding.carat ?? 24)K · \(holding.grams ?? holding.amount) g"
        case .silver: return "Silver · \(holding.purity ?? 999)‰ · \(holding.grams ?? holding.amount) g"
        case .investment: return holding.name ?? "Investment"
        }
    }

    private func countdown(to date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Africa/Cairo") ?? .current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()),
                                           to: calendar.startOfDay(for: date)).day ?? 0
        if days < 0 { return "Hawl completed \(-days) days ago" }
        if days == 0 { return "Hawl is due today" }
        return "\(days) days remaining"
    }

    private func hijriLabel(for date: Date, status: HijriDateStatus) -> String {
        guard let hijri = EgyptianCalendarRepository.makeCalendar().convert(date) else {
            return "Hijri equivalent unavailable"
        }
        let monthNames = ["", "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
                          "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
                          "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"]
        let month = (1...12).contains(hijri.hijriMonth) ? monthNames[hijri.hijriMonth] : "Month \(hijri.hijriMonth)"
        if status == .officiallyConfirmed && hijri.status == .officiallyConfirmed {
            return "Egyptian Hijri: \(hijri.hijriDay) \(month) \(hijri.hijriYear) · Confirmed"
        }
        return "Hijri estimate: \(hijri.hijriDay) \(month) \(hijri.hijriYear) · Not an official Egyptian date"
    }
}
