import SwiftUI
import FirebaseCore

// AppDelegate is required to call FirebaseApp.configure() before any Firebase
// service is accessed. The @UIApplicationDelegateAdaptor bridges UIKit's
// application lifecycle into SwiftUI's App protocol.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct todolist_3App: App {
    // Register the AppDelegate so Firebase initialises before any view appears.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            // No NavigationView wrapper here — each tab owns its own
            // NavigationStack internally, which avoids double-navigation chrome.
            ContentView()
        }
    }
}
