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
    let hasTime: Bool

    /// Timed reminders are overdue once their time passes; all-day ones only from the next day.
    func isOverdue(at now: Date) -> Bool {
        hasTime ? dueDate <= now : dueDate < Calendar.current.startOfDay(for: now)
    }
}

struct ReminderEntry: TimelineEntry {
    let date: Date
    let reminders: [ReminderItem]
    var hasAccess = true

    static let sample = ReminderEntry(date: .now, reminders: [
        ReminderItem(id: "1", title: "Buy milk", dueDate: .now.addingTimeInterval(-3600), hasTime: true),
        ReminderItem(id: "2", title: "Call dentist", dueDate: .now, hasTime: false),
        ReminderItem(id: "3", title: "Pay rent", dueDate: .now.addingTimeInterval(3600), hasTime: true),
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
            // Extra entries at each upcoming due time flip that reminder's bullet to "!"
            // on time, without waiting for a refresh.
            let dueEntries = entry.reminders
                .filter { $0.hasTime && $0.dueDate > entry.date }
                .map { ReminderEntry(date: $0.dueDate, reminders: entry.reminders) }
            completion(Timeline(entries: [entry] + dueEntries, policy: .after(nextUpdate)))
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
                    dueDate: dueDate,
                    hasTime: components.hour != nil)
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
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header like the system widget: full size with 0–1 reminders,
                // smaller with 2, and dropped at 3 to make room.
                if entry.reminders.count <= 2 {
                    Text("Today")
                        .font(.system(entry.reminders.count == 2 ? .caption : .headline,
                                      design: .rounded, weight: .bold))
                }
                if entry.reminders.isEmpty {
                    Text("No reminders")
                }
                ForEach(entry.reminders.prefix(3)) { reminder in
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        // Hidden copies of both markers keep titles lined up whichever one shows.
                        ZStack {
                            Text("•").hidden()
                            Text("!").bold().hidden()
                            if reminder.isOverdue(at: entry.date) {
                                Text("!").bold()
                            } else {
                                Text("•")
                            }
                        }
                        Text(reminder.title)
                            .lineLimit(1)
                    }
                }
            }
            // Full-size text fits 2 lines; shrink only when showing 3.
            .font(entry.reminders.count > 2 ? .caption : nil)
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
    ReminderEntry(date: .now, reminders: Array(ReminderEntry.sample.reminders.prefix(2)))
    ReminderEntry(date: .now, reminders: Array(ReminderEntry.sample.reminders.prefix(1)))
    ReminderEntry(date: .now, reminders: [])
    ReminderEntry(date: .now, reminders: [], hasAccess: false)
}
