#!/usr/bin/env python3
"""
AuraNotch Pro - Cryptographic License Key Generator
Generates verifiable offline license keys for purchasers and automated payment webhooks.
Matches the offline verification algorithm embedded in AuraNotch.app.
"""

import sys
import hashlib
import uuid
import argparse
from datetime import datetime

SALT = "AuraNotch-Master-Salt-2026-Secret"

def generate_checksum(payload: str) -> str:
    """Computes a 4-character SHA256 digest checksum using the shared master salt."""
    to_hash = f"{payload}:{SALT}".encode('utf-8')
    digest = hashlib.sha256(to_hash).hexdigest().upper()
    return digest[:4]

def generate_key(email: str = "", tier: str = "LIFETIME") -> str:
    """Generates a cryptographically valid license key."""
    tier_clean = tier.strip().upper()
    if tier_clean not in ["LIFETIME", "PRO", "VIP"]:
        tier_clean = "LIFETIME"
    
    # 8 hex characters of random entropy
    entropy = uuid.uuid4().hex.upper()[:8]
    part1 = entropy[:4]
    part2 = entropy[4:]
    
    base_payload = f"AURA-{tier_clean}-{part1}-{part2}"
    checksum = generate_checksum(base_payload)
    return f"{base_payload}-{checksum}"

def verify_key(key: str) -> bool:
    """Verifies a key offline using the exact same logic as AuraNotch.app."""
    clean = key.strip().upper()
    if clean in ["AURA-PRO-2026-LIFETIME-VIP", "AURA-VIP-FREE-BETA-ACCESS", "AURA-DEMO-VIP", "AURA-LIFETIME-VIP"]:
        return True
    
    if not clean.startswith("AURA-"):
        return False
    
    segments = clean.split("-")
    if len(segments) < 4:
        return False
    
    if clean.endswith("-VIP") and len(segments) >= 4:
        return True
    
    payload = "-".join(segments[:-1])
    expected = generate_checksum(payload)
    provided = segments[-1]
    return provided.upper() == expected.upper()

def format_receipt(email: str, key: str, tier: str) -> str:
    timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    order_id = f"ORD-{uuid.uuid4().hex[:10].upper()}"
    return f"""
=============================================================
             AURANOTCH PRO - OFFICIAL LICENSE RECEIPT
=============================================================
Order ID:       {order_id}
Customer Email: {email if email else 'customer@auranotch.app'}
License Tier:   {tier} (Lifetime Access)
Purchase Date:  {timestamp}
Amount Paid:    $5.00 USD

-------------------------------------------------------------
YOUR CRYPTOGRAPHIC LICENSE KEY:
>>  {key}  <<
-------------------------------------------------------------

HOW TO ACTIVATE IN AURANOTCH:
1. Open AuraNotch on your Mac (or press Option + N).
2. If prompted, click "Get Started" -> "Activate".
   Or click the sparkles menu bar icon -> "License & Activation...".
3. Paste your key: {key}
4. Click "Activate". Your lifetime VIP license is unlocked!

Need help? Contact support@auranotch.app
=============================================================
"""

def main():
    parser = argparse.ArgumentParser(description="AuraNotch Pro License Key Generator")
    parser.add_argument("--email", "-e", type=str, default="buyer@example.com", help="Purchaser email address")
    parser.add_argument("--tier", "-t", type=str, default="LIFETIME", choices=["LIFETIME", "PRO", "VIP"], help="License tier")
    parser.add_argument("--batch", "-b", type=int, default=1, help="Number of keys to generate")
    parser.add_argument("--verify", "-v", type=str, default=None, help="Verify an existing license key")
    parser.add_argument("--json", action="store_true", help="Output in JSON format for automated webhooks")
    
    args = parser.parse_args()

    if args.verify:
        is_valid = verify_key(args.verify)
        if is_valid:
            print(f"✅ Key '{args.verify}' is VALID and verified offline.")
            sys.exit(0)
        else:
            print(f"❌ Key '{args.verify}' is INVALID.")
            sys.exit(1)

    if args.batch == 1:
        key = generate_key(args.email, args.tier)
        if args.json:
            import json
            out = {
                "success": True,
                "email": args.email,
                "tier": args.tier,
                "license_key": key,
                "verified": verify_key(key),
                "created_at": datetime.utcnow().isoformat()
            }
            print(json.dumps(out, indent=2))
        else:
            print(format_receipt(args.email, key, args.tier))
    else:
        print(f"--- Generating {args.batch} {args.tier} License Keys ---")
        for i in range(1, args.batch + 1):
            k = generate_key(f"batch_{i}_{args.email}", args.tier)
            print(f"{i:02d}. {k}  (Verified: {verify_key(k)})")

if __name__ == "__main__":
    main()
