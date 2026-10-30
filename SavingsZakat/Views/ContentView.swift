import SwiftUI
import Combine

struct ContentView: View {
    @State private var snapshot = FinanceSnapshot()
    @State private var importedMessages: [ImportedMessage] = []
    @State private var preferences = FinancePreferences()
    @State private var storageError: String?

    private let store: FinanceStore
    private let importCoordinator: MessageImportCoordinator
    private let uiTestDirectory: URL?

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        let directory = isUITesting
            ? FileManager.default.temporaryDirectory.appendingPathComponent("SavingsZakatUITests", isDirectory: true)
            : nil
        self.uiTestDirectory = directory
        self.store = FinanceStore(directoryURL: directory)
        let queueURL = directory?.appendingPathComponent("imported-messages.json")
        self.importCoordinator = MessageImportCoordinator(queueURL: queueURL)
    }

    var body: some View {
        TabView {
            WalletDashboardTab(snapshot: $snapshot, preferences: $preferences, onSave: save, onRestore: restoreSnapshot)
                .tabItem { Label("Wallet", systemImage: "wallet.bifold") }
            AccountsCardsTab(snapshot: $snapshot, onSave: save)
                .tabItem { Label("Accounts", systemImage: "building.columns") }
            TransactionsTab(
                snapshot: $snapshot,
                importedMessages: $importedMessages,
                onSave: save,
                onSaveConfirmedTransaction: saveConfirmedTransaction,
                onSaveImports: saveImportedMessages,
                onRefreshImports: loadImportedMessages
            )
                .tabItem { Label("Activity", systemImage: "arrow.left.arrow.right") }
            DebtsTab(snapshot: $snapshot, onSave: save)
                .tabItem { Label("Debts", systemImage: "doc.text") }
            AssetsZakatTab(snapshot: $snapshot, preferences: $preferences, onSave: save)
                .tabItem { Label("Zakat", systemImage: "sparkles") }
        }
        .tint(Color(red: 0.12, green: 0.34, blue: 0.78))
        .task { load() }
        .onReceive(NotificationCenter.default.publisher(for: .bankMessageImportDidChange)) { _ in
            loadImportedMessages()
        }
        .alert("Local storage", isPresented: Binding(
            get: { storageError != nil },
            set: { if !$0 { storageError = nil } }
        )) {
            Button("OK", role: .cancel) { storageError = nil }
        } message: {
            Text(storageError ?? "An unknown storage error occurred.")
        }
    }

    private func load() {
        if ProcessInfo.processInfo.arguments.contains("-ui-testing-reset"),
           let uiTestDirectory {
            try? FileManager.default.removeItem(at: uiTestDirectory.appendingPathComponent("finance-data.json"))
            try? FileManager.default.removeItem(at: uiTestDirectory.appendingPathComponent("imported-messages.json"))
            UserDefaults.standard.removeObject(forKey: "testHoldingsJSON")
        }
        do {
            snapshot = try store.load()
            preferences = snapshot.preferences ?? FinancePreferences()
            storageError = nil
            loadImportedMessages()
        } catch {
            storageError = "Could not read saved finance data: \(error.localizedDescription)"
        }
    }

    private func loadImportedMessages() {
        do {
            importedMessages = try importCoordinator.loadMessages()
        } catch {
            storageError = "Could not read imported bank messages: \(error.localizedDescription)"
        }
    }

    private func restoreSnapshot(_ restored: FinanceSnapshot) -> Bool {
        do {
            var snapshotToRestore = restored
            snapshotToRestore.preferences = restored.preferences ?? FinancePreferences()
            try store.save(snapshotToRestore)
            snapshot = snapshotToRestore
            preferences = snapshotToRestore.preferences ?? FinancePreferences()
            storageError = nil
            return true
        } catch {
            storageError = "Could not restore finance data: \\(error.localizedDescription)"
            return false
        }
    }

    private func saveConfirmedTransaction() -> Bool {
        do {
            snapshot.preferences = preferences
            try store.save(snapshot)
            storageError = nil
            return true
        } catch {
            storageError = "Could not save confirmed transaction: \\(error.localizedDescription)"
            return false
        }
    }

    private func saveImportedMessages() {
        do {
            try importCoordinator.saveMessages(importedMessages)
            storageError = nil
        } catch {
            storageError = "Could not save imported bank messages: \(error.localizedDescription)"
        }
    }

    private func save() {
        do {
            snapshot.preferences = preferences
            try store.save(snapshot)
            storageError = nil
        } catch {
            storageError = "Could not save finance data: \(error.localizedDescription)"
        }
    }
}
