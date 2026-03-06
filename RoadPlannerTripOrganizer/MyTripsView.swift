import SwiftUI

struct MyTripsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddSheet = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            GoldHeaderView(title: "My Trips") {
                Button(action: { showAddSheet = true }) {
                    PlusIcon()
                        .fill(Theme.white)
                        .frame(width: 22, height: 22)
                }
            }

            ZStack {
                Theme.lightGray.ignoresSafeArea()
                if store.trips.isEmpty {
                    VStack(spacing: 16) {
                        SuitcaseIcon()
                            .fill(Theme.gold.opacity(0.4))
                            .frame(width: 60, height: 60)
                        Text("No trips yet")
                            .font(.headline)
                            .foregroundColor(Theme.darkGray)
                        Text("Tap + to plan your first trip")
                            .font(.subheadline)
                            .foregroundColor(Theme.darkGray.opacity(0.7))
                    }
                } else {
                    List {
                        ForEach(store.trips) { trip in
                            Button(action: { store.selectTrip(trip) }) {
                                TripCardView(trip: trip, isSelected: store.selectedTripID == trip.id, dateFormatter: dateFormatter)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: store.deleteTrip)
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddTripSheet(isPresented: $showAddSheet)
                .environmentObject(store)
        }
    }
}

struct TripCardView: View {
    let trip: Trip
    let isSelected: Bool
    let dateFormatter: DateFormatter

    var statusColor: Color {
        switch trip.status {
        case .planned: return Theme.gold
        case .active: return Color.green
        case .completed: return Theme.darkGray
        }
    }

    var countdownText: String {
        let now = Date()
        let calendar = Calendar.current
        
        switch trip.status {
        case .completed:
            return "Completed"
        case .active:
            let totalDays = calendar.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
            let currentDay = calendar.dateComponents([.day], from: trip.startDate, to: now).day ?? 0
            return "Day \(currentDay + 1) of \(totalDays + 1)"
        case .planned:
            let daysUntil = calendar.dateComponents([.day], from: now, to: trip.startDate).day ?? 0
            if daysUntil == 0 {
                return "Starts today"
            } else if daysUntil == 1 {
                return "1 day until trip"
            } else {
                return "\(daysUntil) days until trip"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trip.name)
                    .font(.headline)
                    .foregroundColor(Theme.darkGray)
                Spacer()
                if isSelected {
                    Circle()
                        .fill(Theme.gold)
                        .frame(width: 10, height: 10)
                }
            }
            HStack {
                MapPinIcon()
                    .fill(Theme.gold)
                    .frame(width: 14, height: 14)
                Text(trip.destination)
                    .font(.subheadline)
                    .foregroundColor(Theme.darkGray.opacity(0.8))
            }
            HStack {
                Text("\(dateFormatter.string(from: trip.startDate)) - \(dateFormatter.string(from: trip.endDate))")
                    .font(.caption)
                    .foregroundColor(Theme.darkGray.opacity(0.6))
                Spacer()
                Text(String(format: "$%.0f", trip.budget))
                    .font(.caption.bold())
                    .foregroundColor(Theme.gold)
            }
            HStack {
                Text(trip.status.rawValue)
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor)
                    .cornerRadius(8)
                Spacer()
                Text(countdownText)
                    .font(.caption.bold())
                    .foregroundColor(Theme.gold)
            }
        }
        .padding()
        .background(Theme.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Theme.gold : Color.clear, lineWidth: 2)
        )
    }
}

struct AddTripSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var name = ""
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var budgetStr = ""
    @State private var status: TripStatus = .planned

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Trip Name", text: $name)
                    TextField("Destination", text: $destination)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    TextField("Budget ($)", text: $budgetStr)
                        .keyboardType(.decimalPad)
                    Picker("Status", selection: $status) {
                        ForEach(TripStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                }
            }
            .navigationTitle("New Trip")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let budget = Double(budgetStr) ?? 0
                        let trip = Trip(name: name.isEmpty ? "My Trip" : name,
                                       destination: destination.isEmpty ? "Unknown" : destination,
                                       startDate: startDate,
                                       endDate: endDate,
                                       budget: budget,
                                       status: status)
                        store.addTrip(trip)
                        isPresented = false
                    }
                }
            }
        }
    }
}
