# Business Strategy, Account Setup & Go-To-Market Playbook

## 1. Apple Developer Account & Notarization

To distribute **AuraNotch** outside the Mac App Store without triggering Gatekeeper security warnings on macOS Sonoma and Sequoia, you need an active Apple Developer Program membership.

### A. Account Setup
1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/) ($99 USD / year).
2. Create a **Developer ID Application** Certificate in Xcode or the Apple Developer Portal.
3. Generate an **App-Specific Password** in your Apple ID account for notarization CLI access.

### B. Codesigning & Notarization Workflow
Save your Apple credentials in Keychain:
```bash
xcrun notarytool store-credentials "AURA_NOTARY_PROFILE" \
  --apple-id "your-apple-id@email.com" \
  --team-id "TEAM_ID_HERE" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

Codesign with Hardened Runtime enabled:
```bash
# Codesign the application
codesign --deep --force --verify --verbose \
  --options runtime \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  "build/AuraNotch.app"

# Create a zipped DMG or ZIP archive
ditto -c -k --keepParent "build/AuraNotch.app" "build/AuraNotch-2.5.0.zip"

# Submit for Apple Notarization
xcrun notarytool submit "build/AuraNotch-2.5.0.zip" \
  --keychain-profile "AURA_NOTARY_PROFILE" \
  --wait

# Staple the notarization ticket to the app
xcrun stapler staple "build/AuraNotch.app"
```
Once stapled, users on any Mac can double-click and open AuraNotch with zero security warnings or Gatekeeper friction!

---

## 2. Pricing Strategy & Revenue Projections

### The "Flash Sale" Growth Engine (Learned from OmniNotch & Crafting Hype)
OmniNotch reached 600+ paying users in days by utilizing a disciplined psychological pricing ladder:

1. **Phase 1: The $5 Flash Launch (Days 1–7)**
   - **Goal:** Drive maximum volume, frictionless impulsive buying, and immediate 5-star reviews on Peerlist and Twitter.
   - **Conversion Rate:** Typically 3.5%–6.0% of landing page visitors at $5.
   - **Revenue:** 1,000 sales = **$5,000 gross revenue**.
2. **Phase 2: The Anchor Price Transition (Day 8+)**
   - Raise price to **$9.99**, then **$19.99**.
   - Always display the list price `$19.99` with strikethrough next to current sales.
3. **Phase 3: Multi-Seat & Team Licenses**
   - Single User (3 Macs): $19.99
   - Team / Family (10 Macs): $49.00
   - Lifetime All-Access + Future Plugins: $39.00

### Unit Economics with Lemon Squeezy (MoR)
- Sale Price: **$5.00**
- Lemon Squeezy Fee (5% + $0.50): **-$0.75**
- Net Profit per sale: **$4.25 (85% profit margin)**
- At 2,000 units sold: **$8,500 net profit** with zero customer support overhead.

---

## 3. Go-To-Market (GTM) & Distribution Playbook

### Step 1: Pre-Launch Directory Listings (Submit 1 Week Prior)
Submit AuraNotch to curated Mac and indie tool directories:
- **MacMenuBar.app:** Highly authoritative directory for macOS utilities.
- **Peerlist.io:** Strong developer community; great for early tech adopter feedback.
- **TryMacApps.com & Twelve.tools:** High-converting showcase sites.
- **SaasCity.io & NickLaunches:** Indie hacker directories.
- **TrustMRR:** Connect Lemon Squeezy API to display verified revenue badges, building immense buyer trust.

### Step 2: The Product Hunt #1 Day Launch Checklist
1. **Launch Timing:** 12:01 AM PST on Tuesday or Wednesday.
2. **First Comment from Maker:** Share the story of building AuraNotch, why privacy matters, and how you engineered 27 tools with liquid spring physics.
3. **Visual Media:**
   - 3-5 high-resolution clean 16:9 product screenshots.
   - A 30-second silent looping video of the notch expanding smoothly into Now Playing, AI Chat, and Teleprompter.
4. **Offer an Exclusive Product Hunt Discount Code:** E.g., `PHLAUNCH` for $4.00.

### Step 3: Twitter/X "Build In Public" Virality Formula
Post high-framerate 10-second screen recordings showing satisfying interactions:
- **Clip 1:** Hovering over the notch to reveal synced lyrics dancing to a song.
- **Clip 2:** Dragging a 4K video onto the notch and flicking it to AirDrop.
- **Clip 3:** Opening the under-camera teleprompter during a Zoom meeting.
- **Copy Template:**
  > *"Tired of dead space on your MacBook? We reverse-engineered the camera notch and built 27 native tools right inside it. 100% on-device. No cloud. No subscription. Dropping the $5 flash sale link below 👇"*

### Step 4: The Setapp Strategy (Long-Term Compounding ARR)
Once AuraNotch reaches 1,000+ happy direct customers, apply for **Setapp** (MacPaw's subscription suite):
- Setapp pays developers monthly based on user usage share.
- Top utilities like CleanMyMac, MenubarX, and Bartender make **$3,000–$15,000/month** passively from Setapp's 100k+ paying subscriber base.
