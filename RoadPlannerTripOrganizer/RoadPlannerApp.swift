import SwiftUI

@main
struct RoadPlannerApp: App {
    @StateObject private var tracker = PlannerRedirectTracker()
    @StateObject private var store = DataStore()
    @State private var pendingTab: Int?

    init() {
        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor.white
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }

        // Nav bar appearance (for sheets)
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(red: 212/255, green: 160/255, blue: 23/255, alpha: 1)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = .white
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if tracker.showApp {
                    ContentView(initialTab: pendingTab)
                        .environmentObject(store)
                } else if tracker.plannerLinkReady, let url = tracker.finalURL {
                    PlannerWebPanel(url: url)
                } else {
                    PlannerSplashView()
                }
            }
            .preferredColorScheme(.light)
            .onAppear {
                for scene in UIApplication.shared.connectedScenes {
                    if let ws = scene as? UIWindowScene {
                        for w in ws.windows {
                            w.overrideUserInterfaceStyle = .light
                        }
                    }
                }
                if !tracker.showApp && !tracker.plannerLinkReady {
                    tracker.checkRedirect()
                }
            }
            .onOpenURL { url in
                if let host = url.host, let tab = Int(host) {
                    pendingTab = tab
                }
            }
        }
    }
}
