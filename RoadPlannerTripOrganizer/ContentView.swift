import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    var initialTab: Int?
    @State private var selectedTab = 0
    
    init(initialTab: Int? = nil) {
        self.initialTab = initialTab
        let savedTab = UserDefaults.standard.integer(forKey: "rp_debug_tab")
        if savedTab > 0 {
            _selectedTab = State(initialValue: savedTab)
            UserDefaults.standard.removeObject(forKey: "rp_debug_tab")
        } else if let tab = initialTab {
            _selectedTab = State(initialValue: tab)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MyTripsView()
                .tabItem {
                    shapeImage(SuitcaseIcon())
                    Text("My Trips")
                }
                .tag(0)

            ChecklistView()
                .tabItem {
                    shapeImage(ChecklistBoxIcon())
                    Text("Checklist")
                }
                .tag(1)

            ItineraryView()
                .tabItem {
                    shapeImage(MapPinIcon())
                    Text("Itinerary")
                }
                .tag(2)

            BudgetView()
                .tabItem {
                    shapeImage(WalletIcon())
                    Text("Budget")
                }
                .tag(3)

            SummaryView()
                .tabItem {
                    shapeImage(FlagIcon())
                    Text("Summary")
                }
                .tag(4)
        }
        .accentColor(Theme.gold)
        .preferredColorScheme(.light)
        .onAppear {
            if let tab = initialTab {
                selectedTab = tab
            }
        }
        .onOpenURL { url in
            if let host = url.host, let tab = Int(host) {
                selectedTab = tab
            }
        }
    }
}
