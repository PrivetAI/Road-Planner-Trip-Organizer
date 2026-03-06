import SwiftUI

enum WeightLimit: String, CaseIterable {
    case carryon = "Carry-on (7kg)"
    case checked = "Checked (23kg)"
    case custom = "Custom"
    
    var defaultValue: Double {
        switch self {
        case .carryon: return 7.0
        case .checked: return 23.0
        case .custom: return 20.0
        }
    }
}

struct WeightView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedLimit: WeightLimit = .checked
    @State private var customLimit: Double = 20.0
    @State private var showEditItem: ChecklistItem?

    var tripID: UUID? { store.selectedTripID }
    
    var items: [ChecklistItem] {
        guard let id = tripID else { return [] }
        return store.checklists[id] ?? []
    }
    
    var itemsWithWeight: [ChecklistItem] {
        items.filter { $0.weight != nil && $0.weight! > 0 }
    }
    
    var totalPackedWeight: Double {
        guard let id = tripID else { return 0 }
        return store.totalPackedWeight(tripID: id)
    }
    
    var currentLimit: Double {
        selectedLimit == .custom ? customLimit : selectedLimit.defaultValue
    }
    
    var progress: Double {
        currentLimit > 0 ? min(totalPackedWeight / currentLimit, 1.5) : 0
    }
    
    var isOverLimit: Bool {
        totalPackedWeight > currentLimit
    }

    var body: some View {
        VStack(spacing: 0) {
            GoldHeaderView(title: "Packing Weight") {
                EmptyView()
            }

            ZStack {
                Theme.lightGray.ignoresSafeArea()
                if tripID == nil {
                    VStack(spacing: 12) {
                        WeightIcon()
                            .fill(Theme.gold.opacity(0.4))
                            .frame(width: 50, height: 50)
                        Text("Select a trip first")
                            .foregroundColor(Theme.darkGray)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Weight limit selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Weight Limit")
                                    .font(.headline)
                                    .foregroundColor(Theme.darkGray)
                                
                                Picker("Limit", selection: $selectedLimit) {
                                    ForEach(WeightLimit.allCases, id: \.self) { limit in
                                        Text(limit.rawValue).tag(limit)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                
                                if selectedLimit == .custom {
                                    HStack {
                                        Text("Custom Limit (kg):")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.darkGray)
                                        TextField("kg", value: $customLimit, formatter: NumberFormatter())
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .frame(width: 80)
                                    }
                                }
                            }
                            .padding()
                            .background(Theme.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Progress card
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Total Packed Weight")
                                        .font(.headline)
                                        .foregroundColor(Theme.darkGray)
                                    Spacer()
                                    Text(String(format: "%.1f / %.1f kg", totalPackedWeight, currentLimit))
                                        .font(.headline.bold())
                                        .foregroundColor(isOverLimit ? .red : Theme.gold)
                                }
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Theme.lightGray)
                                            .frame(height: 24)
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isOverLimit ? Color.red : Theme.gold)
                                            .frame(width: geo.size.width * CGFloat(min(progress, 1.0)), height: 24)
                                    }
                                }
                                .frame(height: 24)
                                
                                if isOverLimit {
                                    HStack {
                                        Text("Over limit by \(String(format: "%.1f kg", totalPackedWeight - currentLimit))")
                                            .font(.caption.bold())
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                }
                            }
                            .padding()
                            .background(Theme.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Packed items
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Packed Items with Weight")
                                    .font(.headline)
                                    .foregroundColor(Theme.darkGray)
                                
                                if itemsWithWeight.isEmpty {
                                    Text("No items with weight assigned")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.darkGray.opacity(0.5))
                                        .padding(.vertical, 20)
                                } else {
                                    ForEach(itemsWithWeight.filter { $0.isChecked }) { item in
                                        Button(action: { showEditItem = item }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(item.name)
                                                        .font(.subheadline.bold())
                                                        .foregroundColor(Theme.darkGray)
                                                    Text(item.category)
                                                        .font(.caption)
                                                        .foregroundColor(Theme.gold)
                                                }
                                                Spacer()
                                                Text(String(format: "%.1f kg", item.weight ?? 0))
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Theme.darkGray)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                        Divider()
                                    }
                                }
                                
                                if !itemsWithWeight.filter({ !$0.isChecked }).isEmpty {
                                    Text("Not Packed Yet")
                                        .font(.subheadline.bold())
                                        .foregroundColor(Theme.darkGray.opacity(0.6))
                                        .padding(.top, 8)
                                    
                                    ForEach(itemsWithWeight.filter { !$0.isChecked }) { item in
                                        Button(action: { showEditItem = item }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(item.name)
                                                        .font(.subheadline)
                                                        .foregroundColor(Theme.darkGray.opacity(0.6))
                                                    Text(item.category)
                                                        .font(.caption)
                                                        .foregroundColor(Theme.gold.opacity(0.6))
                                                }
                                                Spacer()
                                                Text(String(format: "%.1f kg", item.weight ?? 0))
                                                    .font(.subheadline)
                                                    .foregroundColor(Theme.darkGray.opacity(0.6))
                                            }
                                            .padding(.vertical, 4)
                                        }
                                        Divider()
                                    }
                                }
                            }
                            .padding()
                            .background(Theme.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Add weight to items
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Add Weight to Items")
                                    .font(.headline)
                                    .foregroundColor(Theme.darkGray)
                                Text("Tap items below to assign weight")
                                    .font(.caption)
                                    .foregroundColor(Theme.darkGray.opacity(0.6))
                                
                                ForEach(items.filter { $0.weight == nil || $0.weight == 0 }) { item in
                                    Button(action: { showEditItem = item }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name)
                                                    .font(.subheadline)
                                                    .foregroundColor(Theme.darkGray)
                                                Text(item.category)
                                                    .font(.caption)
                                                    .foregroundColor(Theme.gold)
                                            }
                                            Spacer()
                                            PlusIcon()
                                                .fill(Theme.gold)
                                                .frame(width: 16, height: 16)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    Divider()
                                }
                            }
                            .padding()
                            .background(Theme.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .sheet(item: $showEditItem) { item in
            WeightEditSheet(item: item, isPresented: Binding(get: { showEditItem != nil }, set: { if !$0 { showEditItem = nil } }))
                .environmentObject(store)
        }
    }
}

struct WeightEditSheet: View {
    let item: ChecklistItem
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var weightStr: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    Text(item.name)
                        .font(.headline)
                    Text(item.category)
                        .font(.subheadline)
                        .foregroundColor(Theme.gold)
                }
                
                Section(header: Text("Weight")) {
                    HStack {
                        TextField("Weight", text: $weightStr)
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundColor(Theme.darkGray.opacity(0.6))
                    }
                }
            }
            .navigationTitle("Set Weight")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let tripID = store.selectedTripID else { return }
                        var updated = item
                        updated.weight = Double(weightStr) ?? 0
                        if updated.weight == 0 {
                            updated.weight = nil
                        }
                        store.updateChecklistItem(tripID: tripID, item: updated)
                        isPresented = false
                    }
                }
            }
            .onAppear {
                if let w = item.weight, w > 0 {
                    weightStr = String(format: "%.1f", w)
                }
            }
        }
    }
}
