import Foundation
import SwiftUI

class DataStore: ObservableObject {
    @Published var trips: [Trip] = [] {
        didSet { saveTrips() }
    }
    @Published var selectedTripID: UUID? {
        didSet { saveSelectedTripID() }
    }
    @Published var checklists: [UUID: [ChecklistItem]] = [:] {
        didSet { saveChecklists() }
    }
    @Published var activities: [UUID: [ItineraryActivity]] = [:] {
        didSet { saveActivities() }
    }
    @Published var expenses: [UUID: [Expense]] = [:] {
        didSet { saveExpenses() }
    }

    var selectedTrip: Trip? {
        trips.first(where: { $0.id == selectedTripID })
    }

    init() {
        loadAll()
    }

    // MARK: - Trips
    func addTrip(_ trip: Trip) {
        trips.append(trip)
        if selectedTripID == nil {
            selectedTripID = trip.id
        }
        // Initialize default checklist
        if checklists[trip.id] == nil {
            checklists[trip.id] = Self.defaultChecklist()
        }
    }

    func deleteTrip(at offsets: IndexSet) {
        let ids = offsets.map { trips[$0].id }
        trips.remove(atOffsets: offsets)
        for id in ids {
            checklists.removeValue(forKey: id)
            activities.removeValue(forKey: id)
            expenses.removeValue(forKey: id)
            if selectedTripID == id {
                selectedTripID = trips.first?.id
            }
        }
    }

    func selectTrip(_ trip: Trip) {
        selectedTripID = trip.id
    }

    // MARK: - Checklist
    static func defaultChecklist() -> [ChecklistItem] {
        let templates: [(String, [String])] = [
            ("Documents", ["Passport", "ID Card", "Travel Insurance", "Boarding Pass", "Hotel Reservation"]),
            ("Clothing", ["T-Shirts", "Pants", "Underwear", "Socks", "Jacket", "Sleepwear"]),
            ("Electronics", ["Phone Charger", "Power Bank", "Camera", "Headphones", "Adapter"]),
            ("Medicine", ["Pain Relievers", "Band-Aids", "Prescription Meds", "Allergy Pills"]),
            ("Toiletries", ["Toothbrush", "Toothpaste", "Shampoo", "Sunscreen", "Deodorant"])
        ]
        var items: [ChecklistItem] = []
        for (cat, names) in templates {
            for n in names {
                items.append(ChecklistItem(name: n, category: cat))
            }
        }
        return items
    }

    func toggleChecklistItem(tripID: UUID, itemID: UUID) {
        guard var list = checklists[tripID],
              let idx = list.firstIndex(where: { $0.id == itemID }) else { return }
        list[idx].isChecked.toggle()
        checklists[tripID] = list
    }

    func addChecklistItem(tripID: UUID, name: String, category: String) {
        var list = checklists[tripID] ?? []
        list.append(ChecklistItem(name: name, category: category))
        checklists[tripID] = list
    }

    func resetChecklist(tripID: UUID) {
        checklists[tripID] = Self.defaultChecklist()
    }

