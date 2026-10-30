import AppIntents
import Foundation

@available(iOS 17.0, *)
struct ImportBankMessageIntent: AppIntent {
    static var title: LocalizedStringResource = "Import Bank Message"
    static var description = IntentDescription("Safely imports a bank notification for review in Savings & Zakat.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Message text")
    var messageText: String

    @Parameter(title: "Sender identifier", default: "Unknown")
    var senderIdentifier: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let coordinator = MessageImportCoordinator()
        let customRules = (try? FinanceStore().load().preferences?.enabledBankMessageRules) ?? []
        switch try coordinator.importMessage(
            text: messageText,
            senderIdentifier: senderIdentifier,
            receivedAt: Date(),
            customRules: customRules
        ) {
        case .imported:
            return .result(dialog: "Message added to Savings & Zakat. Review it before adding it to your accounts.")
        case .duplicate:
            return .result(dialog: "This message was already received recently. No duplicate was added.")
        }
    }
}

@available(iOS 17.0, *)
struct SavingsZakatShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ImportBankMessageIntent(),
            phrases: [
                "Import bank message into \(.applicationName)",
                "Review bank message in \(.applicationName)"
            ],
            shortTitle: "Import bank message",
            systemImageName: "message.badge.filled"
        )
    }
}
