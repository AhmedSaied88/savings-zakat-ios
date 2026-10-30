import Foundation

struct FinanceStore {
    enum StoreError: Error, Equatable {
        case unsupportedSchemaVersion(Int)
    }

    private let directoryURL: URL
    private let fileManager: FileManager
    private let fileName = "finance-data.json"

    init(directoryURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
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
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return FinanceSnapshot()
        }

        let data = try Data(contentsOf: fileURL)
        let snapshot = try JSONDecoder().decode(FinanceSnapshot.self, from: data)
        guard snapshot.schemaVersion == FinanceSnapshot.currentSchemaVersion else {
            throw StoreError.unsupportedSchemaVersion(snapshot.schemaVersion)
        }
        return snapshot
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
