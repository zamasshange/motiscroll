import WidgetKit
import SwiftUI
import AppIntents
import UIKit

// Reads only the JSON the app writes into the App Group. No network, no Firebase.
// Add this file, the font files, and the .lproj folders to the MotiWidgets extension
// target only. Do not add them to the Runner target.

private let appGroup = "group.com.example.motiScroll"
private let payloadKey = "widget_payload"

struct MotiQuote: Codable, Hashable {
    let itemId: String
    let text: String
    let wordCount: Int
    let authorName: String
    let authorRole: String
    let sourceTitle: String
    let sourceYear: Int?
    let isTranslated: Bool
    let field: String
    let colors: [String]
    let takeaway: String?
}

struct MotiDay: Codable {
    let date: String
    let inline: MotiQuote?
    let small: MotiQuote?
    let medium: MotiQuote?
    let large: MotiQuote?

    func quote(for family: WidgetFamily) -> MotiQuote? {
        switch family {
        case .accessoryInline: return inline
        case .systemSmall, .accessoryRectangular: return small
        case .systemMedium: return medium
        case .systemLarge: return large
        default: return small
        }
    }
}

struct MotiPayload: Codable {
    let generatedAt: String?
    let contentLanguage: String
    let direction: String
    let streakCount: Int
    let localizedStrings: [String: String]
    let daily: [MotiDay]
    let moodPools: [String: [MotiQuote]]
    let fieldPools: [String: [MotiQuote]]
    let saved: [MotiQuote]
    let widgetsEnabled: Bool
    let showSavedOnLockScreen: Bool
    let cleared: Bool

    var needsRefresh: Bool {
        if cleared { return true }
        guard let generatedAt else { return true }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let parsed = formatter.date(from: generatedAt) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: generatedAt)
        }()
        guard let parsed else { return true }
        return Date().timeIntervalSince(parsed) > 14 * 24 * 60 * 60
    }

    func text(_ key: String, fallback: String) -> String {
        localizedStrings[key] ?? fallback
    }

    func quote(for family: WidgetFamily, on date: Date) -> MotiQuote? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)
        let day = daily.first { $0.date == key } ?? daily.first
        return day?.quote(for: family)
    }
}

private func portraitFileName(_ id: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
    let safe = String(id.unicodeScalars.map { scalar in
        allowed.contains(scalar) ? Character(scalar) : "_"
    })
    return (safe.isEmpty ? "line" : safe) + ".jpg"
}

private func portraitImage(_ id: String) -> UIImage? {
    guard let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroup
    ) else { return nil }
    let file = container
        .appendingPathComponent("portraits", isDirectory: true)
        .appendingPathComponent(portraitFileName(id))
    guard let data = try? Data(contentsOf: file),
          let image = UIImage(data: data)
    else { return nil }
    return image
}

private func bundledMark() -> UIImage? {
    guard let url = Bundle.main.url(forResource: "mark", withExtension: "png"),
          let data = try? Data(contentsOf: url)
    else { return nil }
    return UIImage(data: data)
}

enum WidgetStore {
    static func load() -> MotiPayload? {
        guard let defaults = UserDefaults(suiteName: appGroup),
              let raw = defaults.string(forKey: payloadKey),
              let data = raw.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(MotiPayload.self, from: data)
    }
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: MotiQuote?
    let message: String?
    let direction: LayoutDirection
    let language: String
    let showSource: Bool
    let showField: Bool
    let strings: [String: String]

    static let placeholder = QuoteEntry(
        date: .now,
        quote: nil,
        message: "Your daily quote appears here",
        direction: .leftToRight,
        language: "en",
        showSource: false,
        showField: false,
        strings: [:]
    )

    static let sample = QuoteEntry(
        date: .now,
        quote: MotiQuote(
            itemId: "sample",
            text: "Your daily quote appears here",
            wordCount: 5,
            authorName: "Sample",
            authorRole: "",
            sourceTitle: "Notes",
            sourceYear: nil,
            isTranslated: false,
            field: "other",
            colors: ["#17191E", "#3A4150"],
            takeaway: nil
        ),
        message: nil,
        direction: .leftToRight,
        language: "en",
        showSource: true,
        showField: false,
        strings: ["translated": "Translated"]
    )

