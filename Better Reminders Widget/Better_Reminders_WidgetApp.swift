//
//  Better_Reminders_WidgetApp.swift
//  Better Reminders Widget
//
//  Created by Hayden Lueck on 2026-10-29.
//

import SwiftUI

@main
struct Better_Reminders_WidgetApp: App {
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
