import CommonCrypto
import CryptoKit
import Foundation

struct BackupService {
    enum BackupError: Error, Equatable {
        case weakPassphrase
        case invalidArchive
        case unsupportedBackupVersion(Int)
        case unsupportedFinanceSchema(Int)
        case invalidKDFParameters
        case keyDerivationFailed
        case authenticationFailed
    }

    private struct Envelope: Codable {
        let backupVersion: Int
        let kdf: String
        let iterations: Int
        let salt: Data
        let nonce: Data
        let ciphertext: Data
        let tag: Data
    }

    static let currentBackupVersion = 1
    static let minimumPassphraseLength = 12
    static let pbkdf2Iterations = 210_000
    private static let minimumAllowedIterations = 100_000
    private static let maximumAllowedIterations = 500_000
    private static let maximumCiphertextBytes = 50 * 1024 * 1024
    private static let authenticatedContext = Data("SavingsZakat.EncryptedBackup.v1".utf8)

    func exportBackup(snapshot: FinanceSnapshot, passphrase: String) throws -> Data {
        try validatePassphrase(passphrase)
        guard snapshot.schemaVersion == FinanceSnapshot.currentSchemaVersion else {
            throw BackupError.unsupportedFinanceSchema(snapshot.schemaVersion)
        }

        let salt = Self.randomData(count: 16)
        let key = try deriveKey(passphrase: passphrase, salt: salt, iterations: Self.pbkdf2Iterations)
        let plaintext = try JSONEncoder.sorted.encode(snapshot)
        let sealed = try AES.GCM.seal(plaintext, using: key, authenticating: Self.authenticatedContext)
        let nonceData = sealed.nonce.withUnsafeBytes { Data($0) }

        let envelope = Envelope(
            backupVersion: Self.currentBackupVersion,
            kdf: "PBKDF2-HMAC-SHA256",
            iterations: Self.pbkdf2Iterations,
            salt: salt,
            nonce: nonceData,
            ciphertext: sealed.ciphertext,
            tag: sealed.tag
        )
        return try JSONEncoder.sorted.encode(envelope)
    }

    func importBackup(data: Data, passphrase: String) throws -> FinanceSnapshot {
        try validatePassphrase(passphrase)
        guard data.count <= Self.maximumCiphertextBytes + 16_384 else {
            throw BackupError.invalidArchive
        }

        let envelope: Envelope
        do {
            envelope = try JSONDecoder().decode(Envelope.self, from: data)
        } catch {
            throw BackupError.invalidArchive
        }

        guard envelope.backupVersion == Self.currentBackupVersion else {
            throw BackupError.unsupportedBackupVersion(envelope.backupVersion)
        }
        guard envelope.kdf == "PBKDF2-HMAC-SHA256",
              (Self.minimumAllowedIterations...Self.maximumAllowedIterations).contains(envelope.iterations),
              envelope.salt.count == 16,
              envelope.nonce.count == 12,
              envelope.tag.count == 16,
              envelope.ciphertext.count <= Self.maximumCiphertextBytes else {
            throw BackupError.invalidKDFParameters
        }

        let key = try deriveKey(passphrase: passphrase, salt: envelope.salt, iterations: envelope.iterations)
        do {
            let nonce = try AES.GCM.Nonce(data: envelope.nonce)
            let sealed = try AES.GCM.SealedBox(nonce: nonce, ciphertext: envelope.ciphertext, tag: envelope.tag)
            let plaintext = try AES.GCM.open(sealed, using: key, authenticating: Self.authenticatedContext)
            let snapshot = try JSONDecoder().decode(FinanceSnapshot.self, from: plaintext)
            guard snapshot.schemaVersion == FinanceSnapshot.currentSchemaVersion else {
                throw BackupError.unsupportedFinanceSchema(snapshot.schemaVersion)
            }
            return snapshot
        } catch let error as BackupError {
            throw error
        } catch {
            throw BackupError.authenticationFailed
        }
    }

    func writeBackup(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }

    private func validatePassphrase(_ passphrase: String) throws {
        guard passphrase.count >= Self.minimumPassphraseLength else {
            throw BackupError.weakPassphrase
        }
    }

    private func deriveKey(passphrase: String, salt: Data, iterations: Int) throws -> SymmetricKey {
        let password = Data(passphrase.utf8)
        var keyBytes = [UInt8](repeating: 0, count: 32)
        let status = keyBytes.withUnsafeMutableBufferPointer { keyBuffer in
            password.withUnsafeBytes { passwordBuffer in
                salt.withUnsafeBytes { saltBuffer in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBuffer.bindMemory(to: Int8.self).baseAddress!,
                        password.count,
                        saltBuffer.bindMemory(to: UInt8.self).baseAddress!,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        keyBuffer.baseAddress!,
                        keyBuffer.count
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw BackupError.keyDerivationFailed }
        return SymmetricKey(data: Data(keyBytes))
    }

    private static func randomData(count: Int) -> Data {
        var generator = SystemRandomNumberGenerator()
        return Data((0..<count).map { _ in UInt8.random(in: .min ... .max, using: &generator) })
    }
}

private extension JSONEncoder {
    static var sorted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
