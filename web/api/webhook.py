#!/usr/bin/env python3
"""
AuraNotch Pro - Automated Purchase Webhook Handler (Python / FastAPI / Flask)
Listens for Stripe & LemonSqueezy payment webhook notifications and generates
verifiable cryptographic license keys instantly.
"""

import hashlib
import uuid
import os
from typing import Dict, Any

MASTER_SALT = os.getenv("AURANOTCH_MASTER_SALT", "AuraNotch-Master-Salt-2026-Secret")

def generate_checksum(payload: str) -> str:
    to_hash = f"{payload}:{MASTER_SALT}".encode('utf-8')
    return hashlib.sha256(to_hash).hexdigest()[:4].upper()

def issue_license_key(tier: str = "LIFETIME") -> str:
    entropy = uuid.uuid4().hex.upper()[:8]
    part1 = entropy[:4]
    part2 = entropy[4:]
    base_payload = f"AURA-{tier.upper()}-{part1}-{part2}"
    checksum = generate_checksum(base_payload)
    return f"{base_payload}-{checksum}"

def process_stripe_event(event: Dict[str, Any]) -> Dict[str, Any]:
    event_type = event.get("type")
    if event_type == "checkout.session.completed":
        session = event.get("data", {}).get("object", {})
        customer_email = session.get("customer_details", {}).get("email") or session.get("customer_email")
        order_id = session.get("id")
        
        key = issue_license_key("LIFETIME")
        return {
            "success": True,
            "email": customer_email,
            "order_id": order_id,
            "license_key": key
        }
    return {"received": True}

def process_lemon_squeezy_event(payload: Dict[str, Any]) -> Dict[str, Any]:
    event_name = payload.get("meta", {}).get("event_name")
    if event_name == "order_created":
        order_data = payload.get("data", {}).get("attributes", {})
        customer_email = order_data.get("user_email")
        order_id = payload.get("data", {}).get("id")

        key = issue_license_key("LIFETIME")
        return {
            "success": True,
            "email": customer_email,
            "order_id": order_id,
            "license_key": key
        }
    return {"received": True}

if __name__ == "__main__":
    test_key = issue_license_key("LIFETIME")
    print(f"Generated test purchase key: {test_key}")
