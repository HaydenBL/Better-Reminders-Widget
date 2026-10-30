//
//  ContentView.swift
//  Better Reminders Widget
//
//  Created by Hayden Lueck on 2026-10-29.
//

import SwiftUI
import EventKit
import WidgetKit

struct ContentView: View {
    @State private var hasAccess = EKEventStore.authorizationStatus(for: .reminder) == .fullAccess

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasAccess ? "checkmark.circle.fill" : "list.bullet")
                .font(.largeTitle) +
                .foregroundStyle(.tint)
            Text(hasAccess ? "Reminders access granted" : "Reminders access needed")
                .font(.headline)

            if !hasAccess {
                Button("Grant Access") {
                    Task {
                        hasAccess = (try? await EKEventStore().requestFullAccessToReminders()) ?? false
                        // Let the widget refresh now that it can read reminders.
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
