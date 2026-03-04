import SwiftUI

struct ChecklistView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddItem = false
    @State private var newItemName = ""
    @State private var newItemCategory = "Custom"

    var tripID: UUID? { store.selectedTripID }

    var items: [ChecklistItem] {
        guard let id = tripID else { return [] }
        return store.checklists[id] ?? []
    }

    var categories: [String] {
        let cats = Set(items.map { $0.category })
        return cats.sorted()
    }

    var checkedCount: Int { items.filter { $0.isChecked }.count }
    var progress: Double { items.isEmpty ? 0 : Double(checkedCount) / Double(items.count) }

    var body: some View {
        VStack(spacing: 0) {
            GoldHeaderView(title: "Checklist") {
                HStack(spacing: 12) {
                    Button(action: { showAddItem = true }) {
                        PlusIcon()
                            .fill(Theme.white)
                            .frame(width: 18, height: 18)
                    }
                    Menu {
                        Button("Reset Checklist") {
                            if let id = tripID {
                                store.resetChecklist(tripID: id)
                            }
                        }
                    } label: {
                        Circle()
                            .fill(Theme.white)
                            .frame(width: 22, height: 22)
                            .overlay(
                                VStack(spacing: 2) {
                                    Circle().fill(Theme.gold).frame(width: 4, height: 4)
                                    Circle().fill(Theme.gold).frame(width: 4, height: 4)
                                    Circle().fill(Theme.gold).frame(width: 4, height: 4)
                                }
                            )
                    }
                }
            }

            ZStack {
                Theme.lightGray.ignoresSafeArea()
                if tripID == nil {
                    noTripView
                } else {
                    VStack(spacing: 0) {
                        // Progress bar
                        VStack(spacing: 4) {
                            HStack {
                                Text("Packed: \(Int(progress * 100))%")
                                    .font(.subheadline.bold())
                                    .foregroundColor(Theme.darkGray)
                                Spacer()
                                Text("\(checkedCount)/\(items.count)")
                                    .font(.caption)
                                    .foregroundColor(Theme.darkGray.opacity(0.7))
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Theme.lightGray)
                                        .frame(height: 10)
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Theme.gold)
                                        .frame(width: geo.size.width * CGFloat(progress), height: 10)
                                }
                            }
                            .frame(height: 10)
                        }
                        .padding()
                        .background(Theme.white)

                        List {
                            ForEach(categories, id: \.self) { cat in
                                Section(header: Text(cat).foregroundColor(Theme.gold)) {
                                    ForEach(items.filter { $0.category == cat }) { item in
                                        Button(action: {
                                            if let id = tripID {
                                                store.toggleChecklistItem(tripID: id, itemID: item.id)
                                            }
                                        }) {
                                            HStack {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(Theme.gold, lineWidth: 2)
                                                        .frame(width: 22, height: 22)
                                                    if item.isChecked {
                                                        RoundedRectangle(cornerRadius: 4)
                                                            .fill(Theme.gold)
                                                            .frame(width: 22, height: 22)
                                                        ChecklistBoxIcon()
                                                            .stroke(Color.white, lineWidth: 2)
                                                            .frame(width: 14, height: 14)
                                                    }
                                                }
                                                Text(item.name)
                                                    .foregroundColor(item.isChecked ? Theme.darkGray.opacity(0.5) : Theme.darkGray)
                                                    .strikethrough(item.isChecked)
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
        }
        .sheet(isPresented: $showAddItem) {
            addItemSheet
        }
    }

    var noTripView: some View {
        VStack(spacing: 12) {
            ChecklistBoxIcon()
                .fill(Theme.gold.opacity(0.4))
                .frame(width: 50, height: 50)
            Text("Select a trip first")
                .foregroundColor(Theme.darkGray)
        }
    }

    var addItemSheet: some View {
        NavigationView {
            Form {
                TextField("Item Name", text: $newItemName)
                Picker("Category", selection: $newItemCategory) {
                    ForEach(["Documents", "Clothing", "Electronics", "Medicine", "Toiletries", "Custom"], id: \.self) {
                        Text($0)
                    }
                }
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showAddItem = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if let id = tripID, !newItemName.isEmpty {
                            store.addChecklistItem(tripID: id, name: newItemName, category: newItemCategory)
                            newItemName = ""
                        }
                        showAddItem = false
                    }
                }
            }
        }
    }
}
