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
    @Published var journals: [UUID: [JournalEntry]] = [:] {
        didSet { saveJournals() }
    }
    @Published var emergencyInfos: [UUID: EmergencyInfo] = [:] {
        didSet { saveEmergencyInfos() }
    }
    @Published var documents: [UUID: [TravelDocument]] = [:] {
        didSet { saveDocuments() }
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
            journals.removeValue(forKey: id)
            emergencyInfos.removeValue(forKey: id)
            documents.removeValue(forKey: id)
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

    func updateChecklistItem(tripID: UUID, item: ChecklistItem) {
        var list = checklists[tripID] ?? []
        if let idx = list.firstIndex(where: { $0.id == item.id }) {
            list[idx] = item
        }
        checklists[tripID] = list
    }

    func resetChecklist(tripID: UUID) {
        checklists[tripID] = Self.defaultChecklist()
    }

    // MARK: - Weight Tracking
    func totalPackedWeight(tripID: UUID) -> Double {
        guard let list = checklists[tripID] else { return 0 }
        return list.filter { $0.isChecked }.compactMap { $0.weight }.reduce(0, +)
    }

    func totalWeight(tripID: UUID) -> Double {
        guard let list = checklists[tripID] else { return 0 }
        return list.compactMap { $0.weight }.reduce(0, +)
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

    // MARK: - Journal
    func addJournalEntry(tripID: UUID, entry: JournalEntry) {
        var list = journals[tripID] ?? []
        list.append(entry)
        journals[tripID] = list
    }

    func updateJournalEntry(tripID: UUID, entry: JournalEntry) {
        var list = journals[tripID] ?? []
        if let idx = list.firstIndex(where: { $0.id == entry.id }) {
            list[idx] = entry
        }
        journals[tripID] = list
    }

    func deleteJournalEntry(tripID: UUID, entryID: UUID) {
        var list = journals[tripID] ?? []
        list.removeAll { $0.id == entryID }
        journals[tripID] = list
    }

    func journalEntriesForDay(tripID: UUID, dayIndex: Int) -> [JournalEntry] {
        (journals[tripID] ?? [])
            .filter { $0.dayIndex == dayIndex }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Emergency Info
    func getEmergencyInfo(tripID: UUID) -> EmergencyInfo {
        emergencyInfos[tripID] ?? EmergencyInfo(tripID: tripID)
    }

    func updateEmergencyInfo(info: EmergencyInfo) {
        emergencyInfos[info.tripID] = info
    }

    // MARK: - Documents
    func addDocument(tripID: UUID, document: TravelDocument) {
        var list = documents[tripID] ?? []
        list.append(document)
        documents[tripID] = list
    }

    func updateDocument(tripID: UUID, document: TravelDocument) {
        var list = documents[tripID] ?? []
        if let idx = list.firstIndex(where: { $0.id == document.id }) {
            list[idx] = document
        }
        documents[tripID] = list
    }

    func deleteDocument(tripID: UUID, documentID: UUID) {
        var list = documents[tripID] ?? []
        list.removeAll { $0.id == documentID }
        documents[tripID] = list
    }

    // MARK: - Trip Statistics
    func totalTripsCount() -> Int {
        trips.count
    }

    func totalDaysTraveled() -> Int {
        trips.reduce(0) { sum, trip in
            let days = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
            return sum + days + 1
        }
    }

    func totalMoneySpent() -> Double {
        trips.reduce(0) { sum, trip in
            sum + totalSpent(tripID: trip.id)
        }
    }

    func mostVisitedDestinations() -> [(String, Int)] {
        var dict: [String: Int] = [:]
        for trip in trips {
            dict[trip.destination, default: 0] += 1
        }
        return dict.sorted { $0.value > $1.value }
    }

    func averageTripDuration() -> Double {
        guard !trips.isEmpty else { return 0 }
        let totalDays = totalDaysTraveled()
        return Double(totalDays) / Double(trips.count)
    }

    func averageDailySpending() -> Double {
        let totalDays = totalDaysTraveled()
        guard totalDays > 0 else { return 0 }
        return totalMoneySpent() / Double(totalDays)
    }

    func monthlySpending() -> [(String, Double)] {
        var dict: [String: Double] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        for trip in trips {
            if let expenseList = expenses[trip.id] {
                for expense in expenseList {
                    let key = formatter.string(from: expense.date)
                    dict[key, default: 0] += expense.amount
                }
            }
        }
        return dict.sorted { $0.key < $1.key }
    }

    func averageRating(tripID: UUID) -> Double? {
        guard let acts = activities[tripID] else { return nil }
        let rated = acts.compactMap { $0.rating }
        guard !rated.isEmpty else { return nil }
        return Double(rated.reduce(0, +)) / Double(rated.count)
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
    private func saveJournals() {
        let dict = Dictionary(uniqueKeysWithValues: journals.map { ($0.key.uuidString, $0.value) })
        if let data = try? encoder.encode(dict) {
            UserDefaults.standard.set(data, forKey: "rp_journals")
        }
    }
    private func saveEmergencyInfos() {
        let dict = Dictionary(uniqueKeysWithValues: emergencyInfos.map { ($0.key.uuidString, $0.value) })
        if let data = try? encoder.encode(dict) {
            UserDefaults.standard.set(data, forKey: "rp_emergencyInfos")
        }
    }
    private func saveDocuments() {
        let dict = Dictionary(uniqueKeysWithValues: documents.map { ($0.key.uuidString, $0.value) })
        if let data = try? encoder.encode(dict) {
            UserDefaults.standard.set(data, forKey: "rp_documents")
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
        if let data = UserDefaults.standard.data(forKey: "rp_journals"),
           let dict = try? decoder.decode([String: [JournalEntry]].self, from: data) {
            journals = Dictionary(uniqueKeysWithValues: dict.compactMap { k, v in
                UUID(uuidString: k).map { ($0, v) }
            })
        }
        if let data = UserDefaults.standard.data(forKey: "rp_emergencyInfos"),
           let dict = try? decoder.decode([String: EmergencyInfo].self, from: data) {
            emergencyInfos = Dictionary(uniqueKeysWithValues: dict.compactMap { k, v in
                UUID(uuidString: k).map { ($0, v) }
            })
        }
        if let data = UserDefaults.standard.data(forKey: "rp_documents"),
           let dict = try? decoder.decode([String: [TravelDocument]].self, from: data) {
            documents = Dictionary(uniqueKeysWithValues: dict.compactMap { k, v in
                UUID(uuidString: k).map { ($0, v) }
            })
        }
    }
}
