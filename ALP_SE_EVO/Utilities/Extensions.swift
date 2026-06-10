import Foundation
import SwiftUI
import CoreImage

// MARK: - Date Extensions

extension Date {
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }
    
    func isTomorrow() -> Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    func timeUntilNow() -> String {
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: self, to: Date())
        
        if let days = components.day, days > 0 {
            return "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - String Extensions

extension String {
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: self)
    }
    
    func isValidPassword() -> Bool {
        return self.count >= 6
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst().lowercased()
    }
}

// MARK: - Color Extensions

extension Color {
    // MARK: Solid Light Blue Theme (no gradients)
    
    // Primary solid light blue — #87CEFA — used on main headers, buttons, nav bars
    static let appPrimary    = Color(red: 0.529, green: 0.808, blue: 0.980) // #87CEFA
    
    // Darker accent for icons, labels, active states — #4A90D9
    static let appAccent     = Color(red: 0.290, green: 0.565, blue: 0.851) // #4A90D9
    
    // Deep blue for important text on light bg — #1A5E8C
    static let appDeep       = Color(red: 0.102, green: 0.369, blue: 0.549) // #1A5E8C
    
    // Background: very pale icy blue — #EEF6FD
    static let appBackground = Color(red: 0.933, green: 0.965, blue: 0.992) // #EEF6FD
    
    // Card surfaces: barely-blue white — #F5FAFF
    static let appCard       = Color(red: 0.961, green: 0.980, blue: 1.000) // #F5FAFF
    
    // Text on light backgrounds
    static let appTextPrimary   = Color(red: 0.10, green: 0.20, blue: 0.35)   // near-dark navy
    static let appTextSecondary = Color(red: 0.40, green: 0.55, blue: 0.68)   // muted steel-blue
    
    // Icon tint / separator / divider
    static let appIconTint   = Color(red: 0.290, green: 0.565, blue: 0.851) // same as appAccent
    static let appDivider    = Color(red: 0.75, green: 0.88, blue: 0.97)
    
    // Status colors (kept solid, paired with light bg for readability)
    static let appGreen      = Color(red: 0.18, green: 0.70, blue: 0.45)
    static let appOrange     = Color(red: 0.95, green: 0.55, blue: 0.15)
    static let appRed        = Color(red: 0.85, green: 0.22, blue: 0.22)
    
    // Legacy aliases (kept so existing references compile without changes)
    static let appLightBlue  = Color(red: 0.529, green: 0.808, blue: 0.980)
    static let appMediumBlue = Color(red: 0.290, green: 0.565, blue: 0.851)
    static let appDarkBlue   = Color(red: 0.102, green: 0.369, blue: 0.549)
    static let appCardBg     = Color(red: 0.961, green: 0.980, blue: 1.000)
    static let darkStart     = Color(red: 0.102, green: 0.369, blue: 0.549)
    static let darkEnd       = Color(red: 0.10, green: 0.20, blue: 0.35)
    static let lightStart    = Color(red: 0.933, green: 0.965, blue: 0.992)
    static let lightEnd      = Color(red: 0.933, green: 0.965, blue: 0.992)
}

// MARK: - Double Extensions

extension Double {
    func formatDecimal(_ style: NumberFormatter.Style = .decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - Codable Extensions

extension JSONDecoder {
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }()
}

extension JSONEncoder {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return encoder
    }()
}

// MARK: - UIScreen Extensions

extension UIScreen {
    static let hasNotch: Bool = {
        let bottom = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .safeAreaInsets
            .bottom ?? 0
        return bottom > 0
    }()
}

// MARK: - Validation Helpers

struct ValidationHelper {
    static func validateEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(email.startIndex..., in: email)
        return regex?.firstMatch(in: email, range: range) != nil
    }
    
    static func validatePassword(_ password: String) -> Bool {
        // Minimum 6 characters
        return password.count >= 6
    }
    
    static func validatePhone(_ phone: String) -> Bool {
        // Simple validation: at least 10 digits
        let digits = phone.filter { $0.isNumber }
        return digits.count >= 10
    }
}

// MARK: - Formatting Helpers

struct FormattingHelper {
    static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: NSNumber(value: amount)) ?? "Rp \(amount)"
    }
    
    static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: date)
    }
    
    static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: date)
    }
    
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: date)
    }
}

// MARK: - Error Handling

enum AppError: LocalizedError {
    case invalidInput(String)
    case networkError(String)
    case authenticationError(String)
    case firebaseError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid Input: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .firebaseError(let message):
            return "Database Error: \(message)"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
}

// MARK: - Logger

struct Logger {
    static func log(_ message: String, level: String = "INFO") {
        #if DEBUG
        let timestamp = DateFormatter().string(from: Date())
        print("[\(timestamp)] [\(level)] \(message)")
        #endif
    }
    
    static func error(_ message: String) {
        Log.log(message, level: "ERROR")
    }
    
    static func warning(_ message: String) {
        Log.log(message, level: "WARNING")
    }
}

typealias Log = Logger

// MARK: - QR Code Generation

extension String {
    func generateQRCode() -> UIImage? {
        let data = self.data(using: .ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("M", forKey: "inputCorrectionLevel")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            if let outputImage = filter.outputImage?.transformed(by: transform) {
                let context = CIContext()
                if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        return nil
    }
}
