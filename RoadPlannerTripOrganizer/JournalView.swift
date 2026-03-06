import SwiftUI

struct JournalView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddEntry = false
    @State private var editingEntry: JournalEntry?

    var tripID: UUID? { store.selectedTripID }

    var allEntries: [JournalEntry] {
        guard let id = tripID else { return [] }
        return (store.journals[id] ?? []).sorted { $0.date > $1.date }
    }

    var groupedEntries: [(Int, [JournalEntry])] {
        let dict = Dictionary(grouping: allEntries, by: { $0.dayIndex })
        return dict.sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(spacing: 0) {
            GoldHeaderView(title: "Journal") {
                Button(action: { showAddEntry = true }) {
                    PlusIcon()
                        .fill(Theme.white)
                        .frame(width: 22, height: 22)
                }
            }

            ZStack {
                Theme.lightGray.ignoresSafeArea()
                if tripID == nil {
                    noTripView
                } else if allEntries.isEmpty {
                    emptyView
                } else {
                    List {
                        ForEach(groupedEntries, id: \.0) { dayIndex, entries in
                            Section(header: Text("Day \(dayIndex + 1)").foregroundColor(Theme.gold).font(.headline)) {
                                ForEach(entries) { entry in
                                    Button(action: { editingEntry = entry }) {
                                        JournalEntryRow(entry: entry)
                                    }
                                }
                                .onDelete { offsets in
                                    if let id = tripID {
                                        for offset in offsets {
                                            store.deleteJournalEntry(tripID: id, entryID: entries[offset].id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
        }
        .sheet(isPresented: $showAddEntry) {
            if let id = tripID {
                JournalEntrySheet(tripID: id, entry: nil, isPresented: $showAddEntry)
                    .environmentObject(store)
            }
        }
        .sheet(item: $editingEntry) { entry in
            if let id = tripID {
                JournalEntrySheet(tripID: id, entry: entry, isPresented: Binding(
                    get: { editingEntry != nil },
                    set: { if !$0 { editingEntry = nil } }
                ))
                .environmentObject(store)
            }
        }
    }

    var noTripView: some View {
        VStack(spacing: 12) {
            JournalIcon()
                .fill(Theme.gold.opacity(0.4))
                .frame(width: 50, height: 50)
            Text("Select a trip first")
                .foregroundColor(Theme.darkGray)
        }
    }

    var emptyView: some View {
        VStack(spacing: 12) {
            JournalIcon()
                .fill(Theme.gold.opacity(0.4))
                .frame(width: 50, height: 50)
            Text("No journal entries yet")
                .font(.headline)
                .foregroundColor(Theme.darkGray)
            Text("Tap + to add your first entry")
                .font(.subheadline)
                .foregroundColor(Theme.darkGray.opacity(0.7))
        }
    }
}

struct JournalEntryRow: View {
    let entry: JournalEntry
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.title)
                .font(.headline)
                .foregroundColor(Theme.darkGray)
            Text(entry.text)
                .font(.subheadline)
                .foregroundColor(Theme.darkGray.opacity(0.8))
                .lineLimit(2)
            Text(dateFormatter.string(from: entry.date))
                .font(.caption)
                .foregroundColor(Theme.gold)
        }
        .padding(.vertical, 4)
    }
}

struct JournalEntrySheet: View {
    let tripID: UUID
    let entry: JournalEntry?
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var title = ""
    @State private var text = ""
    @State private var dayIndex = 0

    init(tripID: UUID, entry: JournalEntry?, isPresented: Binding<Bool>) {
        self.tripID = tripID
        self.entry = entry
        self._isPresented = isPresented
        _title = State(initialValue: entry?.title ?? "")
        _text = State(initialValue: entry?.text ?? "")
        _dayIndex = State(initialValue: entry?.dayIndex ?? 0)
    }

    var trip: Trip? {
        store.trips.first(where: { $0.id == tripID })
    }

    var numberOfDays: Int {
        guard let trip = trip else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
        return max(1, days + 1)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Entry Details")) {
                    TextField("Title", text: $title)
                    Picker("Day", selection: $dayIndex) {
                        ForEach(0..<numberOfDays, id: \.self) { day in
                            Text("Day \(day + 1)").tag(day)
                        }
                    }
                }
                Section(header: Text("Notes")) {
                    TextEditor(text: $text)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if entry == nil {
                            let newEntry = JournalEntry(tripID: tripID, dayIndex: dayIndex, title: title.isEmpty ? "Untitled" : title, text: text)
                            store.addJournalEntry(tripID: tripID, entry: newEntry)
                        } else if var existing = entry {
                            existing.title = title.isEmpty ? "Untitled" : title
                            existing.text = text
                            existing.dayIndex = dayIndex
                            store.updateJournalEntry(tripID: tripID, entry: existing)
                        }
                        isPresented = false
                    }
                }
            }
        }
    }
}
