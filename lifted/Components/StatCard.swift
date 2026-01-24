import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    let color: Color

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String? = nil,
        color: Color = .blue
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct StatRow: View {
    let items: [StatItem]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(items) { item in
                StatCard(
                    title: item.title,
                    value: item.value,
                    subtitle: item.subtitle,
                    icon: item.icon,
                    color: item.color
                )
            }
        }
    }
}

struct StatItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    let color: Color

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String? = nil,
        color: Color = .blue
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
}

struct LargeStatCard: View {
    let title: String
    let value: String
    let trend: Trend?
    let icon: String
    let color: Color

    enum Trend {
        case up(String)
        case down(String)
        case neutral(String)

        var text: String {
            switch self {
            case .up(let value), .down(let value), .neutral(let value):
                return value
            }
        }

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .secondary
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                        Text(trend.text)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(trend.color)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        StatRow(items: [
            StatItem(title: "Workouts", value: "12", icon: "flame.fill", color: .orange),
            StatItem(title: "Streak", value: "5 days", icon: "bolt.fill", color: .yellow),
            StatItem(title: "Volume", value: "45k lbs", icon: "scalemass.fill", color: .blue)
        ])

        LargeStatCard(
            title: "Total Volume",
            value: "125,450 lbs",
            trend: .up("+12%"),
            icon: "chart.bar.fill",
            color: .blue
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
