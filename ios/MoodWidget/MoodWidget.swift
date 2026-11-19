import SwiftUI
import UIKit
import WidgetKit

// Home screen widget: today's dominant mood face and the tap count.
// The Flutter app writes day, mood, count, link and face_png with the home_widget package into
// the shared app group. A snapshot of an earlier day shows an empty widget after midnight.
// Colors come from WidgetColors.g.swift (generated from design/tokens.json). Flat: no gradient,
// shadow or glow.

private let appGroup = "group.com.example.moodClicker"

struct MoodEntry: TimelineEntry {
    let date: Date
    let count: Int
    let link: URL
    let face: UIImage?
}

struct MoodProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoodEntry {
        MoodEntry(date: Date(), count: 0, link: MoodProvider.openApp, face: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MoodEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoodEntry>) -> Void) {
        let midnight = Calendar.current.nextDate(
            after: Date(), matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [currentEntry()], policy: .after(midnight)))
    }

    private static let openApp = URL(string: "moodclicker://tap")!

    private func currentEntry() -> MoodEntry {
        let defaults = UserDefaults(suiteName: appGroup)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let fresh = defaults?.string(forKey: "day") == formatter.string(from: Date())
        guard fresh, let defaults = defaults else {
            return MoodEntry(date: Date(), count: 0, link: MoodProvider.openApp, face: nil)
        }
        let link = defaults.string(forKey: "link").flatMap { URL(string: $0) } ?? MoodProvider.openApp
        let face = defaults.string(forKey: "face_png").flatMap { UIImage(contentsOfFile: $0) }
        return MoodEntry(date: Date(), count: defaults.integer(forKey: "count"), link: link, face: face)
    }
}

struct MoodWidgetView: View {
    let entry: MoodEntry

    var body: some View {
        VStack(spacing: 4) {
            if let face = entry.face {
                Image(uiImage: face)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
            }
            Text("\(entry.count)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(WidgetColors.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(entry.link)
        .background(WidgetColors.ground)
    }
}

@main
struct MoodWidget: Widget {
    let kind = "MoodWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoodProvider()) { entry in
            if #available(iOS 17.0, *) {
                MoodWidgetView(entry: entry).containerBackground(WidgetColors.ground, for: .widget)
            } else {
                MoodWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("widget_name")
        .description("widget_description")
        .supportedFamilies([.systemSmall])
    }
}
