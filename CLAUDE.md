# Better Reminders Widget

A read-only replacement for the iOS Reminders **Lock Screen** widget. The system widget has checkboxes that are easy to tap by accident; this one shows reminders but never completes them.

## Scope
- **Only one widget size: `.accessoryRectangular`** (the 2-slot widget under the clock). No circular, inline, or Home Screen sizes.
- **No interactivity.** Never add `Button`/`Toggle` with an App Intent to the widget. Tapping the widget should open the Reminders app (via `.widgetURL`).

## Design decisions
- **Which reminders:** incomplete reminders due today or overdue (like the system "Today" list). No-due-date reminders are hidden.
- **Lists:** all lists combined. No list picker for now.
- **Layout:** 2 reminders, each with its due time on the right:
  ```
  Buy milk      9:00
  Call dentist  14:30
  ```
  Sorted by due date, overdue first. All-day reminders (no time) show no time; overdue ones from a past day show a short date instead of a time.
- **Empty state:** checkmark icon + "All done".

## Structure
- `Better Reminders Widget/` — host app. Its only job is requesting Reminders access (`ContentView.swift`) so the widget can read them.
- `Safe Reminders Widget/` — WidgetKit extension (target `Safe Reminders WidgetExtension`). `Safe_Reminders_Widget.swift` holds the provider, entry, view, and widget config.
- Project file is Xcode's JSON-style `Better Reminders Widget.xcodeproj/project.xcproj` (not `project.pbxproj`). Info.plist values are set via `INFOPLIST_KEY_*` build settings there.
- `NSRemindersFullAccessUsageDescription` is set on both targets.

## Notes
- Data comes from EventKit (`EKEventStore`, `EKReminder`). Access is granted in the app; the widget inherits it.
- `x-apple-reminderkit://` (to open Reminders) is undocumented — verify on device and keep a fallback (open host app, which opens Reminders).
- Deployment target is iOS 27.2.
- SourceKit may show "unavailable in macOS" errors for accessory families — false positives; the iOS build is fine.
- The user commits changes themselves.

## Status / next steps
1. ~~Project setup, permission text, Grant Access screen, Lock Screen-only widget~~ (done)
2. Replace the template emoji provider with EventKit fetching of today's + overdue incomplete reminders (see Design decisions)
3. Build the rectangular view: 2 reminders + times, "All done" empty state
4. `.widgetURL` to open Reminders; test on device
5. Refresh the widget when reminders change
6. Later, optional: configuration intent to choose which list to show
