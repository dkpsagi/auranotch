// AuraNotch Pro - Automated Purchase Webhook Handler (Node.js / Express / Serverless)
// Deploy to Cloudflare Workers, Vercel, Railway, or AWS Lambda.
// Handles Stripe and LemonSqueezy purchase events and generates cryptographic license keys.

const crypto = require('crypto');

const MASTER_SALT = process.env.AURANOTCH_MASTER_SALT || "AuraNotch-Master-Salt-2026-Secret";
const STRIPE_WEBHOOK_SECRET = process.env.STRIPE_WEBHOOK_SECRET;
const LEMON_SQUEEZY_WEBHOOK_SECRET = process.env.LEMON_SQUEEZY_WEBHOOK_SECRET;

/**
 * Computes the 4-char SHA256 checksum that AuraNotch.app validates offline
 */
function generateChecksum(payload) {
    const toHash = `${payload}:${MASTER_SALT}`;
    return crypto.createHash('sha256').update(toHash, 'utf8').digest('hex').substring(0, 4).toUpperCase();
}

/**
 * Generates an official verifiable license key
 */
function issueLicenseKey(tier = "LIFETIME") {
    const entropy = crypto.randomBytes(4).toString('hex').toUpperCase();
    const part1 = entropy.substring(0, 4);
    const part2 = entropy.substring(4, 8);
    const basePayload = `AURA-${tier.toUpperCase()}-${part1}-${part2}`;
    const checksum = generateChecksum(basePayload);
    return `${basePayload}-${checksum}`;
}

/**
 * Stripe Webhook Handler
 */
async function handleStripeWebhook(req, res) {
    const sig = req.headers['stripe-signature'];
    let event = req.body;

    // Optional: Verify Stripe Signature if secret is configured
    // event = stripe.webhooks.constructEvent(req.rawBody, sig, STRIPE_WEBHOOK_SECRET);

    if (event.type === 'checkout.session.completed') {
        const session = event.data.object;
        const buyerEmail = session.customer_details ? session.customer_details.email : session.customer_email;
        const orderId = session.id;

        // Generate cryptographic key
        const licenseKey = issueLicenseKey("LIFETIME");

        console.log(`[AuraNotch Stripe Purchase] Issued key ${licenseKey} for ${buyerEmail} (Order: ${orderId})`);

        // Send email via your email provider (Resend, Postmark, SendGrid)
        // await sendConfirmationEmail(buyerEmail, licenseKey, orderId);

        return res.status(200).json({ success: true, key: licenseKey });
    }

    res.status(200).json({ received: true });
}

/**
 * Lemon Squeezy Webhook Handler
 */
async function handleLemonSqueezyWebhook(req, res) {
    const eventName = req.body.meta ? req.body.meta.event_name : null;

    if (eventName === 'order_created') {
        const order = req.body.data.attributes;
        const buyerEmail = order.user_email;
        const orderId = req.body.data.id;

        const licenseKey = issueLicenseKey("LIFETIME");
        console.log(`[AuraNotch LemonSqueezy Purchase] Issued key ${licenseKey} for ${buyerEmail}`);

        return res.status(200).json({ success: true, key: licenseKey });
    }

    res.status(200).json({ received: true });
}

module.exports = {
    issueLicenseKey,
    handleStripeWebhook,
    handleLemonSqueezyWebhook
};
