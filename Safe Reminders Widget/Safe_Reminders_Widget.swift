//
//  Safe_Reminders_Widget.swift
//  Safe Reminders Widget
//
//  Created by Hayden Lueck on 2026-10-29.
//

import WidgetKit
import SwiftUI
import EventKit

struct ReminderItem: Identifiable {
    let id: String
    let title: String
    let dueDate: Date
}

struct ReminderEntry: TimelineEntry {
    let date: Date
    let reminders: [ReminderItem]
    var hasAccess = true

    static let sample = ReminderEntry(date: .now, reminders: [
        ReminderItem(id: "1", title: "Buy milk", dueDate: .now),
        ReminderItem(id: "2", title: "Call dentist", dueDate: .now),
        ReminderItem(id: "3", title: "Pay rent", dueDate: .now),
    ])
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ReminderEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (ReminderEntry) -> ()) {
        if context.isPreview {
            completion(.sample)
        } else {
            fetchEntry(completion: completion)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        fetchEntry { entry in
            // Refresh periodically so the list stays current and rolls over at midnight.
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date)!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    /// Fetches incomplete reminders that are due today or overdue, across all lists.
    private func fetchEntry(completion: @escaping (ReminderEntry) -> ()) {
        let now = Date()
        guard EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else {
            completion(ReminderEntry(date: now, reminders: [], hasAccess: false))
            return
        }

        let calendar = Calendar.current
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let store = EKEventStore()
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil, ending: endOfToday, calendars: nil)

        store.fetchReminders(matching: predicate) { reminders in
            let items = (reminders ?? []).compactMap { reminder -> ReminderItem? in
                guard let components = reminder.dueDateComponents,
                      let dueDate = calendar.date(from: components),
                      dueDate < endOfToday else { return nil }
                return ReminderItem(
                    id: reminder.calendarItemIdentifier,
                    title: reminder.title ?? "",
                    dueDate: dueDate)
            }
            .sorted { $0.dueDate < $1.dueDate }

            // Referencing the store keeps it alive until the fetch finishes.
            withExtendedLifetime(store) {
                completion(ReminderEntry(date: now, reminders: items))
            }
        }
    }
}

struct Safe_Reminders_WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if !entry.hasAccess {
            Label("Open the app to allow access", systemImage: "lock")
                .font(.caption)
        } else if entry.reminders.isEmpty {
            Label("All done", systemImage: "checkmark.circle")
                .font(.headline)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(entry.reminders.prefix(3)) { reminder in
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("•")
                        Text(reminder.title)
                            .lineLimit(1)
                    }
                }
            }
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct Safe_Reminders_Widget: Widget {
    let kind: String = "Safe_Reminders_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            Safe_Reminders_WidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
                // Widget taps always open our own app; it forwards to Apple's Reminders app.
                .widgetURL(URL(string: "saferemindersapp://open-reminders"))
        }
        .configurationDisplayName("Safe Reminders")
        .description("Shows your reminders without checkboxes.")
        .supportedFamilies([.accessoryRectangular])
    }
}

#Preview(as: .accessoryRectangular) {
    Safe_Reminders_Widget()
} timeline: {
    ReminderEntry.sample
    ReminderEntry(date: .now, reminders: [])
    ReminderEntry(date: .now, reminders: [], hasAccess: false)
}