    // MARK: - Itinerary
    func activitiesForDay(tripID: UUID, dayIndex: Int) -> [ItineraryActivity] {
        (activities[tripID] ?? [])
            .filter { $0.dayIndex == dayIndex }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    func addActivity(tripID: UUID, activity: ItineraryActivity) {
        var list = activities[tripID] ?? []
        list.append(activity)
        activities[tripID] = list
    }

    func deleteActivity(tripID: UUID, activityID: UUID) {
        var list = activities[tripID] ?? []
        list.removeAll { $0.id == activityID }
        activities[tripID] = list
    }

    func updateActivity(tripID: UUID, activity: ItineraryActivity) {
        var list = activities[tripID] ?? []
        if let idx = list.firstIndex(where: { $0.id == activity.id }) {
            list[idx] = activity
        }
        activities[tripID] = list
    }

    func moveActivities(tripID: UUID, dayIndex: Int, from source: IndexSet, to destination: Int) {
        var dayActs = activitiesForDay(tripID: tripID, dayIndex: dayIndex)
        dayActs.move(fromOffsets: source, toOffset: destination)
        for (i, var act) in dayActs.enumerated() {
            act.orderIndex = i
            dayActs[i] = act
        }
        var list = activities[tripID] ?? []
        list.removeAll { $0.dayIndex == dayIndex }
        list.append(contentsOf: dayActs)
        activities[tripID] = list
    }

    // MARK: - Expenses
    func addExpense(tripID: UUID, expense: Expense) {
        var list = expenses[tripID] ?? []
        list.append(expense)
        expenses[tripID] = list
    }

    func deleteExpense(tripID: UUID, expenseID: UUID) {
        var list = expenses[tripID] ?? []
        list.removeAll { $0.id == expenseID }
        expenses[tripID] = list
    }

    func totalSpent(tripID: UUID) -> Double {
        (expenses[tripID] ?? []).reduce(0) { $0 + $1.amount }
    }

    func spentByCategory(tripID: UUID) -> [(ExpenseCategory, Double)] {
        let list = expenses[tripID] ?? []
        var dict: [ExpenseCategory: Double] = [:]
        for e in list {
            dict[e.category, default: 0] += e.amount
        }
        return ExpenseCategory.allCases.map { ($0, dict[$0] ?? 0) }
    }

    // MARK: - Persistence
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private func saveTrips() {
        if let data = try? encoder.encode(trips) {
            UserDefaults.standard.set(data, forKey: "rp_trips")
        }
    }
    private func saveSelectedTripID() {
        UserDefaults.standard.set(selectedTripID?.uuidString, forKey: "rp_selectedTripID")
    }
    private func saveChecklists() {
        let dict = Dictionary(uniqueKeysWithValues: checklists.map { ($0.key.uuidString, $0.value) })
        if let data = try? encoder.encode(dict) {
            UserDefaults.standard.set(data, forKey: "rp_checklists")
        }
    }
    private func saveActivities() {
        let dict = Dictionary(uniqueKeysWithValues: activities.map { ($0.key.uuidString, $0.value) })
        if let data = try? encoder.encode(dict) {
            UserDefaults.standard.set(data, forKey: "rp_activities")
        }
    }
    private func saveExpenses() {
        let dict = Dictionary(uniqueKeysWithValues: expenses.map { ($0.key.uuidString, $0.value) })
        if let data = try? encoder.encode(dict) {
            UserDefaults.standard.set(data, forKey: "rp_expenses")
        }
    }

    private func loadAll() {
        if let data = UserDefaults.standard.data(forKey: "rp_trips"),
           let val = try? decoder.decode([Trip].self, from: data) {
            trips = val
        }
        if let str = UserDefaults.standard.string(forKey: "rp_selectedTripID") {
            selectedTripID = UUID(uuidString: str)
        }
        if let data = UserDefaults.standard.data(forKey: "rp_checklists"),
           let dict = try? decoder.decode([String: [ChecklistItem]].self, from: data) {
            checklists = Dictionary(uniqueKeysWithValues: dict.compactMap { k, v in
                UUID(uuidString: k).map { ($0, v) }
            })
        }
        if let data = UserDefaults.standard.data(forKey: "rp_activities"),
           let dict = try? decoder.decode([String: [ItineraryActivity]].self, from: data) {
            activities = Dictionary(uniqueKeysWithValues: dict.compactMap { k, v in
                UUID(uuidString: k).map { ($0, v) }
            })
        }
        if let data = UserDefaults.standard.data(forKey: "rp_expenses"),
           let dict = try? decoder.decode([String: [Expense]].self, from: data) {
            expenses = Dictionary(uniqueKeysWithValues: dict.compactMap { k, v in
                UUID(uuidString: k).map { ($0, v) }
            })
        }
    }
}
