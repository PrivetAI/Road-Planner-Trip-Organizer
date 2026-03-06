import SwiftUI

struct DocumentsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddDocument = false
    @State private var editingDocument: TravelDocument?

    var tripID: UUID? { store.selectedTripID }

    var documents: [TravelDocument] {
        guard let id = tripID else { return [] }
        return (store.documents[id] ?? []).sorted { doc1, doc2 in
            if let d1 = doc1.startDate, let d2 = doc2.startDate {
                return d1 < d2
            }
            return doc1.type.rawValue < doc2.type.rawValue
        }
    }

    var groupedDocuments: [(DocumentType, [TravelDocument])] {
        let dict = Dictionary(grouping: documents, by: { $0.type })
        return DocumentType.allCases.compactMap { type in
            guard let docs = dict[type], !docs.isEmpty else { return nil }
            return (type, docs)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            GoldHeaderView(title: "Documents") {
                Button(action: { showAddDocument = true }) {
                    PlusIcon()
                        .fill(Theme.white)
                        .frame(width: 22, height: 22)
                }
            }

            ZStack {
                Theme.lightGray.ignoresSafeArea()
                if tripID == nil {
                    noTripView
                } else if documents.isEmpty {
                    emptyView
                } else {
                    List {
                        ForEach(groupedDocuments, id: \.0) { type, docs in
                            Section(header: Text(type.rawValue).foregroundColor(Theme.gold).font(.headline)) {
                                ForEach(docs) { doc in
                                    Button(action: { editingDocument = doc }) {
                                        DocumentRow(document: doc)
                                    }
                                }
                                .onDelete { offsets in
                                    if let id = tripID {
                                        for offset in offsets {
                                            store.deleteDocument(tripID: id, documentID: docs[offset].id)
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
        .sheet(isPresented: $showAddDocument) {
            if let id = tripID {
                DocumentSheet(tripID: id, document: nil, isPresented: $showAddDocument)
                    .environmentObject(store)
            }
        }
        .sheet(item: $editingDocument) { doc in
            if let id = tripID {
                DocumentSheet(tripID: id, document: doc, isPresented: Binding(
                    get: { editingDocument != nil },
                    set: { if !$0 { editingDocument = nil } }
                ))
                .environmentObject(store)
            }
        }
    }

    var noTripView: some View {
        VStack(spacing: 12) {
            DocumentIcon()
                .fill(Theme.gold.opacity(0.4))
                .frame(width: 50, height: 50)
            Text("Select a trip first")
                .foregroundColor(Theme.darkGray)
        }
    }

    var emptyView: some View {
        VStack(spacing: 12) {
            DocumentIcon()
                .fill(Theme.gold.opacity(0.4))
                .frame(width: 50, height: 50)
            Text("No documents yet")
                .font(.headline)
                .foregroundColor(Theme.darkGray)
            Text("Tap + to add your first document")
                .font(.subheadline)
                .foregroundColor(Theme.darkGray.opacity(0.7))
        }
    }
}

struct DocumentRow: View {
    let document: TravelDocument
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(Theme.gold.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        DocumentIcon()
                            .fill(Theme.gold)
                            .frame(width: 20, height: 20)
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.referenceNumber)
                        .font(.headline)
                        .foregroundColor(Theme.darkGray)
                    if let start = document.startDate, let end = document.endDate {
                        Text("\(dateFormatter.string(from: start)) - \(dateFormatter.string(from: end))")
                            .font(.caption)
                            .foregroundColor(Theme.gold)
                    } else if let start = document.startDate {
                        Text(dateFormatter.string(from: start))
                            .font(.caption)
                            .foregroundColor(Theme.gold)
                    }
                    if !document.notes.isEmpty {
                        Text(document.notes)
                            .font(.caption)
                            .foregroundColor(Theme.darkGray.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct DocumentSheet: View {
    let tripID: UUID
    let document: TravelDocument?
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var type: DocumentType = .flight
    @State private var referenceNumber = ""
    @State private var notes = ""
    @State private var hasStartDate = false
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()

    init(tripID: UUID, document: TravelDocument?, isPresented: Binding<Bool>) {
        self.tripID = tripID
        self.document = document
        self._isPresented = isPresented
        _type = State(initialValue: document?.type ?? .flight)
        _referenceNumber = State(initialValue: document?.referenceNumber ?? "")
        _notes = State(initialValue: document?.notes ?? "")
        _hasStartDate = State(initialValue: document?.startDate != nil)
        _startDate = State(initialValue: document?.startDate ?? Date())
        _hasEndDate = State(initialValue: document?.endDate != nil)
        _endDate = State(initialValue: document?.endDate ?? Date())
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Document Details")) {
                    Picker("Type", selection: $type) {
                        ForEach(DocumentType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    TextField("Reference Number", text: $referenceNumber)
                }
                Section(header: Text("Dates")) {
                    Toggle("Has Start Date", isOn: $hasStartDate)
                    if hasStartDate {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    }
                    Toggle("Has End Date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                }
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(document == nil ? "New Document" : "Edit Document")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if document == nil {
                            let newDoc = TravelDocument(
                                tripID: tripID,
                                type: type,
                                referenceNumber: referenceNumber.isEmpty ? "Untitled" : referenceNumber,
                                startDate: hasStartDate ? startDate : nil,
                                endDate: hasEndDate ? endDate : nil,
                                notes: notes
                            )
                            store.addDocument(tripID: tripID, document: newDoc)
                        } else if var existing = document {
                            existing.type = type
                            existing.referenceNumber = referenceNumber.isEmpty ? "Untitled" : referenceNumber
                            existing.startDate = hasStartDate ? startDate : nil
                            existing.endDate = hasEndDate ? endDate : nil
                            existing.notes = notes
                            store.updateDocument(tripID: tripID, document: existing)
                        }
                        isPresented = false
                    }
                }
            }
        }
    }
}
