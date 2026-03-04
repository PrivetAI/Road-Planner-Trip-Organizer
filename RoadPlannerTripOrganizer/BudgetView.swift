import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddExpense = false

    var trip: Trip? { store.selectedTrip }
    var tripID: UUID? { store.selectedTripID }

    var expenseList: [Expense] {
        guard let id = tripID else { return [] }
        return (store.expenses[id] ?? []).sorted { $0.date > $1.date }
    }

    var totalSpent: Double {
        guard let id = tripID else { return 0 }
        return store.totalSpent(tripID: id)
    }

    var remaining: Double {
        (trip?.budget ?? 0) - totalSpent
    }

    var body: some View {
        VStack(spacing: 0) {
            GoldHeaderView(title: "Budget") {
                Button(action: { showAddExpense = true }) {
                    PlusIcon()
                        .fill(Theme.white)
                        .frame(width: 18, height: 18)
                }
            }

            ZStack {
                Theme.lightGray.ignoresSafeArea()
                if trip == nil {
                    VStack(spacing: 12) {
                        WalletIcon()
                            .fill(Theme.gold.opacity(0.4))
                            .frame(width: 50, height: 50)
                        Text("Select a trip first")
                            .foregroundColor(Theme.darkGray)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Summary cards
                            HStack(spacing: 12) {
                                budgetCard(title: "Budget", value: trip?.budget ?? 0, color: Theme.gold)
                                budgetCard(title: "Spent", value: totalSpent, color: Theme.darkGray)
                                budgetCard(title: "Left", value: remaining, color: remaining >= 0 ? Color.green : Color.red)
                            }
                            .padding(.horizontal)

                            // Category breakdown
                            if let id = tripID {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("By Category")
                                        .font(.headline)
                                        .foregroundColor(Theme.darkGray)
                                    let cats = store.spentByCategory(tripID: id)
                                    let maxVal = cats.map { $0.1 }.max() ?? 1
                                    ForEach(cats, id: \.0) { cat, amount in
                                        HStack {
                                            Text(cat.rawValue)
                                                .font(.caption)
                                                .foregroundColor(Theme.darkGray)
                                                .frame(width: 100, alignment: .leading)
                                            GeometryReader { geo in
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Theme.gold)
                                                    .frame(width: maxVal > 0 ? geo.size.width * CGFloat(amount / maxVal) : 0, height: 16)
                                            }
                                            .frame(height: 16)
                                            Text(String(format: "$%.0f", amount))
                                                .font(.caption.bold())
                                                .foregroundColor(Theme.darkGray)
                                                .frame(width: 50, alignment: .trailing)
                                        }
                                    }
                                }
                                .padding()
                                .background(Theme.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }

                            // Expense list
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expenses")
                                    .font(.headline)
                                    .foregroundColor(Theme.darkGray)
                                if expenseList.isEmpty {
                                    Text("No expenses yet")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.darkGray.opacity(0.5))
                                        .padding(.vertical, 20)
                                } else {
                                    ForEach(expenseList) { expense in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(expense.category.rawValue)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Theme.darkGray)
                                                if !expense.note.isEmpty {
                                                    Text(expense.note)
                                                        .font(.caption)
                                                        .foregroundColor(Theme.darkGray.opacity(0.7))
                                                }
                                            }
                                            Spacer()
                                            Text(String(format: "$%.2f", expense.amount))
                                                .font(.subheadline.bold())
                                                .foregroundColor(Theme.gold)
                                        }
                                        .padding(.vertical, 4)
                                        Divider()
                                    }
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
        .sheet(isPresented: $showAddExpense) {
            AddExpenseSheet(isPresented: $showAddExpense)
                .environmentObject(store)
        }
    }

    func budgetCard(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.darkGray.opacity(0.7))
            Text(String(format: "$%.0f", value))
                .font(.headline.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.white)
        .cornerRadius(12)
    }
}

struct AddExpenseSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var amountStr = ""
    @State private var category: ExpenseCategory = .food
    @State private var note = ""
    @State private var date = Date()

    var body: some View {
        NavigationView {
            Form {
                TextField("Amount ($)", text: $amountStr)
                    .keyboardType(.decimalPad)
                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                TextField("Note", text: $note)
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let tripID = store.selectedTripID,
                              let amount = Double(amountStr), amount > 0 else { return }
                        let expense = Expense(amount: amount, category: category, note: note, date: date)
                        store.addExpense(tripID: tripID, expense: expense)
                        isPresented = false
                    }
                }
            }
        }
    }
}
