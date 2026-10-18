import SwiftUI

public struct PlatformSales: Identifiable {
    public let id = UUID()
    public let platformName: String
    public let amount: Double
    public let orderCount: Int
    public let platformColor: Color
    public let iconName: String
}

public class SalesManager: ObservableObject {
    public static let shared = SalesManager()

    @Published public var platforms: [PlatformSales] = [
        PlatformSales(platformName: "Stripe", amount: 485.00, orderCount: 24, platformColor: .purple, iconName: "creditcard.fill"),
        PlatformSales(platformName: "Lemon Squeezy", amount: 265.00, orderCount: 14, platformColor: .yellow, iconName: "cart.fill"),
        PlatformSales(platformName: "Polar.sh", amount: 150.00, orderCount: 6, platformColor: .blue, iconName: "snowflake"),
        PlatformSales(platformName: "Gumroad", amount: 85.00, orderCount: 4, platformColor: .pink, iconName: "bag.fill"),
        PlatformSales(platformName: "Paddle", amount: 120.00, orderCount: 3, platformColor: .green, iconName: "globe")
    ]

    @Published public var hideAmounts: Bool = false
    @Published public var currencySymbol: String = "$"

    public var totalRevenueToday: Double {
        platforms.reduce(0) { $0 + $1.amount }
    }

    public var totalOrdersToday: Int {
        platforms.reduce(0) { $0 + $1.orderCount }
    }
}

public struct SalesTrackerView: View {
    @ObservedObject var sales = SalesManager.shared

    public var body: some View {
        VStack(spacing: 14) {
            // Main Revenue Display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Today's Net Revenue")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)
                        Button(action: { sales.hideAmounts.toggle() }) {
                            Image(systemName: sales.hideAmounts ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }

                    if sales.hideAmounts {
                        Text("••••••")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Text("\(sales.currencySymbol)\(String(format: "%.2f", sales.totalRevenueToday))")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Orders")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .textCase(.uppercase)
                    Text("\(sales.totalOrdersToday) sales")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)

            // Platform Breakdowns
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(sales.platforms) { platform in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(platform.platformColor)
                                .frame(width: 10, height: 10)

                            Text(platform.platformName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()

                            Text("\(platform.orderCount) orders")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.45))

                            Text(sales.hideAmounts ? "••••" : "\(sales.currencySymbol)\(String(format: "%.2f", platform.amount))")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(8)
                    }
                }
            }

            // Security assurance
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 10))
                Text("API keys stored securely in your macOS Keychain. Read-only permissions.")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
            }
        }
        .padding(16)
    }
}
