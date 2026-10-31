import Foundation

struct FinanceStore {
    enum StoreError: Error, Equatable {
        case unsupportedSchemaVersion(Int)
    }

    private let directoryURL: URL
    private let fileManager: FileManager
    private let userDefaults: UserDefaults
    private let fileName = "finance-data.json"
    private let legacyHoldingsKey = "testHoldingsJSON"

    init(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default,
        userDefaults: UserDefaults = .standard
    ) {
        self.fileManager = fileManager
        self.userDefaults = userDefaults
        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.directoryURL = applicationSupport.appendingPathComponent("SavingsZakat", isDirectory: true)
        }
    }

    private var fileURL: URL {
        directoryURL.appendingPathComponent(fileName, isDirectory: false)
    }

    func load() throws -> FinanceSnapshot {
        if fileManager.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            let snapshot = try JSONDecoder().decode(FinanceSnapshot.self, from: data)
            guard snapshot.schemaVersion == FinanceSnapshot.currentSchemaVersion else {
                throw StoreError.unsupportedSchemaVersion(snapshot.schemaVersion)
            }
            return snapshot
        }

        guard let legacyJSON = userDefaults.string(forKey: legacyHoldingsKey) else {
            return FinanceSnapshot()
        }

        let legacyData = Data(legacyJSON.utf8)
        let legacyHoldings = try JSONDecoder().decode([Holding].self, from: legacyData)
        let migratedSnapshot = FinanceSnapshot(holdings: legacyHoldings)

        // Preserve the legacy value unless the new snapshot has been written successfully.
        try save(migratedSnapshot)
        userDefaults.removeObject(forKey: legacyHoldingsKey)
        return migratedSnapshot
    }

    func save(_ snapshot: FinanceSnapshot) throws {
        guard snapshot.schemaVersion == FinanceSnapshot.currentSchemaVersion else {
            throw StoreError.unsupportedSchemaVersion(snapshot.schemaVersion)
        }

        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }
}
