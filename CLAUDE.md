# Better Reminders Widget

A read-only replacement for the iOS Reminders **Lock Screen** widget. The system widget has checkboxes that are easy to tap by accident; this one shows reminders but never completes them.

## Scope
- **Only one widget size: `.accessoryRectangular`** (the 2-slot widget under the clock). No circular, inline, or Home Screen sizes.
- **No interactivity.** Never add `Button`/`Toggle` with an App Intent to the widget. Tapping the widget should open the Reminders app (via `.widgetURL`).

## Design decisions
- **Which reminders:** incomplete reminders due today or overdue (like the system "Today" list). No-due-date reminders are hidden.
- **Lists:** all lists combined. No list picker for now.
- **Layout:** up to 3 reminder titles, one per line, no due times (times didn't fit on device). Sorted by due date, overdue first. Default font when there are 1–2 reminders, `.caption` when there are 3+. With 1–2, it also drops to `.caption` if any title (or the whole stack) would not fit at full size — done with `ViewThatFits(in: [.horizontal, .vertical])`. A "Today" header in bold SF Pro Rounded (`.system(_, design: .rounded, weight: .bold)`) sits on top, copying the system widget: `.headline` size with 0–1 reminders, `.caption` with 2, none with 3+.
- **Markers:** each line starts with `•`, or a bold `!` if overdue. Timed reminders are overdue once their time passes; all-day ones only from the next day (matches Reminders). The timeline adds entries at upcoming due times so the `!` appears on time.
- **Empty state:** the "Today" header with "No reminders" under it in the normal font.

## Structure
- `Better Reminders Widget/` — host app. Its only job is requesting Reminders access (`ContentView.swift`) so the widget can read them.
- `Safe Reminders Widget/` — WidgetKit extension (target `Safe Reminders WidgetExtension`). `Safe_Reminders_Widget.swift` holds the provider, entry, view, and widget config.
- Project file is Xcode's JSON-style `Better Reminders Widget.xcodeproj/project.xcproj` (not `project.pbxproj`). Info.plist values are set via `INFOPLIST_KEY_*` build settings there.
- `NSRemindersFullAccessUsageDescription` is set on both targets.
- App icon: `Better Reminders Widget/SafeReminders.icon` (Icon Composer bundle: two white dot-and-bar rows plus a "+" on a blue gradient; SVG layers in `Assets/`). The app target's `ASSETCATALOG_COMPILER_APPICON_NAME` is `SafeReminders`.

## Notes
- Data comes from EventKit (`EKEventStore`, `EKReminder`). Access is granted in the app; the widget inherits it.
- **Opening Reminders on tap:** `widgetURL` always opens the containing app (tested: pointing it straight at `x-apple-reminderkit://` just opened our app). So the widget uses `saferemindersapp://open-reminders`, and the app's `.onOpenURL` forwards to `x-apple-reminderkit://` (fallback `x-apple-reminder://`). Both Reminders schemes are undocumented. `OpenURLIntent` isn't an alternative: it only supports your own universal links.
- **Expiry tracking:** the app target depends on `SideloadKit` (from the Sideboard repo) and calls `SideloadReporter.report()` in the `App` init. That writes this install's profile expiry to the App Group `group.se.haydenblai.sideload` so the Sideboard app can show it. Only the app target has the App Group; the widget doesn't need it.
- Deployment target is iOS 27.2.
- SourceKit may show "unavailable in macOS" errors for accessory families — false positives; the iOS build is fine.
- The user commits changes themselves.

## Status / next steps
1. ~~Project setup, permission text, Grant Access screen, Lock Screen-only widget~~ (done)
2. ~~EventKit fetch of today's + overdue incomplete reminders~~ (done, needs on-device check)
3. ~~Rectangular view: 2 reminders + times, "All done" empty state~~ (done, needs on-device check)
4. `.widgetURL` to open Reminders; test on device
5. Refresh the widget when reminders change. Partly done: the timeline asks for a reload every 15 min (iOS may stretch this, with a budget of roughly 40–70/day), and the app reloads all timelines whenever it becomes active. A widget can't observe Reminders changes while our app isn't running, so edits made in Reminders show up on the next scheduled refresh.
6. Later, optional: configuration intent to choose which list to show
