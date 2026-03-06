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
    var weight: Double?

    init(id: UUID = UUID(), name: String, category: String, isChecked: Bool = false, weight: Double? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.isChecked = isChecked
        self.weight = weight
    }
}

struct ItineraryActivity: Codable, Identifiable {
    var id: UUID
    var dayIndex: Int
    var time: String
    var placeName: String
    var notes: String
    var orderIndex: Int
    var rating: Int?
    var review: String?

    init(id: UUID = UUID(), dayIndex: Int, time: String, placeName: String, notes: String, orderIndex: Int = 0, rating: Int? = nil, review: String? = nil) {
        self.id = id
        self.dayIndex = dayIndex
        self.time = time
        self.placeName = placeName
        self.notes = notes
        self.orderIndex = orderIndex
        self.rating = rating
        self.review = review
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

struct JournalEntry: Codable, Identifiable {
    var id: UUID
    var tripID: UUID
    var dayIndex: Int
    var title: String
    var text: String
    var date: Date

    init(id: UUID = UUID(), tripID: UUID, dayIndex: Int, title: String, text: String, date: Date = Date()) {
        self.id = id
        self.tripID = tripID
        self.dayIndex = dayIndex
        self.title = title
        self.text = text
        self.date = date
    }
}

struct EmergencyContact: Codable, Identifiable {
    var id: UUID
    var name: String
    var phone: String
    var relationship: String

    init(id: UUID = UUID(), name: String, phone: String, relationship: String) {
        self.id = id
        self.name = name
        self.phone = phone
        self.relationship = relationship
    }
}

struct EmergencyInfo: Codable, Identifiable {
    var id: UUID
    var tripID: UUID
    var contacts: [EmergencyContact]
    var passportNumber: String
    var insurancePolicy: String
    var bloodType: String
    var allergies: String
    var notes: String

    init(id: UUID = UUID(), tripID: UUID, contacts: [EmergencyContact] = [], passportNumber: String = "", insurancePolicy: String = "", bloodType: String = "", allergies: String = "", notes: String = "") {
        self.id = id
        self.tripID = tripID
        self.contacts = contacts
        self.passportNumber = passportNumber
        self.insurancePolicy = insurancePolicy
        self.bloodType = bloodType
        self.allergies = allergies
        self.notes = notes
    }
}

enum DocumentType: String, Codable, CaseIterable {
    case flight = "Flight"
    case hotel = "Hotel"
    case carRental = "Car Rental"
    case train = "Train"
    case bus = "Bus"
    case other = "Other"
}

struct TravelDocument: Codable, Identifiable {
    var id: UUID
    var tripID: UUID
    var type: DocumentType
    var referenceNumber: String
    var startDate: Date?
    var endDate: Date?
    var notes: String

    init(id: UUID = UUID(), tripID: UUID, type: DocumentType, referenceNumber: String, startDate: Date? = nil, endDate: Date? = nil, notes: String = "") {
        self.id = id
        self.tripID = tripID
        self.type = type
        self.referenceNumber = referenceNumber
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
    }
}
