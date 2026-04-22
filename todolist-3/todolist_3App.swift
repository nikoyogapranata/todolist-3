import SwiftUI
import FirebaseCore

// AppDelegate initialises Firebase before any view or service is accessed.
// The @UIApplicationDelegateAdaptor bridges UIKit's lifecycle into SwiftUI.
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

    // AuthViewModel is the single source of truth for the auth session.
    // @StateObject ensures it lives for the lifetime of the app and isn't
    // re-created on SwiftUI redraws.
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            // RootView reads authVM from the environment and routes to either
            // LandingView (unauthenticated) or ContentView (authenticated).
            RootView()
                .environmentObject(authVM)
        }
    }
}
