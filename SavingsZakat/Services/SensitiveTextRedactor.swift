import Foundation

enum SensitiveTextRedactor {
    static func redact(_ text: String) -> String {
        var safe = normalizeDigits(in: text)
        let patterns = [
            #"(?i)\b(?:otp|one[- ]time password|cvv|cvc|pin|verification code|security code|passcode)\s*[:#-]?\s*[A-Z0-9!@#$%^&*_-]{3,32}\b"#,
            #"(?i)\b(?:password|banking password)\s*[:#-]?\s*[A-Z0-9!@#$%^&*_-]{4,32}\b"#,
            #"(?:رمز التحقق|كود التحقق|رمز التأكيد|رمز الدخول|كلمة المرور لمرة واحدة|كلمة المرور|كلمة السر|الرقم السري)\s*[:#-]?\s*[\p{L}\p{M}\p{N}!@#$%^&*_-]{3,32}(?![\p{L}\p{M}\p{N}])"#,
            #"(?<!\d)(?:\d[ -]?){12,19}(?!\d)"#
        ]
        for pattern in patterns {
            safe = safe.replacingOccurrences(of: pattern, with: "[REDACTED]", options: .regularExpression)
        }
        return safe
    }

    static func normalizeDigits(in text: String) -> String {
        let replacements: [Character: Character] = [
            "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
            "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9",
            "۰": "0", "۱": "1", "۲": "2", "۳": "3", "۴": "4",
            "۵": "5", "۶": "6", "۷": "7", "۸": "8", "۹": "9"
        ]
        return String(text.map { replacements[$0] ?? $0 })
            .replacingOccurrences(of: "٫", with: ".")
            .replacingOccurrences(of: "٬", with: ",")
    }
}
