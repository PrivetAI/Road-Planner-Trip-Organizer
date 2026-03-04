import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var store: DataStore
    @State private var showPrivacyPolicy = false
    @State private var copiedToClipboard = false

    var trip: Trip? { store.selectedTrip }

    var totalDays: Int {
        guard let t = trip else { return 0 }
        return max(1, (Calendar.current.dateComponents([.day], from: t.startDate, to: t.endDate).day ?? 0) + 1)
    }

    var totalSpent: Double {
        guard let id = trip?.id else { return 0 }
        return store.totalSpent(tripID: id)
    }

    var placesVisited: Int {
        guard let id = trip?.id else { return 0 }
        let acts = store.activities[id] ?? []
        return Set(acts.map { $0.placeName }).count
    }

    var checklistProgress: Double {
        guard let id = trip?.id, let items = store.checklists[id], !items.isEmpty else { return 0 }
        return Double(items.filter { $0.isChecked }.count) / Double(items.count)
    }

    var dailyAvg: Double {
        totalDays > 0 ? totalSpent / Double(totalDays) : 0
    }

    var summaryText: String {
        guard let t = trip else { return "" }
        let df = DateFormatter()
        df.dateStyle = .medium
        return """
        Trip: \(t.name)
        Destination: \(t.destination)
        Dates: \(df.string(from: t.startDate)) - \(df.string(from: t.endDate))
        Total Days: \(totalDays)
        Budget: $\(String(format: "%.0f", t.budget))
        Total Spent: $\(String(format: "%.2f", totalSpent))
        Remaining: $\(String(format: "%.2f", t.budget - totalSpent))
        Daily Average: $\(String(format: "%.2f", dailyAvg))
        Places Visited: \(placesVisited)
        Packing: \(Int(checklistProgress * 100))% complete
        """
    }

    var body: some View {
        VStack(spacing: 0) {
            GoldHeaderView(title: "Summary")

            ZStack {
                Theme.lightGray.ignoresSafeArea()
                if trip == nil {
                    VStack(spacing: 12) {
                        FlagIcon()
                            .fill(Theme.gold.opacity(0.4))
                            .frame(width: 50, height: 50)
                        Text("Select a trip first")
                            .foregroundColor(Theme.darkGray)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Trip header
                            VStack(spacing: 4) {
                                Text(trip?.name ?? "")
                                    .font(.title2.bold())
                                    .foregroundColor(Theme.darkGray)
                                Text(trip?.destination ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.darkGray.opacity(0.7))
                            }
                            .padding()

                            // Stats grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                statCard(title: "Total Days", value: "\(totalDays)")
                                statCard(title: "Total Spent", value: String(format: "$%.0f", totalSpent))
                                statCard(title: "Places Visited", value: "\(placesVisited)")
                                statCard(title: "Packed", value: "\(Int(checklistProgress * 100))%")
                                statCard(title: "Daily Average", value: String(format: "$%.0f", dailyAvg))
                                statCard(title: "Remaining", value: String(format: "$%.0f", (trip?.budget ?? 0) - totalSpent))
                            }
                            .padding(.horizontal)

                            // Copy summary
                            Button(action: {
                                UIPasteboard.general.string = summaryText
                                copiedToClipboard = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedToClipboard = false
                                }
                            }) {
                                HStack {
                                    FlagIcon()
                                        .fill(Theme.white)
                                        .frame(width: 16, height: 16)
                                    Text(copiedToClipboard ? "Copied!" : "Copy Summary")
                                        .font(.subheadline.bold())
                                        .foregroundColor(Theme.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.gold)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)

                            // Privacy Policy
                            Button(action: { showPrivacyPolicy = true }) {
                                Text("Privacy Policy")
                                    .font(.caption)
                                    .foregroundColor(Theme.gold)
                                    .underline()
                            }
                            .padding(.top, 8)
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationView {
                PlannerWebPanel(url: URL(string: "https://example.com")!)
                    .navigationTitle("Privacy Policy")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") { showPrivacyPolicy = false }
                        }
                    }
            }
        }
    }

    func statCard(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(Theme.gold)
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.darkGray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.white)
        .cornerRadius(12)
    }
}
