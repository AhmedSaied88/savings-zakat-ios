import SwiftUI
import UniformTypeIdentifiers

struct EncryptedBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw BackupService.BackupError.invalidArchive
        }
        self.data = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct BackupSettingsView: View {
    @Binding var snapshot: FinanceSnapshot
    let onRestore: (FinanceSnapshot) -> Bool

    @State private var passphrase = ""
    @State private var confirmPassphrase = ""
    @State private var exportDocument: EncryptedBackupDocument?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var pendingRestore: FinanceSnapshot?
    @State private var showRestoreConfirmation = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Encrypted local backup") {
                    SecureField("Backup passphrase", text: $passphrase)
                        .textContentType(.newPassword)
                    SecureField("Confirm passphrase", text: $confirmPassphrase)
                        .textContentType(.newPassword)
                    Text("Use at least 12 characters. The passphrase is not saved by the app. Keep it somewhere safe; without it, the backup cannot be restored.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button {
                        createBackup()
                    } label: {
                        Label("Export encrypted backup", systemImage: "lock.doc")
                            .frame(minHeight: 44)
                    }
                    .disabled(passphrase.count < BackupService.minimumPassphraseLength ||
                              passphrase != confirmPassphrase)
                }

                Section("Restore from backup") {
                    Button {
                        showImporter = true
                    } label: {
                        Label("Choose backup file", systemImage: "folder")
                            .frame(minHeight: 44)
                    }
                    .disabled(passphrase.count < BackupService.minimumPassphraseLength)
                    Text("Restoring replaces the current local finance records after the archive is authenticated and you confirm the replacement.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("What is included") {
                    Label("Accounts, cards, transactions, liabilities and assets", systemImage: "checkmark.circle")
                    Label("Encrypted with PBKDF2-HMAC-SHA256 and AES-256-GCM", systemImage: "lock.fill")
                    Label("No automatic upload or cloud account", systemImage: "iphone")
                    Text("Pending bank-message review items, manual exchange rates, metal prices, Nisab settings and notification schedules are not included in this first backup version.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                if let statusMessage {
                    Section("Backup status") {
                        Text(statusMessage).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Backup & Restore")
            .fileExporter(
                isPresented: $showExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "savings-zakat-encrypted-backup"
            ) { result in
                switch result {
                case .success:
                    statusMessage = "Encrypted backup exported. Store the file and passphrase separately."
                    errorMessage = nil
                case .failure(let error):
                    errorMessage = "Could not export backup: \(error.localizedDescription)"
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                importSelectedFile(result)
            }
            .confirmationDialog(
                "Replace current local records?",
                isPresented: $showRestoreConfirmation,
                titleVisibility: .visible
            ) {
                Button("Replace local records", role: .destructive) {
                    restorePendingBackup()
                }
                Button("Cancel", role: .cancel) {
                    pendingRestore = nil
                }
            } message: {
                Text("This replaces the current accounts, cards, transactions, liabilities and assets with the contents of the selected encrypted backup. This cannot be undone from the app.")
            }
            .alert("Backup error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "An unknown backup error occurred.")
            }
        }
    }

    private func createBackup() {
        do {
            let data = try BackupService().exportBackup(snapshot: snapshot, passphrase: passphrase)
            exportDocument = EncryptedBackupDocument(data: data)
            showExporter = true
            errorMessage = nil
        } catch {
            errorMessage = backupErrorMessage(error)
        }
    }

    private func importSelectedFile(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess { url.stopAccessingSecurityScopedResource() }
            }
            let data = try Data(contentsOf: url)
            let restored = try BackupService().importBackup(data: data, passphrase: passphrase)
            pendingRestore = restored
            showRestoreConfirmation = true
            errorMessage = nil
            statusMessage = "Backup authenticated. Confirm replacement to restore its records."
        } catch {
            errorMessage = backupErrorMessage(error)
        }
    }

    private func restorePendingBackup() {
        guard let pendingRestore else { return }
        if onRestore(pendingRestore) {
            snapshot = pendingRestore
            statusMessage = "Backup restored to local storage."
            errorMessage = nil
        } else {
            errorMessage = "Could not save the restored records. Your current records were not intentionally replaced."
        }
        self.pendingRestore = nil
    }

    private func backupErrorMessage(_ error: Error) -> String {
        guard let backupError = error as? BackupService.BackupError else {
            return error.localizedDescription
        }
        switch backupError {
        case .weakPassphrase:
            return "Use a passphrase of at least 12 characters."
        case .invalidArchive:
            return "The selected file is not a valid Savings & Zakat backup."
        case .unsupportedBackupVersion(let version):
            return "This backup version (\(version)) is not supported by this app."
        case .unsupportedFinanceSchema(let version):
            return "The finance data schema (\(version)) is not supported by this app."
        case .invalidKDFParameters:
            return "The backup uses invalid or unsafe encryption parameters."
        case .keyDerivationFailed:
            return "The backup encryption key could not be derived."
        case .authenticationFailed:
            return "The passphrase is incorrect or the backup file has been modified."
        }
    }
}
