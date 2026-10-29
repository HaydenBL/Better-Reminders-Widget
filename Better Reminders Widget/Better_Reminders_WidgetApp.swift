//
//  Better_Reminders_WidgetApp.swift
//  Better Reminders Widget
//
//  Created by Hayden Lueck on 2026-10-29.
//

import SwiftUI
import WidgetKit

@main
struct Better_Reminders_WidgetApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Widgets can only open their own app, so the widget sends us here
                    // and we pass the tap on to Apple's Reminders app.
                    if url.host == "open-reminders" {
                        openRemindersApp()
                    }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            // Reloads requested while the app is in the foreground don't use up the
            // widget's daily refresh budget, so refresh every time the app opens.
            if phase == .active {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    private func openRemindersApp() {
        Task {
            // Both schemes are undocumented; the older one is a fallback.
            if await !UIApplication.shared.open(URL(string: "x-apple-reminderkit://")!) {
                await UIApplication.shared.open(URL(string: "x-apple-reminder://")!)
            }
        }
    }
}
