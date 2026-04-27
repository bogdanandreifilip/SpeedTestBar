import SwiftUI

@main
struct SpeedTestBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        Settings { EmptyView() }
    }
}
