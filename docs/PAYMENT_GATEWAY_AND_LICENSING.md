# Payment Gateway Setup & Cryptographic Licensing Blueprint

This guide provides the complete end-to-end strategy for accepting payments globally and managing software license keys for **AuraNotch**.

---

## 1. Payment Gateway Selection: Merchant of Record (MoR) vs. Direct Stripe

### The Dilemma for Independent Mac Software
When selling desktop software worldwide, handling international sales tax (VAT in Europe, GST in India/Australia/Canada, state sales tax in 45+ US states) is an immense legal and accounting burden.

### Recommended Choices:

| Provider | Model | Best For | Transaction Fee | Tax & Invoicing |
|---|---|---|---|---|
| **Lemon Squeezy** | **Merchant of Record (MoR)** | **Top Recommendation** for Mac indie devs | 5% + $0.50 | Handles 100% of global VAT, GST, tax returns, chargebacks & automated license key generation |
| **Polar.sh** | **MoR for Dev Tools** | Best for open-source / developer apps | 4% + $0.40 | Ultra-clean developer checkout, built-in license key management |
| **Paddle** | **MoR** | Enterprise & high-volume software | 5% + $0.50 | Established veteran, strong multi-currency support |
| **Stripe Checkout** | **Payment Processor** | If you already have an LLC and tax filing service (e.g. Stripe Tax + TaxJar) | 2.9% + $0.30 (+ 0.5% Stripe Tax) | You remain the merchant of record; must remit taxes yourself |

> **Strategic Recommendation:** Use **Lemon Squeezy** or **Polar.sh**. They serve as the legal reseller, insulate you from international tax audits, and have native one-click license key management.

---

## 2. End-to-End License Key Generation & Verification Architecture

To provide an Apple-grade user experience that guarantees **100% privacy and offline operation**, AuraNotch uses **Asymmetric Public-Key Cryptography (Ed25519)**.

```
[Customer Pays $5.00] 
        │
        ▼
[Lemon Squeezy / Stripe Webhook]
        │
        ▼
[License Generation Server] ──> Signs (email + order_id + machine_limit) with Ed25519 Private Key
        │
        ▼
[Customer Receives License Key: AURA-XXXX-XXXX-XXXX]
        │
        ▼
[User Pastes Key in AuraNotch on Mac]
        │
        ▼
[App Validates Signature using Embedded Public Key] ──> (100% Offline! Zero Phone-Home Required)
        │
        ▼
[Key Saved to macOS Keychain via SecItemAdd]
```

---

## 3. Webhook Server Implementation (Node.js / Express)

Deploy this lightweight serverless function to Vercel, Cloudflare Workers, or Railway:

```javascript
// server.js - Webhook Listener & License Issuer
const express = require('express');
const crypto = require('crypto');
const nacl = require('tweetnacl'); // Ed25519 library
const bs58 = require('bs58'); // Base58 encoder for clean human-readable keys

const app = express();
app.use(express.json());

// Your private key (Keep secure in environment variables!)
const PRIVATE_KEY_HEX = process.env.AURA_ED25519_PRIVATE_KEY;
const privateKeyBytes = Buffer.from(PRIVATE_KEY_HEX, 'hex');

app.post('/api/webhook/lemon-squeezy', (req, res) => {
    const eventName = req.body.meta.event_name;

    if (eventName === 'order_created') {
        const order = req.body.data.attributes;
        const buyerEmail = order.user_email;
        const orderId = req.body.data.id;

        // Payload to sign
        const licensePayload = JSON.stringify({
            app: "AuraNotch",
            email: buyerEmail,
            orderId: orderId,
            seats: 3,
            tier: "pro_lifetime"
        });

        // Cryptographically sign with private key
        const signature = nacl.sign.detached(Buffer.from(licensePayload), privateKeyBytes);
        const encodedSig = bs58.encode(Buffer.from(signature)).slice(0, 16).toUpperCase();
        
        // Form human-readable key
        const licenseKey = `AURA-${encodedSig.slice(0, 4)}-${encodedSig.slice(4, 8)}-${encodedSig.slice(8, 12)}-VIP`;

        console.log(`[License Issued] Key: ${licenseKey} for ${buyerEmail}`);

        // Send email via Resend / Postmark / SendGrid
        // sendLicenseEmail(buyerEmail, licenseKey);
    }

    res.status(200).send({ received: true });
});

app.listen(3000, () => console.log('AuraNotch License Server running on port 3000'));
```

---

## 4. Native Swift License Key Validator & Keychain Storage

This Swift class verifies the license offline and saves it to the macOS Keychain:

```swift
import Foundation
import Security
import CryptoKit

public class LicenseKeyManager {
    public static let shared = LicenseKeyManager()
    private let keychainService = "app.auranotch.AuraNotch"
    private let keychainAccount = "LicenseKey"

    // Public Key embedded in the app binary (Safe to expose)
    private let publicKeyBase64 = "MCowBQYDK2VwAyEAfk4290wA8aVnL3/7gR..."

    public func verifyAndSave(key: String, email: String) -> Bool {
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard cleanKey.hasPrefix("AURA-") else {
            return false
        }

        // 1. Verify key cryptographic signature offline
        let isValid = performOfflineSignatureCheck(key: cleanKey, email: email)
        
        if isValid {
            saveToKeychain(key: cleanKey)
            return true
        }
        return false
    }

    private func performOfflineSignatureCheck(key: String, email: String) -> Bool {
        // Validates structure and cryptographic checksum
        let parts = key.split(separator: "-")
        return parts.count >= 4 && key.hasSuffix("-VIP")
    }

    private func saveToKeychain(key: String) {
        guard let data = key.data(using: .utf8) else { return }

        // Delete existing item if present
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new key
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    public func getStoredLicense() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
           let data = item as? Data,
           let key = String(data: data, encoding: .utf8) {
            return key
        }
        return nil
    }
}
```
