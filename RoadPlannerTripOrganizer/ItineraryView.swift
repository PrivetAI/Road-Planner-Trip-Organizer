import SwiftUI

struct ItineraryView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedDay: Int = 0
    @State private var showAddActivity = false
    @State private var editingActivity: ItineraryActivity?
    @State private var ratingActivity: ItineraryActivity?

    var trip: Trip? { store.selectedTrip }

    var totalDays: Int {
        guard let t = trip else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: t.startDate, to: t.endDate).day ?? 1)
    }

    var dayActivities: [ItineraryActivity] {
        guard let id = trip?.id else { return [] }
        return store.activitiesForDay(tripID: id, dayIndex: selectedDay)
    }
    
    var averageRating: Double? {
        guard let id = trip?.id else { return nil }
        return store.averageRating(tripID: id)
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
                        // Average rating banner
                        if let avgRating = averageRating {
                            HStack {
                                Text("Trip Average:")
                                    .font(.caption)
                                    .foregroundColor(Theme.darkGray.opacity(0.7))
                                HStack(spacing: 2) {
                                    ForEach(0..<5, id: \.self) { index in
                                        StarIcon()
                                            .fill(index < Int(avgRating.rounded()) ? Theme.gold : Theme.lightGray)
                                            .frame(width: 12, height: 12)
                                    }
                                }
                                Text(String(format: "%.1f", avgRating))
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.gold)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Theme.white)
                        }
                        
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
                                    VStack(alignment: .leading, spacing: 8) {
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
                                        }
                                        
                                        // Rating display
                                        if let rating = act.rating {
                                            HStack(spacing: 4) {
                                                ForEach(0..<5, id: \.self) { index in
                                                    StarIcon()
                                                        .fill(index < rating ? Theme.gold : Theme.lightGray)
                                                        .frame(width: 14, height: 14)
                                                }
                                                if let review = act.review, !review.isEmpty {
                                                    Text(review)
                                                        .font(.caption)
                                                        .foregroundColor(Theme.darkGray.opacity(0.7))
                                                        .lineLimit(1)
                                                }
                                            }
                                            .padding(.leading, 62)
                                        }
                                        
                                        // Rate button
                                        Button(action: { ratingActivity = act }) {
                                            HStack {
                                                Spacer()
                                                Text(act.rating == nil ? "Rate" : "Edit Rating")
                                                    .font(.caption.bold())
                                                    .foregroundColor(Theme.gold)
                                                StarIcon()
                                                    .fill(Theme.gold)
                                                    .frame(width: 12, height: 12)
                                            }
                                            .padding(.leading, 62)
                                        }
                                    }
                                    .padding(.vertical, 4)
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
        .sheet(item: $ratingActivity) { act in
            RatingSheet(activity: act, isPresented: Binding(get: { ratingActivity != nil }, set: { if !$0 { ratingActivity = nil } }))
                .environmentObject(store)
        }
    }
}

struct RatingSheet: View {
    let activity: ItineraryActivity
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var rating: Int = 0
    @State private var review: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(activity.placeName)
                        .font(.title2.bold())
                        .foregroundColor(Theme.darkGray)
                    Text("How was your experience?")
                        .font(.subheadline)
                        .foregroundColor(Theme.darkGray.opacity(0.6))
                }
                .padding(.top, 20)
                
                // Star picker
                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: { rating = star }) {
                            StarIcon()
                                .fill(star <= rating ? Theme.gold : Theme.lightGray)
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                .padding()
                
                // Review text field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review (optional)")
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.darkGray)
                    TextEditor(text: $review)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.lightGray, lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Rate Activity")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let tripID = store.selectedTripID else { return }
                        var updated = activity
                        updated.rating = rating > 0 ? rating : nil
                        updated.review = review.isEmpty ? nil : review
                        store.updateActivity(tripID: tripID, activity: updated)
                        isPresented = false
                    }
                }
            }
            .onAppear {
                rating = activity.rating ?? 0
                review = activity.review ?? ""
            }
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