    static let rtl = QuoteEntry(
        date: .now,
        quote: MotiQuote(
            itemId: "sample-rtl",
            text: "يظهر الاقتباس اليومي هنا",
            wordCount: 4,
            authorName: "Sample",
            authorRole: "",
            sourceTitle: "Notes",
            sourceYear: nil,
            isTranslated: false,
            field: "other",
            colors: ["#17191E", "#3A4150"],
            takeaway: nil
        ),
        message: nil,
        direction: .rightToLeft,
        language: "ar",
        showSource: true,
        showField: false,
        strings: [:]
    )

    static let empty = QuoteEntry(
        date: .now,
        quote: nil,
        message: "Open MotiScroll to refresh",
        direction: .leftToRight,
        language: "en",
        showSource: false,
        showField: false,
        strings: [:]
    )
}

struct QuoteView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var renderingMode
    let entry: QuoteEntry
    let family: WidgetFamily

    private var accessory: Bool {
        switch family {
        case .accessoryInline, .accessoryCircular, .accessoryRectangular:
            return true
        default:
            return false
        }
    }

    private var showsPortrait: Bool {
        switch family {
        case .systemSmall, .systemMedium, .systemLarge:
            return true
        default:
            return false
        }
    }

    private var portraitSide: CGFloat {
        switch family {
        case .systemLarge: return 52
        case .systemMedium: return 44
        default: return 36
        }
    }

    private var authorSize: CGFloat {
        switch family {
        case .systemSmall: return 15
        case .accessoryRectangular: return 13
        default: return 18
        }
    }

    private func portrait(_ quote: MotiQuote) -> some View {
        let side = portraitSide
        return Group {
            if let image = portraitImage(quote.itemId) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: side, height: side)
                    .clipShape(RoundedRectangle(cornerRadius: side * 0.22, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
                        .fill(Color(red: 0.043, green: 0.043, blue: 0.051))
                    if let mark = bundledMark() {
                        Image(uiImage: mark)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(Color(red: 0.957, green: 0.945, blue: 0.918))
                            .scaledToFit()
                            .frame(width: side * 0.62, height: side * 0.62)
                    }
                }
                .frame(width: side, height: side)
            }
        }
        .accessibilityHidden(true)
    }

    var body: some View {
        content
            .environment(\.layoutDirection, entry.direction)
            .containerBackground(for: .widget) {
                if accessory {
                    AccessoryWidgetBackground()
                } else {
                    background
                }
            }
    }

    @ViewBuilder private var content: some View {
        if family == .accessoryInline {
            Text(inlineLine)
                .font(labelFont(13))
                .widgetAccentable()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        } else if let quote = entry.quote {
            VStack(alignment: .leading, spacing: 10) {
                if entry.showField {
                    Text(fieldName(quote.field))
                        .font(labelFont(11))
                        .foregroundStyle(Color(red: 0.88, green: 0.48, blue: 0.29))
                        .widgetAccentable()
                        .accessibilityHidden(true)
                }
                if showsPortrait {
                    HStack(alignment: .center, spacing: 8) {
                        portrait(quote)
                        Text(quote.authorName)
                            .font(labelFont(authorSize))
                            .foregroundStyle(textColor)
                            .widgetAccentable()
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                }
                Text(quote.text)
                    .font(quoteFont(quoteSize))
                    .lineSpacing(entry.language == "ar" || entry.language == "fa" || entry.language == "hi" ? 4 : 0)
                    .foregroundStyle(textColor)
                    .widgetAccentable()
                    .lineLimit(lineLimit)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                if !showsPortrait {
                    Text(quote.authorName)
                        .font(labelFont(authorSize))
                        .foregroundStyle(textColor)
                        .widgetAccentable()
                }
                if entry.showSource, !quote.sourceTitle.isEmpty {
                    Text(sourceLine(quote))
                        .font(labelFont(12))
                        .foregroundStyle(mutedColor)
                        .accessibilityHidden(true)
                }
                if entry.showField, let takeaway = quote.takeaway, !takeaway.isEmpty {
                    Text(takeaway)
                        .font(labelFont(12))
                        .foregroundStyle(mutedColor)
                }
                if entry.showSource, quote.isTranslated {
                    Text(entry.strings["translated"] ?? "Translated")
                        .font(labelFont(11))
                        .foregroundStyle(Color(red: 0.88, green: 0.48, blue: 0.29))
                        .widgetAccentable()
                }
                Spacer(minLength: 0)
            }
            .padding(accessory ? 0 : 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("quote, by \(quote.authorName)")
        } else {
            Text(entry.message ?? "Open MotiScroll to refresh")
                .font(quoteFont(18))
                .foregroundStyle(textColor)
                .widgetAccentable()
                .lineLimit(4)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private var inlineLine: String {
        if let quote = entry.quote {
            return "\(quote.text) — \(quote.authorName)"
        }
        return entry.message ?? "Open MotiScroll to refresh"
    }

    private var quoteSize: CGFloat {
        switch family {
        case .systemLarge: return 22
        case .systemMedium: return 18
        case .accessoryRectangular: return 15
        default: return 16
        }
    }

    private var lineLimit: Int {
        switch family {
        case .systemLarge: return 8
        case .systemMedium: return 5
        case .accessoryRectangular: return 3
        default: return 4
        }
    }

    private var textColor: Color {
        if accessory { return .primary }
        return colorScheme == .dark ? Color(red: 0.96, green: 0.95, blue: 0.92) : Color(red: 0.10, green: 0.10, blue: 0.10)
    }

    private var mutedColor: Color {
        colorScheme == .dark ? Color(red: 0.78, green: 0.76, blue: 0.72) : Color(red: 0.36, green: 0.34, blue: 0.31)
    }

    private var background: some View {
        let dark = colorScheme == .dark && renderingMode == .fullColor
        return ZStack {
            if dark, let quote = entry.quote, quote.colors.count >= 2 {
                LinearGradient(
                    colors: [color(quote.colors[0]), color(quote.colors[1])],
                    startPoint: .top,
                    endPoint: .bottom
                )
                LinearGradient(
                    colors: [Color.black.opacity(0.90), Color.black.opacity(0.70)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else if colorScheme == .dark {
                Color(red: 0.04, green: 0.04, blue: 0.05)
            } else {
                Color(red: 0.97, green: 0.96, blue: 0.94)
            }
        }
    }

    private func quoteFont(_ size: CGFloat) -> Font {
        switch entry.language {
        case "ar", "fa", "hi", "zh", "ja", "ko":
            return .system(size: size, design: .serif)
        default:
            return .custom("PlayfairDisplay-SemiBold", size: size)
        }
    }

    private func labelFont(_ size: CGFloat) -> Font {
        switch entry.language {
        case "ar", "fa", "hi", "zh", "ja", "ko":
            return .system(size: size)
        default:
            return .custom("DMSans-Medium", size: size)
        }
    }

    private func color(_ hex: String) -> Color {
        var value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if value.count == 6 { value = "FF" + value }
        var int: UInt64 = 0
        Scanner(string: value).scanHexInt64(&int)
        return Color(
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8) & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255
        )
    }

    private func sourceLine(_ quote: MotiQuote) -> String {
        if let year = quote.sourceYear { return "\(quote.sourceTitle), \(year)" }
        return quote.sourceTitle
    }

    private func fieldName(_ field: String) -> String {
        entry.strings["field_\(field)"] ?? field
    }
}

struct StreakView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family
    let count: Int
    let label: String
    let message: String?

    var body: some View {
        VStack(spacing: 4) {
            Text(message == nil ? "\(count)" : "—")
                .font(.custom("PlayfairDisplay-SemiBold", size: family == .accessoryCircular ? 22 : 36))
                .foregroundStyle(Color(red: 0.88, green: 0.48, blue: 0.29))
                .widgetAccentable()
            if family != .accessoryCircular {
                Text(message ?? label)
                    .font(.custom("DMSans-Medium", size: 13))
                    .foregroundStyle(colorScheme == .dark ? Color(red: 0.96, green: 0.95, blue: 0.92) : Color(red: 0.10, green: 0.10, blue: 0.10))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
        .containerBackground(for: .widget) {
            if family == .accessoryCircular {
                AccessoryWidgetBackground()
            } else if colorScheme == .dark {
                Color(red: 0.04, green: 0.04, blue: 0.05)
            } else {
                Color(red: 0.97, green: 0.96, blue: 0.94)
            }
        }
        .accessibilityLabel(message ?? "\(count) \(label)")
    }
}

enum MotiTimeline {
    static func day(_ key: String) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else { return nil }
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func quoteEntry(at date: Date, family: WidgetFamily, payload: MotiPayload?, quote: MotiQuote?) -> QuoteEntry {
        let refresh = payload?.needsRefresh ?? true
        let disabled = payload?.widgetsEnabled == false
        let showSource = family == .systemMedium || family == .systemLarge
        let showField = family == .systemLarge
        if payload == nil || refresh {
            return QuoteEntry(
                date: date,
                quote: nil,
                message: payload?.text("openToRefresh", fallback: "Open MotiScroll to refresh") ?? "Open MotiScroll to refresh",
                direction: payload?.direction == "rtl" ? .rightToLeft : .leftToRight,
                language: payload?.contentLanguage ?? "en",
                showSource: false,
                showField: false,
                strings: payload?.localizedStrings ?? [:]
            )
        }
        if disabled || quote == nil {
            return QuoteEntry(
                date: date,
                quote: nil,
                message: disabled
                    ? payload?.text("yourDailyQuote", fallback: "Your daily quote appears here")
                    : payload?.text("openToRefresh", fallback: "Open MotiScroll to refresh"),
                direction: payload?.direction == "rtl" ? .rightToLeft : .leftToRight,
                language: payload?.contentLanguage ?? "en",
                showSource: false,
                showField: false,
                strings: payload?.localizedStrings ?? [:]
            )
        }
        return QuoteEntry(
            date: date,
            quote: quote,
            message: nil,
            direction: payload?.direction == "rtl" ? .rightToLeft : .leftToRight,
            language: payload?.contentLanguage ?? "en",
            showSource: showSource,
            showField: showField,
            strings: payload?.localizedStrings ?? [:]
        )
    }
}

struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        let payload = WidgetStore.load()
        completion(
            MotiTimeline.quoteEntry(
                at: .now,
                family: context.family,
                payload: payload,
                quote: payload?.quote(for: context.family, on: .now)
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let payload = WidgetStore.load()
        guard let payload, !payload.needsRefresh, payload.widgetsEnabled else {
            let entry = MotiTimeline.quoteEntry(at: .now, family: context.family, payload: payload, quote: nil)
            completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(6 * 60 * 60))))
            return
        }
        let entries = payload.daily.compactMap { day -> QuoteEntry? in
            guard let date = MotiTimeline.day(day.date) else { return nil }
            return MotiTimeline.quoteEntry(
                at: date,
                family: context.family,
                payload: payload,
                quote: day.quote(for: context.family)
            )
        }
        completion(Timeline(entries: entries.isEmpty ? [.empty] : entries, policy: .atEnd))
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let count: Int
    let label: String
    let message: String?
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, count: 0, label: "day streak", message: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let next = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(24 * 60 * 60)
        completion(Timeline(entries: [entry()], policy: .after(next)))
    }

    private func entry() -> StreakEntry {
        let payload = WidgetStore.load()
        if payload == nil || payload?.needsRefresh == true || payload?.widgetsEnabled == false {
            return StreakEntry(
                date: .now,
                count: 0,
                label: "",
                message: payload?.text("openToRefresh", fallback: "Open MotiScroll to refresh") ?? "Open MotiScroll to refresh"
            )
        }
        return StreakEntry(
            date: .now,
            count: payload?.streakCount ?? 0,
            label: payload?.text("streakLabel", fallback: "day streak") ?? "day streak",
            message: nil
        )
    }
}

enum PoolChoice: String, AppEnum {
    case sports, business, science, arts, leadership, resilience
    case startingOver, badDay, needFocus, preWorkout, examStress, feelingStuck

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Pool")

    static var caseDisplayRepresentations: [PoolChoice: DisplayRepresentation] = [
        .sports: DisplayRepresentation(title: LocalizedStringResource("field_sports")),
        .business: DisplayRepresentation(title: LocalizedStringResource("field_business")),
        .science: DisplayRepresentation(title: LocalizedStringResource("field_science")),
        .arts: DisplayRepresentation(title: LocalizedStringResource("field_arts")),
        .leadership: DisplayRepresentation(title: LocalizedStringResource("field_leadership")),
        .resilience: DisplayRepresentation(title: LocalizedStringResource("field_resilience")),
        .startingOver: DisplayRepresentation(title: LocalizedStringResource("mood_startingOver")),
        .badDay: DisplayRepresentation(title: LocalizedStringResource("mood_badDay")),
        .needFocus: DisplayRepresentation(title: LocalizedStringResource("mood_needFocus")),
        .preWorkout: DisplayRepresentation(title: LocalizedStringResource("mood_preWorkout")),
        .examStress: DisplayRepresentation(title: LocalizedStringResource("mood_examStress")),
        .feelingStuck: DisplayRepresentation(title: LocalizedStringResource("mood_feelingStuck")),
    ]

    var poolKey: (String, String) {
        switch self {
        case .sports, .business, .science, .arts, .leadership, .resilience:
            return ("field", rawValue)
        default:
            return ("mood", rawValue)
        }
    }
}

struct PoolIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "pool_widget_name"

    @Parameter(title: "Pool")
    var pool: PoolChoice?
}

struct PoolProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry { .placeholder }

    func snapshot(for configuration: PoolIntent, in context: Context) async -> QuoteEntry {
        .placeholder
    }

    func timeline(for configuration: PoolIntent, in context: Context) async -> Timeline<QuoteEntry> {
        let payload = WidgetStore.load()
        guard let key = configuration.pool?.poolKey else {
            let entry = MotiTimeline.quoteEntry(at: .now, family: .systemMedium, payload: payload, quote: nil)
            return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(5 * 60 * 60)))
        }
        let pool = key.0 == "mood" ? payload?.moodPools[key.1] : payload?.fieldPools[key.1]
        let items = pool ?? []
        guard let payload, !payload.needsRefresh, payload.widgetsEnabled, !items.isEmpty else {
            let entry = MotiTimeline.quoteEntry(at: .now, family: .systemMedium, payload: payload, quote: nil)
            return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(5 * 60 * 60)))
        }
        let entries = items.enumerated().map { index, quote in
            MotiTimeline.quoteEntry(
                at: Date().addingTimeInterval(Double(index) * 5 * 60 * 60),
                family: .systemMedium,
                payload: payload,
                quote: quote
            )
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SavedProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let payload = WidgetStore.load()
        let saved = payload?.saved ?? []
        guard let payload, !payload.needsRefresh, payload.widgetsEnabled, !saved.isEmpty else {
            var entry = MotiTimeline.quoteEntry(at: .now, family: .systemMedium, payload: payload, quote: nil)
            if payload?.needsRefresh != true && payload?.widgetsEnabled != false {
                entry = QuoteEntry(
                    date: .now,
                    quote: nil,
                    message: payload?.text("saveAQuote", fallback: "Save a quote to see it here") ?? "Save a quote to see it here",
                    direction: payload?.direction == "rtl" ? .rightToLeft : .leftToRight,
                    language: payload?.contentLanguage ?? "en",
                    showSource: false,
                    showField: false,
                    strings: payload?.localizedStrings ?? [:]
                )
            }
            completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(5 * 60 * 60))))
            return
        }
        let entries = saved.enumerated().map { index, quote in
            MotiTimeline.quoteEntry(
                at: Date().addingTimeInterval(Double(index) * 5 * 60 * 60),
                family: .systemMedium,
                payload: payload,
                quote: quote
            )
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct MotiQuoteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MotiQuoteWidget", provider: QuoteProvider()) { entry in
            FamilyQuoteView(entry: entry)
        }
        .configurationDisplayName(Text("quoteOfTheDay"))
        .description(Text("quote_widget_description"))
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryRectangular, .accessoryInline,
        ])
    }
}

