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
            AssetsZakatTab(snapshot: $snapshot, onSave: save, preferences: $preferences)
                .tabItem { Label("Zakat", systemImage: "sparkles") }
        }
        .tint(FinancePalette.royalBlue)
        .background(FinancePalette.canvas.ignoresSafeArea())
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
            if ProcessInfo.processInfo.arguments.contains("-ui-testing-populated"),
               uiTestDirectory != nil {
                try store.save(makeVisualReviewSnapshot())
            }
            snapshot = try store.load()
            preferences = snapshot.preferences ?? FinancePreferences()
            storageError = nil
            loadImportedMessages()
        } catch {
            storageError = "Could not read saved finance data: \(error.localizedDescription)"
        }
    }

    /// Fictional, isolated data used only by the simulator screenshot review.
    /// The UI-test store lives in the temporary directory and never touches app data.
    private func makeVisualReviewSnapshot() -> FinanceSnapshot {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let twoYearsAgo = calendar.date(byAdding: .year, value: -2, to: today) ?? today
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today) ?? today
        let dueDate = calendar.date(byAdding: .day, value: 12, to: today) ?? today

        let bank = FinanceAccount(
            name: "Main Bank",
            institution: "Example Bank",
            kind: .bank,
            currency: "EGP",
            openingBalance: Decimal(string: "42500")!
        )
        let wallet = FinanceAccount(
            name: "Daily Wallet",
            kind: .wallet,
            currency: "EGP",
            openingBalance: Decimal(string: "2800")!
        )
        let creditCard = FinanceCard(
            name: "Everyday Credit",
            issuer: "Example Bank",
            kind: .credit,
            lastFour: "4821",
            linkedAccountID: bank.id,
            creditLimit: Decimal(string: "60000"),
            paymentDueDate: dueDate,
            minimumDue: Decimal(string: "2400"),
            currency: "EGP",
            openingOutstandingBalance: Decimal(string: "8750")
        )
        let income = FinanceTransaction(
            title: "Monthly salary",
            amount: Decimal(string: "32000")!,
            currency: "EGP",
            direction: .income,
            date: today,
            accountID: bank.id,
            category: "Salary"
        )
        let expense = FinanceTransaction(
            title: "Groceries",
            amount: Decimal(string: "1850")!,
            currency: "EGP",
            direction: .expense,
            date: today,
            accountID: bank.id,
            category: "Food"
        )
        let loan = FinanceLiability(
            name: "Personal loan",
            kind: .loan,
            outstandingAmount: Decimal(string: "45000")!,
            currency: "EGP",
            dueDate: dueDate
        )
        let cashHolding = Holding(
            id: UUID(), kind: .cash, amount: 18_000, currency: "EGP", grams: nil, carat: nil,
            acquiredDate: twoYearsAgo, hawlStartDate: twoYearsAgo, purpose: .investment
        )
        let goldHolding = Holding(
            id: UUID(), kind: .gold, amount: 12, currency: nil, grams: 12, carat: 21,
            acquiredDate: twoYearsAgo, hawlStartDate: twoYearsAgo, purpose: .investment
        )
        let silverHolding = Holding(
            id: UUID(), kind: .silver, amount: 150, currency: nil, grams: 150, carat: nil,
            acquiredDate: oneYearAgo, hawlStartDate: oneYearAgo, purpose: .investment,
            name: "Silver bars", purity: 999
        )
        let investmentHolding = Holding(
            id: UUID(), kind: .investment, amount: 8_000, currency: "EGP", grams: nil, carat: nil,
            acquiredDate: twoYearsAgo, hawlStartDate: twoYearsAgo, purpose: .investment,
            name: "Long-term investment"
        )
        let samplePreferences = FinancePreferences(
            exchangeRatesToEGP: ["EGP": 1, "USD": 50],
            goldPricesPerGramEGP: ["24": 5_900, "22": 5_400, "21": 5_150, "18": 4_420, "14": 3_450],
            silverPricePerGramEGP: 82,
            nisabEGP: 30_000
        )
        return FinanceSnapshot(
            accounts: [bank, wallet],
            cards: [creditCard],
            transactions: [income, expense],
            liabilities: [loan],
            holdings: [cashHolding, goldHolding, silverHolding, investmentHolding],
            preferences: samplePreferences
        )
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
