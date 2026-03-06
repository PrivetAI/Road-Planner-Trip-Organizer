import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var store: DataStore

    var totalTrips: Int { store.totalTripsCount() }
    var totalDays: Int { store.totalDaysTraveled() }
    var totalSpent: Double { store.totalMoneySpent() }
    var avgDuration: Double { store.averageTripDuration() }
    var avgDailySpending: Double { store.averageDailySpending() }
    var destinations: [(String, Int)] { store.mostVisitedDestinations() }
    var monthlySpend: [(String, Double)] { store.monthlySpending() }

    var body: some View {
        VStack(spacing: 0) {
            GoldHeaderView(title: "Trip Statistics") {
                EmptyView()
            }

            ZStack {
                Theme.lightGray.ignoresSafeArea()
                if store.trips.isEmpty {
                    VStack(spacing: 12) {
                        ChartIcon()
                            .fill(Theme.gold.opacity(0.4))
                            .frame(width: 50, height: 50)
                        Text("No trips yet")
                            .foregroundColor(Theme.darkGray)
                        Text("Start planning to see your stats")
                            .font(.subheadline)
                            .foregroundColor(Theme.darkGray.opacity(0.6))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Overview cards
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    statCard(title: "Total Trips", value: "\(totalTrips)", color: Theme.gold)
                                    statCard(title: "Days Traveled", value: "\(totalDays)", color: Theme.darkGray)
                                }
                                statCard(title: "Total Spent", value: String(format: "$%.0f", totalSpent), color: Color.green)
                            }
                            .padding(.horizontal)
                            
                            // Fun stat
                            VStack(spacing: 8) {
                                Text("You've planned \(totalDays) days of adventure!")
                                    .font(.headline)
                                    .foregroundColor(Theme.gold)
                                    .multilineTextAlignment(.center)
                                if avgDuration > 0 {
                                    Text("Average trip: \(String(format: "%.1f days", avgDuration))")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.darkGray.opacity(0.7))
                                }
                                if avgDailySpending > 0 {
                                    Text("Daily spending: \(String(format: "$%.2f", avgDailySpending))")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.darkGray.opacity(0.7))
                                }
                            }
                            .padding()
                            .background(Theme.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Most visited destinations
                            if !destinations.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Most Visited Destinations")
                                        .font(.headline)
                                        .foregroundColor(Theme.darkGray)
                                    
                                    ForEach(destinations.prefix(5), id: \.0) { dest, count in
                                        HStack {
                                            MapPinIcon()
                                                .fill(Theme.gold)
                                                .frame(width: 16, height: 16)
                                            Text(dest)
                                                .font(.subheadline)
                                                .foregroundColor(Theme.darkGray)
                                            Spacer()
                                            Text("\(count) trip\(count > 1 ? "s" : "")")
                                                .font(.subheadline.bold())
                                                .foregroundColor(Theme.gold)
                                        }
                                        .padding(.vertical, 4)
                                        if dest != destinations.prefix(5).last?.0 {
                                            Divider()
                                        }
                                    }
                                }
                                .padding()
                                .background(Theme.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            
                            // Monthly spending chart
                            if !monthlySpend.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Monthly Spending")
                                        .font(.headline)
                                        .foregroundColor(Theme.darkGray)
                                    
                                    let maxSpend = monthlySpend.map { $0.1 }.max() ?? 1
                                    ForEach(monthlySpend, id: \.0) { month, amount in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(month)
                                                    .font(.caption)
                                                    .foregroundColor(Theme.darkGray)
                                                    .frame(width: 80, alignment: .leading)
                                                Spacer()
                                                Text(String(format: "$%.0f", amount))
                                                    .font(.caption.bold())
                                                    .foregroundColor(Theme.darkGray)
                                            }
                                            GeometryReader { geo in
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Theme.gold)
                                                    .frame(width: maxSpend > 0 ? geo.size.width * CGFloat(amount / maxSpend) : 0, height: 20)
                                            }
                                            .frame(height: 20)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                .padding()
                                .background(Theme.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            
                            // Budget performance
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Budget Performance")
                                    .font(.headline)
                                    .foregroundColor(Theme.darkGray)
                                
                                ForEach(store.trips.prefix(5)) { trip in
                                    let spent = store.totalSpent(tripID: trip.id)
                                    let budget = trip.budget
                                    let percentage = budget > 0 ? (spent / budget) * 100 : 0
                                    let isOver = spent > budget
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(trip.name)
                                                .font(.subheadline.bold())
                                                .foregroundColor(Theme.darkGray)
                                            Spacer()
                                            Text("\(Int(percentage))%")
                                                .font(.caption.bold())
                                                .foregroundColor(isOver ? .red : Theme.gold)
                                        }
                                        HStack {
                                            Text(String(format: "$%.0f / $%.0f", spent, budget))
                                                .font(.caption)
                                                .foregroundColor(Theme.darkGray.opacity(0.7))
                                            Spacer()
                                        }
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Theme.lightGray)
                                                    .frame(height: 8)
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(isOver ? Color.red : Theme.gold)
                                                    .frame(width: geo.size.width * CGFloat(min(percentage / 100, 1.0)), height: 8)
                                            }
                                        }
                                        .frame(height: 8)
                                    }
                                    .padding(.vertical, 8)
                                    if trip.id != store.trips.prefix(5).last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding()
                            .background(Theme.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
    }
    
    func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.darkGray.opacity(0.7))
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.white)
        .cornerRadius(12)
    }
}
