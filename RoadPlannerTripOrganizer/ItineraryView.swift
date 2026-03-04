import SwiftUI

struct ItineraryView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedDay: Int = 0
    @State private var showAddActivity = false
    @State private var editingActivity: ItineraryActivity?

    var trip: Trip? { store.selectedTrip }

    var totalDays: Int {
        guard let t = trip else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: t.startDate, to: t.endDate).day ?? 1)
    }

    var dayActivities: [ItineraryActivity] {
        guard let id = trip?.id else { return [] }
        return store.activitiesForDay(tripID: id, dayIndex: selectedDay)
    }

    var body: some View {
        VStack(spacing: 0) {
            GoldHeaderView(title: "Itinerary") {
                Button(action: { showAddActivity = true }) {
                    PlusIcon()
                        .fill(Theme.white)
                        .frame(width: 18, height: 18)
                }
            }

            ZStack {
                Theme.lightGray.ignoresSafeArea()
                if trip == nil {
                    VStack(spacing: 12) {
                        MapPinIcon()
                            .fill(Theme.gold.opacity(0.4))
                            .frame(width: 50, height: 50)
                        Text("Select a trip first")
                            .foregroundColor(Theme.darkGray)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Day selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<totalDays, id: \.self) { day in
                                    Button(action: { selectedDay = day }) {
                                        Text("Day \(day + 1)")
                                            .font(.subheadline.bold())
                                            .foregroundColor(selectedDay == day ? .white : Theme.darkGray)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(selectedDay == day ? Theme.gold : Theme.white)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .padding()
                        }
                        .background(Theme.white)

                        if dayActivities.isEmpty {
                            Spacer()
                            Text("No activities for Day \(selectedDay + 1)")
                                .foregroundColor(Theme.darkGray.opacity(0.6))
                            Spacer()
                        } else {
                            List {
                                ForEach(dayActivities) { act in
                                    Button(action: { editingActivity = act }) {
                                        HStack(alignment: .top, spacing: 12) {
                                            VStack {
                                                Text(act.time)
                                                    .font(.caption.bold())
                                                    .foregroundColor(Theme.gold)
                                            }
                                            .frame(width: 50)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(act.placeName)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Theme.darkGray)
                                                if !act.notes.isEmpty {
                                                    Text(act.notes)
                                                        .font(.caption)
                                                        .foregroundColor(Theme.darkGray.opacity(0.7))
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                .onDelete { offsets in
                                    if let id = trip?.id {
                                        let acts = dayActivities
                                        for idx in offsets {
                                            store.deleteActivity(tripID: id, activityID: acts[idx].id)
                                        }
                                    }
                                }
                                .onMove { from, to in
                                    if let id = trip?.id {
                                        store.moveActivities(tripID: id, dayIndex: selectedDay, from: from, to: to)
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            .environment(\.editMode, .constant(.active))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddActivity) {
            ActivityFormSheet(isPresented: $showAddActivity, dayIndex: selectedDay, existing: nil)
                .environmentObject(store)
        }
        .sheet(item: $editingActivity) { act in
            ActivityFormSheet(isPresented: Binding(get: { editingActivity != nil }, set: { if !$0 { editingActivity = nil } }), dayIndex: selectedDay, existing: act)
                .environmentObject(store)
        }
    }
}

struct ActivityFormSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    let dayIndex: Int
    let existing: ItineraryActivity?

    @State private var time = ""
    @State private var placeName = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Time (e.g. 09:00)", text: $time)
                TextField("Place Name", text: $placeName)
                TextField("Notes", text: $notes)
            }
            .navigationTitle(existing == nil ? "Add Activity" : "Edit Activity")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let tripID = store.selectedTripID else { return }
                        if let ex = existing {
                            var updated = ex
                            updated.time = time
                            updated.placeName = placeName
                            updated.notes = notes
                            store.updateActivity(tripID: tripID, activity: updated)
                        } else {
                            let act = ItineraryActivity(dayIndex: dayIndex, time: time.isEmpty ? "00:00" : time, placeName: placeName.isEmpty ? "Activity" : placeName, notes: notes, orderIndex: store.activitiesForDay(tripID: tripID, dayIndex: dayIndex).count)
                            store.addActivity(tripID: tripID, activity: act)
                        }
                        isPresented = false
                    }
                }
            }
            .onAppear {
                if let ex = existing {
                    time = ex.time
                    placeName = ex.placeName
                    notes = ex.notes
                }
            }
        }
    }
}
