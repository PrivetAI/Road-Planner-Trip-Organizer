import SwiftUI

struct EmergencyView: View {
    @EnvironmentObject var store: DataStore
    @State private var showEditSheet = false

    var tripID: UUID? { store.selectedTripID }

    var info: EmergencyInfo {
        guard let id = tripID else { return EmergencyInfo(tripID: UUID()) }
        return store.getEmergencyInfo(tripID: id)
    }

    var body: some View {
        VStack(spacing: 0) {
            GoldHeaderView(title: "Emergency") {
                if tripID != nil {
                    Button(action: { showEditSheet = true }) {
                        Text("Edit")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }

            ZStack {
                Theme.lightGray.ignoresSafeArea()
                if tripID == nil {
                    noTripView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Emergency Contacts
                            if !info.contacts.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Emergency Contacts")
                                        .font(.headline)
                                        .foregroundColor(Theme.darkGray)
                                    ForEach(info.contacts) { contact in
                                        ContactCard(contact: contact)
                                    }
                                }
                                .padding()
                                .background(Theme.white)
                                .cornerRadius(12)
                            }

                            // Medical Info
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Medical Information")
                                    .font(.headline)
                                    .foregroundColor(Theme.darkGray)
                                if !info.bloodType.isEmpty {
                                    InfoRow(label: "Blood Type", value: info.bloodType)
                                }
                                if !info.allergies.isEmpty {
                                    InfoRow(label: "Allergies", value: info.allergies)
                                }
                                if info.bloodType.isEmpty && info.allergies.isEmpty {
                                    Text("No medical info added")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.darkGray.opacity(0.5))
                                }
                            }
                            .padding()
                            .background(Theme.white)
                            .cornerRadius(12)

                            // Travel Documents
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Travel Documents")
                                    .font(.headline)
                                    .foregroundColor(Theme.darkGray)
                                if !info.passportNumber.isEmpty {
                                    InfoRow(label: "Passport", value: info.passportNumber)
                                }
                                if !info.insurancePolicy.isEmpty {
                                    InfoRow(label: "Insurance", value: info.insurancePolicy)
                                }
                                if info.passportNumber.isEmpty && info.insurancePolicy.isEmpty {
                                    Text("No documents added")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.darkGray.opacity(0.5))
                                }
                            }
                            .padding()
                            .background(Theme.white)
                            .cornerRadius(12)

                            // Notes
                            if !info.notes.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Notes")
                                        .font(.headline)
                                        .foregroundColor(Theme.darkGray)
                                    Text(info.notes)
                                        .font(.subheadline)
                                        .foregroundColor(Theme.darkGray.opacity(0.8))
                                }
                                .padding()
                                .background(Theme.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let id = tripID {
                EmergencyEditSheet(tripID: id, isPresented: $showEditSheet)
                    .environmentObject(store)
            }
        }
    }

    var noTripView: some View {
        VStack(spacing: 12) {
            ShieldIcon()
                .fill(Theme.gold.opacity(0.4))
                .frame(width: 50, height: 50)
            Text("Select a trip first")
                .foregroundColor(Theme.darkGray)
        }
    }
}

struct ContactCard: View {
    let contact: EmergencyContact

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.gold.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(contact.name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(Theme.gold)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.darkGray)
                Text(contact.phone)
                    .font(.subheadline)
                    .foregroundColor(Theme.gold)
                Text(contact.relationship)
                    .font(.caption)
                    .foregroundColor(Theme.darkGray.opacity(0.7))
            }
            Spacer()
        }
        .padding()
        .background(Theme.lightGray)
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Theme.darkGray.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(Theme.darkGray)
        }
    }
}

struct EmergencyEditSheet: View {
    let tripID: UUID
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var contacts: [EmergencyContact] = []
    @State private var passportNumber = ""
    @State private var insurancePolicy = ""
    @State private var bloodType = ""
    @State private var allergies = ""
    @State private var notes = ""
    @State private var showAddContact = false

    init(tripID: UUID, isPresented: Binding<Bool>) {
        self.tripID = tripID
        self._isPresented = isPresented
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Emergency Contacts")) {
                    ForEach(contacts) { contact in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.name)
                                .font(.headline)
                            Text(contact.phone)
                                .font(.subheadline)
                                .foregroundColor(Theme.gold)
                            Text(contact.relationship)
                                .font(.caption)
                                .foregroundColor(Theme.darkGray.opacity(0.7))
                        }
                    }
                    .onDelete { offsets in
                        contacts.remove(atOffsets: offsets)
                    }
                    Button(action: { showAddContact = true }) {
                        HStack {
                            PlusIcon()
                                .fill(Theme.gold)
                                .frame(width: 16, height: 16)
                            Text("Add Contact")
                                .foregroundColor(Theme.gold)
                        }
                    }
                }

                Section(header: Text("Medical Information")) {
                    TextField("Blood Type", text: $bloodType)
                    TextField("Allergies", text: $allergies)
                }

                Section(header: Text("Travel Documents")) {
                    TextField("Passport Number", text: $passportNumber)
                    TextField("Insurance Policy", text: $insurancePolicy)
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Emergency Info")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var info = store.getEmergencyInfo(tripID: tripID)
                        info.contacts = contacts
                        info.passportNumber = passportNumber
                        info.insurancePolicy = insurancePolicy
                        info.bloodType = bloodType
                        info.allergies = allergies
                        info.notes = notes
                        store.updateEmergencyInfo(info: info)
                        isPresented = false
                    }
                }
            }
            .onAppear {
                let info = store.getEmergencyInfo(tripID: tripID)
                contacts = info.contacts
                passportNumber = info.passportNumber
                insurancePolicy = info.insurancePolicy
                bloodType = info.bloodType
                allergies = info.allergies
                notes = info.notes
            }
        }
        .sheet(isPresented: $showAddContact) {
            AddContactSheet(contacts: $contacts, isPresented: $showAddContact)
        }
    }
}

struct AddContactSheet: View {
    @Binding var contacts: [EmergencyContact]
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var phone = ""
    @State private var relationship = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Relationship", text: $relationship)
            }
            .navigationTitle("Add Contact")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if !name.isEmpty && !phone.isEmpty {
                            contacts.append(EmergencyContact(name: name, phone: phone, relationship: relationship))
                        }
                        isPresented = false
                    }
                }
            }
        }
    }
}