struct MotiStreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MotiStreakWidget", provider: StreakProvider()) { entry in
            StreakView(count: entry.count, label: entry.label, message: entry.message)
        }
        .configurationDisplayName(Text("streak_widget_name"))
        .description(Text("streak_widget_description"))
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct MotiSavedWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MotiSavedWidget", provider: SavedProvider()) { entry in
            FamilyQuoteView(entry: entry)
        }
        .configurationDisplayName(Text("saved_widget_name"))
        .description(Text("saved_widget_description"))
        .supportedFamilies([.systemMedium])
    }
}

struct MotiPoolWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "MotiPoolWidget", intent: PoolIntent.self, provider: PoolProvider()) { entry in
            FamilyQuoteView(entry: entry)
        }
        .configurationDisplayName(Text("pool_widget_name"))
        .description(Text("pool_widget_description"))
        .supportedFamilies([.systemMedium])
    }
}

@main
struct MotiWidgetBundle: WidgetBundle {
    var body: some Widget {
        MotiQuoteWidget()
        MotiStreakWidget()
        MotiSavedWidget()
        MotiPoolWidget()
    }
}

// The quote widget's view does not receive the real family from StaticConfiguration's
// entry builder on its own. A wrapper reads the environment family.

struct FamilyQuoteView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuoteEntry

    var body: some View {
        QuoteView(entry: entry, family: family)
    }
}

