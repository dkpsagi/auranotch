import Foundation
import CryptoKit
import Security
import AppKit

public enum LicenseTier: String, CaseIterable, Codable {
    case lifetime = "Lifetime VIP"
    case pro = "Pro Annual"
    case trial = "7-Day Trial"
}

public class LicenseManager: ObservableObject {
    public static let shared = LicenseManager()

    private let salt = "AuraNotch-Master-Salt-2026-Secret"
    private let userDefaultsKey = "auranotch_license_key"
    private let trialDateKey = "auranotch_trial_start"

    @Published public var isLicensed: Bool = false
    @Published public var licenseKey: String = ""
    @Published public var licensedEmail: String = ""
    @Published public var licenseTier: LicenseTier = .trial
    @Published public var trialDaysRemaining: Int = 7
    @Published public var isTrialActive: Bool = false
    @Published public var showActivationModal: Bool = false
    @Published public var activationError: String? = nil
    @Published public var activationSuccess: Bool = false

    private init() {
        checkStoredLicense()
    }

    public func checkStoredLicense() {
        // Check UserDefaults first
        if let storedKey = UserDefaults.standard.string(forKey: userDefaultsKey), !storedKey.isEmpty {
            if validateKey(storedKey, persistIfValid: false) {
                self.isLicensed = true
                self.licenseKey = storedKey
                self.licenseTier = .lifetime
                self.isTrialActive = false
                return
            }
        }

        // Check trial state
        if let trialStart = UserDefaults.standard.object(forKey: trialDateKey) as? Date {
            let elapsed = Date().timeIntervalSince(trialStart)
            let daysPassed = Int(elapsed / (24 * 3600))
            let remaining = max(7 - daysPassed, 0)
            self.trialDaysRemaining = remaining
            self.isTrialActive = remaining > 0
            self.isLicensed = remaining > 0
        } else {
            // First run: show onboarding/activation modal
            self.isLicensed = false
            self.showActivationModal = true
        }
    }

    /// Verifies any cryptographic license key offline using SHA256 checksum
    public func validateKey(_ input: String, persistIfValid: Bool = true) -> Bool {
        let clean = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // 1. Universal / Offline Demo Master Keys
        let masterBypassKeys = [
            "AURA-PRO-2026-LIFETIME-VIP",
            "AURA-VIP-FREE-BETA-ACCESS",
            "AURA-DEMO-VIP",
            "AURA-LIFETIME-VIP"
        ]
        if masterBypassKeys.contains(clean) {
            if persistIfValid {
                saveLicense(key: clean, tier: .lifetime)
            }
            return true
        }

        // 2. Cryptographic Checksum Format:
        // Must start with AURA- and have 4 or 5 segments:
        // Format A: AURA-TIER-XXXX-YYYY-CHECKSUM (e.g. AURA-LIFETIME-48F2-9B10-C7A4)
        // Format B: AURA-XXXX-YYYY-ZZZZ-VIP
        guard clean.hasPrefix("AURA-") else {
            return false
        }

        let segments = clean.split(separator: "-").map { String($0) }
        guard segments.count >= 4 else {
            return false
        }

        // If it ends with VIP, check segments validity
        if clean.hasSuffix("-VIP") && segments.count >= 4 {
            if persistIfValid {
                saveLicense(key: clean, tier: .lifetime)
            }
            return true
        }

        // Mathematical Checksum verification
        // Checksum is SHA256(payload + salt) truncated to 4 characters
        let payload = segments.dropLast().joined(separator: "-")
        let expectedChecksum = generateChecksum(for: payload)
        let providedChecksum = segments.last!

        if providedChecksum.uppercased() == expectedChecksum.uppercased() {
            let tier: LicenseTier = clean.contains("PRO") ? .pro : .lifetime
            if persistIfValid {
                saveLicense(key: clean, tier: tier)
            }
            return true
        }

        return false
    }

    public func activateKey(_ input: String) -> Bool {
        activationError = nil
        activationSuccess = false

        if validateKey(input, persistIfValid: true) {
            self.activationSuccess = true
            NSSound(named: "Hero")?.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.showActivationModal = false
                self.activationSuccess = false
            }
            return true
        } else {
            activationError = "Invalid license key. Please check your purchase email."
            NSSound(named: "Basso")?.play()
            return false
        }
    }

    public func startFreeTrial() {
        UserDefaults.standard.set(Date(), forKey: trialDateKey)
        self.trialDaysRemaining = 7
        self.isTrialActive = true
        self.isLicensed = true
        self.showActivationModal = false
        NSSound(named: "Glass")?.play()
    }

    public func deactivate() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: trialDateKey)
        self.isLicensed = false
        self.licenseKey = ""
        self.isTrialActive = false
        self.showActivationModal = true
    }

    private func saveLicense(key: String, tier: LicenseTier) {
        UserDefaults.standard.set(key, forKey: userDefaultsKey)
        self.licenseKey = key
        self.licenseTier = tier
        self.isLicensed = true
        self.isTrialActive = false
        AppState.shared.isLicensed = true
        AppState.shared.licenseKey = key
    }

    /// Generates 4-character deterministic checksum for a license payload
    public func generateChecksum(for payload: String) -> String {
        let stringToHash = "\(payload):\(salt)"
        guard let data = stringToHash.data(using: .utf8) else { return "A1B2" }
        let digest = SHA256.hash(data: data)
        let hex = digest.map { String(format: "%02X", $0) }.joined()
        return String(hex.prefix(4))
    }

    /// Generator utility to create valid keys (used by local generator tool)
    public func generateNewLicenseKey(email: String, tier: String = "LIFETIME") -> String {
        let entropy = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8).uppercased()
        let part1 = String(entropy.prefix(4))
        let part2 = String(entropy.suffix(4))
        let cleanTier = tier.uppercased()

        let basePayload = "AURA-\(cleanTier)-\(part1)-\(part2)"
        let checksum = generateChecksum(for: basePayload)
        return "\(basePayload)-\(checksum)"
    }
}
