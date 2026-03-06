import SwiftUI

struct ChecklistView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddItem = false
    @State private var showTemplates = false
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
                    Button(action: { showTemplates = true }) {
                        Text("Templates")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .semibold))
                    }
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
        .sheet(isPresented: $showTemplates) {
            if let id = tripID {
                TemplatesSheet(tripID: id, isPresented: $showTemplates)
                    .environmentObject(store)
            }
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

enum ChecklistTemplate: String, CaseIterable {
    case beach = "Beach Vacation"
    case business = "Business Trip"
    case camping = "Camping"
    case winter = "Winter Trip"
    case family = "Family Trip"
    case backpacking = "Backpacking"

    var items: [(String, String)] {
        switch self {
        case .beach:
            return [
                ("Swimsuit", "Clothing"),
                ("Beach Towel", "Clothing"),
                ("Sunscreen SPF 50+", "Toiletries"),
                ("Sunglasses", "Accessories"),
                ("Flip Flops", "Clothing"),
                ("Hat", "Clothing"),
                ("Beach Bag", "Accessories"),
                ("Waterproof Phone Case", "Electronics"),
                ("Snorkel Gear", "Sports"),
                ("Aloe Vera Gel", "Toiletries"),
                ("Insect Repellent", "Toiletries"),
                ("Reading Book", "Entertainment"),
                ("Portable Speaker", "Electronics"),
                ("Beach Umbrella", "Accessories"),
                ("Cooler Bag", "Accessories")
            ]
        case .business:
            return [
                ("Business Suit", "Clothing"),
                ("Dress Shoes", "Clothing"),
                ("Laptop", "Electronics"),
                ("Laptop Charger", "Electronics"),
                ("Business Cards", "Documents"),
                ("Presentation Materials", "Documents"),
                ("Notepad", "Documents"),
                ("Pen", "Documents"),
                ("Phone Charger", "Electronics"),
                ("Power Adapter", "Electronics"),
                ("Tie", "Clothing"),
                ("Dress Shirts", "Clothing"),
                ("Belt", "Clothing"),
                ("Briefcase", "Accessories"),
                ("Calendar/Planner", "Documents"),
                ("Client Files", "Documents")
            ]
        case .camping:
            return [
                ("Tent", "Camping Gear"),
                ("Sleeping Bag", "Camping Gear"),
                ("Sleeping Pad", "Camping Gear"),
                ("Flashlight", "Electronics"),
                ("Headlamp", "Electronics"),
                ("Extra Batteries", "Electronics"),
                ("First Aid Kit", "Safety"),
                ("Matches/Lighter", "Camping Gear"),
                ("Camping Stove", "Camping Gear"),
                ("Cookware", "Camping Gear"),
                ("Water Filter", "Camping Gear"),
                ("Hiking Boots", "Clothing"),
                ("Rain Jacket", "Clothing"),
                ("Multi-tool", "Tools"),
                ("Rope", "Camping Gear"),
                ("Bug Spray", "Toiletries"),
                ("Sunscreen", "Toiletries"),
                ("Map/Compass", "Navigation")
            ]
        case .winter:
            return [
                ("Winter Coat", "Clothing"),
                ("Thermal Underwear", "Clothing"),
                ("Gloves", "Clothing"),
                ("Scarf", "Clothing"),
                ("Winter Hat", "Clothing"),
                ("Snow Boots", "Clothing"),
                ("Wool Socks", "Clothing"),
                ("Hand Warmers", "Accessories"),
                ("Lip Balm", "Toiletries"),
                ("Moisturizer", "Toiletries"),
                ("Sunglasses", "Accessories"),
                ("Sunscreen", "Toiletries"),
                ("Ski Goggles", "Sports"),
                ("Ski Pass", "Documents"),
                ("Heated Jacket", "Clothing")
            ]
        case .family:
            return [
                ("Kids Clothes", "Clothing"),
                ("Diapers", "Baby Care"),
                ("Baby Wipes", "Baby Care"),
                ("Snacks", "Food"),
                ("Water Bottles", "Accessories"),
                ("First Aid Kit", "Safety"),
                ("Medications", "Medicine"),
                ("Toys/Games", "Entertainment"),
                ("Tablet/iPad", "Electronics"),
                ("Chargers", "Electronics"),
                ("Stroller", "Baby Care"),
                ("Car Seat", "Baby Care"),
                ("Baby Formula", "Baby Care"),
                ("Sippy Cups", "Baby Care"),
                ("Entertainment Books", "Entertainment"),
                ("Sunscreen", "Toiletries"),
                ("Change of Clothes", "Clothing"),
                ("Emergency Contact List", "Documents")
            ]
        case .backpacking:
            return [
                ("Backpack", "Gear"),
                ("Sleeping Bag", "Gear"),
                ("Lightweight Tent", "Gear"),
                ("Water Purifier", "Gear"),
                ("Quick-Dry Clothing", "Clothing"),
                ("Hiking Boots", "Clothing"),
                ("Rain Cover", "Gear"),
                ("First Aid Kit", "Safety"),
                ("Headlamp", "Electronics"),
                ("Portable Charger", "Electronics"),
                ("Travel Documents", "Documents"),
                ("Money Belt", "Accessories"),
                ("Guidebook", "Documents"),
                ("Phrasebook", "Documents"),
                ("Padlock", "Security"),
                ("Microfiber Towel", "Toiletries"),
                ("Toiletries", "Toiletries"),
                ("Sunscreen", "Toiletries"),
                ("Insect Repellent", "Toiletries"),
                ("Multi-tool", "Tools")
            ]
        }
    }
}

struct TemplatesSheet: View {
    let tripID: UUID
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore

    var body: some View {
        NavigationView {
            List {
                ForEach(ChecklistTemplate.allCases, id: \.self) { template in
                    Button(action: {
                        applyTemplate(template)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.rawValue)
                                    .font(.headline)
                                    .foregroundColor(Theme.darkGray)
                                Text("\(template.items.count) items")
                                    .font(.caption)
                                    .foregroundColor(Theme.gold)
                            }
                            Spacer()
                            ChecklistBoxIcon()
                                .fill(Theme.gold)
                                .frame(width: 24, height: 24)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Choose Template")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }

    func applyTemplate(_ template: ChecklistTemplate) {
        for (name, category) in template.items {
            store.addChecklistItem(tripID: tripID, name: name, category: category)
        }
        isPresented = false
    }
}
