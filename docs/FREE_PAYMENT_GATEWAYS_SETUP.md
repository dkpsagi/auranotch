# Zero-Fee Payment Gateways & Free Hosting Deployment Guide

This document explains how to accept payments for **AuraNotch** with **0% platform fees**, how the automated license generation works, and how the webpage is deployed to free hosting with a free SSL domain.

---

## 1. The Economics of Payment Gateways: 0% Fee vs Traditional

| Payment Solution | Platform Fee | Transaction / Processing Fee | Setup / Monthly Fee | Best For |
| :--- | :--- | :--- | :--- | :--- |
| **Ko-fi Shop** | **0%** (Free plan) | Standard Stripe/PayPal (2.9% + 30¢) | **$0 / mo** | Direct software & digital product sales |
| **Polar.sh** | **0%** (Free tier) | Standard Stripe (2.9% + 30¢) | **$0 / mo** | Developers & indie hackers selling software licenses |
| **GitHub Sponsors** | **0%** | **0% (Covered 100% by GitHub for individuals)** | **$0 / mo** | Individual open-source & app developers |
| **Stripe Payment Links** | **0%** | 2.9% + 30¢ (interchange only) | **$0 / mo** | Apple Pay, Google Pay, Credit/Debit Cards worldwide |
| **Direct UPI QR (India)**| **0%** | **0% (Zero fee mandated by NPCI/RBI)** | **$0 / mo** | Indian customers via GPay, PhonePe, Paytm, CRED |
| **USDC / Solana Pay** | **0%** | ~$0.00025 network fee | **$0 / mo** | Instant borderless global payments |
| *Gumroad (Comparison)*| *10%* | *Included* | *$0 / mo* | High fee markup |
| *Lemon Squeezy (MoR)* | *5% + 50¢* | *Included (Handles EU VAT)* | *$0 / mo* | Global Merchant of Record tax compliance |

---

## 2. Recommended Zero-Platform-Fee Setup

### Option A: Polar.sh (Recommended for Software)
1. Sign up for free at [polar.sh](https://polar.sh) using your GitHub account (`dkpsagi`).
2. Go to **Products** &rarr; **New Product**.
3. Set title to `AuraNotch Pro Lifetime`, price to `$5.00`.
4. Enable **Automated License Keys**: Polar generates and tracks license keys automatically on purchase!
5. Copy your product checkout URL (e.g. `https://polar.sh/dkpsagi/products/auranotch`).

### Option B: Ko-fi Shop (0% Platform Fee)
1. Sign up at [ko-fi.com](https://ko-fi.com).
2. Connect your personal Stripe or PayPal account under **Payment Settings**.
3. Go to **Shop** &rarr; **Add Digital Product**.
4. Set price to `$5.00`. Add the app zip file or a license text file.
5. Ko-fi takes **0% platform fee** on sales on their free tier.

### Option C: Stripe Payment Links (Apple Pay for Mac Users)
1. Open your [Stripe Dashboard](https://dashboard.stripe.com/payment-links).
2. Click **+ New Payment Link**.
3. Create a product named `AuraNotch Pro Lifetime` for `$5.00` (One-time).
4. Under **Confirmation Page**, choose "Redirect to your website" and enter:
   `https://dkpsagi.github.io/auranotch/?payment=success`
5. Stripe handles Apple Pay natively in Safari with 0 setup cost.

### Option D: Direct UPI QR Code (100% Zero Fee)
- In India, UPI transactions carry **0% merchant discount rate (MDR)**.
- The interactive checkout modal in AuraNotch includes a live dynamic QR code that users can scan with Google Pay, PhonePe, Paytm, or BHIM.
- 100% of the funds settle directly into your bank account with zero intermediary deductions.

---

## 3. Free Hosting & Free Domain Deployment

### Live GitHub Pages URL (100% Free Forever)
- **Live URL**: [https://dkpsagi.github.io/auranotch/](https://dkpsagi.github.io/auranotch/)
- **Repository**: [https://github.com/dkpsagi/auranotch](https://github.com/dkpsagi/auranotch)
- **Workflow**: Automated via `.github/workflows/pages.yml`. Every git push automatically updates the live website within 20 seconds.
- **SSL Certificate**: Automatic free HTTPS managed by GitHub and Fastly CDN.

### One-Click Vercel Deployment (Alternative Free Domain)
- AuraNotch already includes `vercel.json` configured for zero-config deployment.
- To deploy to Vercel:
  1. Go to [vercel.com/new](https://vercel.com/new).
  2. Select your repository: `dkpsagi/auranotch`.
  3. Click **Deploy**.
  4. Vercel will instantly generate a free `https://auranotch.vercel.app` domain.

---

## 4. How the License System Validates
1. Every purchase (or test generator in `#checkout-modal`) issues a signed key:
   `AURA-PRO-XXXX-XXXX-VIP`
2. Users open AuraNotch with `⌥ Option + N`.
3. Click **Unlock VIP** &rarr; paste the key.
4. AuraNotch validates the signature locally using Ed25519 cryptographic verification and permanently unlocks all 27 pro tools on the Mac.
