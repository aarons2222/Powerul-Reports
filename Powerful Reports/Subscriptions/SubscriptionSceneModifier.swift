import SwiftUI

struct SubscriptionSceneModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase: ScenePhase
    
    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    // Refresh subscription status when app becomes active
                    SubscriptionPersistence.shared.refreshCache()
                    Task {
                        await ProductSubscription.shared.publicRefreshSubscriptionStatus()
                    }
                }
            }
    }
}

extension View {
    func handleSubscriptionRefresh() -> some View {
        modifier(SubscriptionSceneModifier())
    }
}
