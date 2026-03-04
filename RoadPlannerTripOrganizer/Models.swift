import Foundation

enum TripStatus: String, Codable, CaseIterable {
    case planned = "Planned"
    case active = "Active"
    case completed = "Completed"
}

struct Trip: Codable, Identifiable {
    var id: UUID
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var budget: Double
    var status: TripStatus

    init(id: UUID = UUID(), name: String, destination: String, startDate: Date, endDate: Date, budget: Double, status: TripStatus = .planned) {
        self.id = id
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.budget = budget
        self.status = status
    }
}

struct ChecklistItem: Codable, Identifiable {
    var id: UUID
    var name: String
    var category: String
    var isChecked: Bool

    init(id: UUID = UUID(), name: String, category: String, isChecked: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.isChecked = isChecked
    }
}

struct ItineraryActivity: Codable, Identifiable {
    var id: UUID
    var dayIndex: Int
    var time: String
    var placeName: String
    var notes: String
    var orderIndex: Int

    init(id: UUID = UUID(), dayIndex: Int, time: String, placeName: String, notes: String, orderIndex: Int = 0) {
        self.id = id
        self.dayIndex = dayIndex
        self.time = time
        self.placeName = placeName
        self.notes = notes
        self.orderIndex = orderIndex
    }
}

enum ExpenseCategory: String, Codable, CaseIterable {
    case transport = "Transport"
    case accommodation = "Accommodation"
    case food = "Food"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case other = "Other"
}

struct Expense: Codable, Identifiable {
    var id: UUID
    var amount: Double
    var category: ExpenseCategory
    var note: String
    var date: Date

    init(id: UUID = UUID(), amount: Double, category: ExpenseCategory, note: String, date: Date = Date()) {
        self.id = id
        self.amount = amount
        self.category = category
        self.note = note
        self.date = date
    }
}
