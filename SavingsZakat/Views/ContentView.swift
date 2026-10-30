import SwiftUI

struct ContentView: View {
    @State private var snapshot = FinanceSnapshot()
    @State private var rates: [String: Double] = ["EGP": 1]
    @State private var storageError: String?

    private let store = FinanceStore()

    var body: some View {
        TabView {
            WalletDashboardTab(snapshot: snapshot, rates: rates)
                .tabItem { Label("Wallet", systemImage: "wallet.bifold") }
            AccountsCardsTab(snapshot: $snapshot, onSave: save)
                .tabItem { Label("Accounts", systemImage: "building.columns") }
            TransactionsTab(snapshot: $snapshot, onSave: save)
                .tabItem { Label("Activity", systemImage: "arrow.left.arrow.right") }
            DebtsTab(snapshot: $snapshot, onSave: save)
                .tabItem { Label("Debts", systemImage: "doc.text") }
            AssetsZakatTab(snapshot: $snapshot, rates: $rates, onSave: save)
                .tabItem { Label("Zakat", systemImage: "sparkles") }
        }
        .tint(Color(red: 0.12, green: 0.34, blue: 0.78))
        .task { load() }
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
        do {
            snapshot = try store.load()
            storageError = nil
        } catch {
            storageError = "Could not read saved finance data: \(error.localizedDescription)"
        }
    }

    private func save() {
        do {
            try store.save(snapshot)
            storageError = nil
        } catch {
            storageError = "Could not save finance data: \(error.localizedDescription)"
        }
    }
}