#Preview("Small", as: .systemSmall) {
    MotiQuoteWidget()
} timeline: {
    QuoteEntry.sample
}

#Preview("Medium dark", as: .systemMedium) {
    MotiQuoteWidget()
} timeline: {
    QuoteEntry.sample
}

#Preview("Large", as: .systemLarge) {
    MotiQuoteWidget()
} timeline: {
    QuoteEntry.sample
}

#Preview("Lock rectangular", as: .accessoryRectangular) {
    MotiQuoteWidget()
} timeline: {
    QuoteEntry.sample
}

#Preview("Lock inline", as: .accessoryInline) {
    MotiQuoteWidget()
} timeline: {
    QuoteEntry.sample
}

#Preview("RTL", as: .systemMedium) {
    MotiQuoteWidget()
} timeline: {
    QuoteEntry.rtl
}

#Preview("Empty payload", as: .systemSmall) {
    MotiQuoteWidget()
} timeline: {
    QuoteEntry.empty
}

#Preview("Streak", as: .systemSmall) {
    MotiStreakWidget()
} timeline: {
    StreakEntry(date: .now, count: 3, label: "day streak", message: nil)
}

#Preview("Streak lock", as: .accessoryCircular) {
    MotiStreakWidget()
} timeline: {
    StreakEntry(date: .now, count: 3, label: "day streak", message: nil)
}

#Preview("Saved empty", as: .systemMedium) {
    MotiSavedWidget()
} timeline: {
    QuoteEntry(
        date: .now,
        quote: nil,
        message: "Save a quote to see it here",
        direction: .leftToRight,
        language: "en",
        showSource: false,
        showField: false,
        strings: [:]
    )
}
