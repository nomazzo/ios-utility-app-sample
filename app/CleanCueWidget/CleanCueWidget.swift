import SwiftUI
import WidgetKit

private enum WidgetSnapshotDefaults {
    static let appGroupIdentifier = "group.com.example.homeroutinedemo"
    static let snapshotKey = "CleanCueWidgetSnapshot"
}

private enum WidgetText {
    static var description: String {
        localized(
            ja: "今日やる掃除を確認できます。",
            en: "Check today's cleaning tasks.",
            de: "Sieh deine Putzaufgaben für heute.",
            fr: "Consultez les tâches de ménage du jour.",
            nl: "Bekijk de schoonmaaktaken voor vandaag.",
            sv: "Se dagens städuppgifter.",
            da: "Se dagens rengøringsopgaver.",
            nb: "Se dagens rengjøringsoppgaver.",
            es: "Consulta las tareas de limpieza de hoy.",
            pt: "Vê as tarefas de limpeza de hoje.",
            it: "Vedi le attività di pulizia di oggi.",
            ko: "오늘 할 청소 작업을 확인하세요.",
            zhHant: "查看今天的清潔任務。",
            fi: "Tarkista tämän päivän siivoustehtävät."
        )
    }

    static var noCleaningToday: String {
        localized(
            ja: "今日は掃除なし",
            en: "No cleaning today",
            de: "Heute nichts mehr zu tun",
            fr: "Pas de ménage aujourd’hui",
            nl: "Vandaag niets meer te doen",
            sv: "Ingen städning idag",
            da: "Ingen rengøring i dag",
            nb: "Ingen flere oppgaver i dag",
            es: "No quedan tareas hoy",
            pt: "Nada mais para limpar hoje",
            it: "Nessuna pulizia oggi",
            ko: "오늘은 청소 없음",
            zhHant: "今天沒有清潔",
            fi: "Ei siivousta tänään"
        )
    }

    static var doneToday: String {
        localized(
            ja: "今日は完了です",
            en: "Today is done",
            de: "Alles für heute erledigt",
            fr: "Tout est terminé pour aujourd’hui",
            nl: "Alles klaar voor vandaag",
            sv: "Allt klart för idag",
            da: "Færdig for i dag",
            nb: "Ferdig for i dag",
            es: "Todo listo por hoy",
            pt: "Tudo pronto por hoje",
            it: "Tutto fatto per oggi",
            ko: "오늘은 완료",
            zhHant: "今天完成了",
            fi: "Tänään on valmis"
        )
    }

    static var nextTasksWillAppear: String {
        localized(
            ja: "次の予定が来たら表示します",
            en: "Upcoming tasks will appear here",
            de: "Kommende Aufgaben erscheinen hier",
            fr: "Les prochaines tâches apparaîtront ici",
            nl: "Komende taken verschijnen hier",
            sv: "Kommande uppgifter visas här",
            da: "Kommende opgaver vises her",
            nb: "Kommende oppgaver vises her",
            es: "Las próximas tareas aparecerán aquí",
            pt: "As próximas tarefas aparecem aqui",
            it: "Le prossime attività appariranno qui",
            ko: "다음 작업이 여기에 표시됩니다",
            zhHant: "下一個任務會顯示在這裡",
            fi: "Tulevat tehtävät näkyvät täällä"
        )
    }

    static var nextTasksWillAppearLong: String {
        localized(
            ja: "次の予定が来たらここに表示します。",
            en: "Upcoming tasks will appear here.",
            de: "Kommende Aufgaben erscheinen hier.",
            fr: "Les prochaines tâches apparaîtront ici.",
            nl: "Komende taken verschijnen hier.",
            sv: "Kommande uppgifter visas här.",
            da: "Kommende opgaver vises her.",
            nb: "Kommende oppgaver vises her.",
            es: "Las próximas tareas aparecerán aquí.",
            pt: "As próximas tarefas aparecem aqui.",
            it: "Le prossime attività appariranno qui.",
            ko: "다음 작업이 여기에 표시됩니다.",
            zhHant: "下一個任務會顯示在這裡。",
            fi: "Tulevat tehtävät näkyvät täällä."
        )
    }

    static var today: String {
        localized(ja: "今日", en: "Today", de: "Heute", fr: "Aujourd’hui", nl: "Vandaag", sv: "Idag", da: "I dag", nb: "I dag", es: "Hoy", pt: "Hoje", it: "Oggi", ko: "오늘", zhHant: "今天", fi: "Tänään")
    }

    static var inThreeDays: String {
        localized(ja: "3日後", en: "In 3 days", de: "In 3 Tagen", fr: "Dans 3 jours", nl: "Over 3 dagen", sv: "Om 3 dagar", da: "Om 3 dage", nb: "Om 3 dager", es: "En 3 días", pt: "Daqui a 3 dias", it: "Tra 3 giorni", ko: "3일 후", zhHant: "3 天後", fi: "3 päivän päästä")
    }

    static var kitchen: String {
        localized(ja: "キッチン", en: "Kitchen", de: "Küche", fr: "Cuisine", nl: "Keuken", sv: "Kök", da: "Køkken", nb: "Kjøkken", es: "Cocina", pt: "Cozinha", it: "Cucina", ko: "주방", zhHant: "廚房", fi: "Keittiö")
    }

    static var bathroom: String {
        localized(ja: "浴室", en: "Bathroom", de: "Bad", fr: "Salle de bain", nl: "Badkamer", sv: "Badrum", da: "Badeværelse", nb: "Bad", es: "Baño", pt: "Casa de banho", it: "Bagno", ko: "욕실", zhHant: "浴室", fi: "Kylpyhuone")
    }

    static var wipeStove: String {
        localized(ja: "コンロ拭き", en: "Wipe stove", de: "Herd abwischen", fr: "Essuyer la plaque", nl: "Kookplaat schoonmaken", sv: "Rengör spishällen", da: "Rengør kogepladen", nb: "Rengjør koketoppen", es: "Limpiar la placa", pt: "Limpar a placa", it: "Pulire il piano", ko: "가스레인지 닦기", zhHant: "擦拭爐台", fi: "Pyyhi liesi")
    }

    static var cleanDrain: String {
        localized(ja: "排水口掃除", en: "Clean drain", de: "Abfluss reinigen", fr: "Nettoyer la bonde", nl: "Afvoer schoonmaken", sv: "Rengör avloppet", da: "Rengør afløbet", nb: "Rengjør avløpet", es: "Limpiar el desagüe", pt: "Limpar o ralo", it: "Pulire lo scarico", ko: "배수구 청소", zhHant: "清潔排水口", fi: "Puhdista viemäri")
    }

    static var cleanSink: String {
        localized(ja: "シンク掃除", en: "Clean sink", de: "Spüle reinigen", fr: "Nettoyer l’évier", nl: "Gootsteen schoonmaken", sv: "Rengör diskhon", da: "Rengør vasken", nb: "Rengjør vasken", es: "Limpiar el fregadero", pt: "Limpar o lava-loiça", it: "Pulire il lavello", ko: "싱크대 청소", zhHant: "清潔水槽", fi: "Puhdista allas")
    }

    static func minutes(_ minutes: Int, localeIdentifier: String? = nil) -> String {
        localized(
            ja: "\(minutes)分",
            en: "\(minutes) min",
            de: "\(minutes) Min.",
            fr: "\(minutes) min",
            nl: "\(minutes) min",
            sv: "\(minutes) min",
            da: "\(minutes) min",
            nb: "\(minutes) min",
            es: "\(minutes) min",
            pt: "\(minutes) min",
            it: "\(minutes) min",
            ko: "\(minutes)분",
            zhHant: "\(minutes) 分鐘",
            fi: "\(minutes) min",
            localeIdentifier: localeIdentifier
        )
    }

    static func remainingTasks(_ count: Int, localeIdentifier: String? = nil) -> String {
        let dutch = count == 1 ? "Nog 1 taak" : "Nog \(count) taken"
        let danish = "\(count) tilbage"
        let norwegian = count == 1 ? "1 oppgave igjen" : "\(count) oppgaver igjen"
        let spanish = count == 1 ? "1 tarea pendiente" : "\(count) tareas pendientes"
        let portuguese = count == 1 ? "1 tarefa pendente" : "\(count) tarefas pendentes"
        let italian = count == 1 ? "1 da fare" : "\(count) da fare"
        let korean = "\(count)개 남음"
        let traditionalChinese = "還有 \(count) 個"
        let finnish = "\(count) jäljellä"
        return localized(
            ja: "あと\(count)件",
            en: "\(count) left",
            de: "Noch \(count) offen",
            fr: "\(count) restantes",
            nl: dutch,
            sv: "\(count) kvar",
            da: danish,
            nb: norwegian,
            es: spanish,
            pt: portuguese,
            it: italian,
            ko: korean,
            zhHant: traditionalChinese,
            fi: finnish,
            localeIdentifier: localeIdentifier
        )
    }

    static func moreTasks(_ count: Int, localeIdentifier: String? = nil) -> String {
        let french = count == 1 ? "+1 autre" : "+\(count) autres"
        let spanish = "+\(count) más"
        let portuguese = "+\(count) mais"
        let italian = "+\(count) altre"
        let korean = "+\(count)개 더"
        let traditionalChinese = "+\(count) 個"
        let finnish = "+\(count) lisää"
        return localized(
            ja: "ほか\(count)件",
            en: "\(count) more",
            de: "+\(count) weitere",
            fr: french,
            nl: "+\(count) meer",
            sv: "+\(count) till",
            da: "+\(count) mere",
            nb: "+\(count) til",
            es: spanish,
            pt: portuguese,
            it: italian,
            ko: korean,
            zhHant: traditionalChinese,
            fi: finnish,
            localeIdentifier: localeIdentifier
        )
    }

    static func taskMeta(_ task: WidgetTaskSnapshot, localeIdentifier: String? = nil) -> String {
        let separator = localized(ja: "・", en: " · ", de: " · ", fr: " · ", nl: " · ", sv: " · ", da: " · ", nb: " · ", es: " · ", pt: " · ", it: " · ", ko: " · ", zhHant: " · ", fi: " · ", localeIdentifier: localeIdentifier)
        return [task.placeName, task.dueLabel, minutes(task.estimatedMinutes, localeIdentifier: localeIdentifier)]
            .joined(separator: separator)
    }

    private static func localized(
        ja: String,
        en: String,
        de: String,
        fr: String,
        nl: String,
        sv: String,
        da: String,
        nb: String,
        es: String,
        pt: String,
        it: String,
        ko: String,
        zhHant: String,
        fi: String,
        localeIdentifier: String? = nil
    ) -> String {
        let languageCode = languageCode(for: localeIdentifier)
            ?? languageCode(for: Bundle.main.preferredLocalizations.first)
            ?? Locale.current.language.languageCode?.identifier
        switch languageCode {
        case "ja":
            return ja
        case "de":
            return de
        case "fr":
            return fr
        case "nl":
            return nl
        case "sv":
            return sv
        case "da":
            return da
        case "nb", "no":
            return nb
        case "es":
            return es
        case "pt":
            return pt
        case "it":
            return it
        case "ko":
            return ko
        case "zh":
            return zhHant
        case "fi":
            return fi
        default:
            return en
        }
    }

    static func languageCode(for localeIdentifier: String?) -> String? {
        localeIdentifier.flatMap { Locale(identifier: $0).language.languageCode?.identifier }
    }
}

private struct WidgetTaskSnapshot: Codable, Equatable, Identifiable {
    var id: UUID
    var taskName: String
    var placeName: String
    var dueLabel: String
    var estimatedMinutes: Int
    var urgency: Double
}

private struct WidgetSnapshot: Codable, Equatable {
    var generatedAt: Date
    var localeIdentifier: String?
    var todayTasks: [WidgetTaskSnapshot]

    static let empty = WidgetSnapshot(
        generatedAt: Date(timeIntervalSince1970: 0),
        localeIdentifier: nil,
        todayTasks: []
    )
}

private struct CleanCueWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

private struct CleanCueWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CleanCueWidgetEntry {
        CleanCueWidgetEntry(date: Date(), snapshot: placeholderSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (CleanCueWidgetEntry) -> Void) {
        completion(CleanCueWidgetEntry(date: Date(), snapshot: loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CleanCueWidgetEntry>) -> Void) {
        let entry = CleanCueWidgetEntry(date: Date(), snapshot: loadSnapshot())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private var placeholderSnapshot: WidgetSnapshot {
        WidgetSnapshot(
            generatedAt: Date(),
            localeIdentifier: Locale.current.identifier,
            todayTasks: [
                WidgetTaskSnapshot(
                    id: UUID(),
                    taskName: WidgetText.wipeStove,
                    placeName: WidgetText.kitchen,
                    dueLabel: WidgetText.today,
                    estimatedMinutes: 7,
                    urgency: 0.8
                ),
                WidgetTaskSnapshot(
                    id: UUID(),
                    taskName: WidgetText.cleanDrain,
                    placeName: WidgetText.bathroom,
                    dueLabel: WidgetText.today,
                    estimatedMinutes: 8,
                    urgency: 0.8
                ),
                WidgetTaskSnapshot(
                    id: UUID(),
                    taskName: WidgetText.cleanSink,
                    placeName: WidgetText.kitchen,
                    dueLabel: WidgetText.inThreeDays,
                    estimatedMinutes: 5,
                    urgency: 0.4
                )
            ]
        )
    }

    private func loadSnapshot() -> WidgetSnapshot {
        let defaults = UserDefaults(suiteName: WidgetSnapshotDefaults.appGroupIdentifier) ?? .standard
        guard let data = defaults.data(forKey: WidgetSnapshotDefaults.snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }
}

struct CleanCueWidget: Widget {
    let kind = "CleanCueWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CleanCueWidgetProvider()) { entry in
            CleanCueWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    CleanCueWidgetBackground()
                }
        }
        .configurationDisplayName("HomeRoutine Demo")
        .description(WidgetText.description)
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

private struct CleanCueWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.locale) private var locale
    let entry: CleanCueWidgetEntry

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let task = entry.snapshot.todayTasks.first {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color(for: task.urgency))
                        .frame(width: 8, height: 8)

                    Text("HomeRoutine Demo")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()
                }

                Text(task.taskName)
                    .font(.title3.weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(task.placeName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 8) {
                    Text(task.dueLabel)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Image(systemName: "clock")
                    Text(WidgetText.minutes(task.estimatedMinutes, localeIdentifier: localeIdentifier))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color(red: 0.13, green: 0.79, blue: 0.61))
                Text(WidgetText.doneToday)
                    .font(.headline.weight(.bold))
                    .lineLimit(2)
                Text(WidgetText.nextTasksWillAppear)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(summaryTitle)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()

                if !entry.snapshot.todayTasks.isEmpty {
                    Text(WidgetText.minutes(totalMinutes, localeIdentifier: localeIdentifier))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 0.07, green: 0.52, blue: 1.0))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.91, green: 0.96, blue: 1.0), in: Capsule())
                }
            }

            if entry.snapshot.todayTasks.isEmpty {
                Spacer()
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color(red: 0.13, green: 0.79, blue: 0.61))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(WidgetText.doneToday)
                            .font(.headline.weight(.bold))
                        Text(WidgetText.nextTasksWillAppearLong)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
            } else {
                ForEach(visibleMediumTasks) { task in
                    mediumTaskRow(task)
                }

                if remainingMediumTaskCount > 0 {
                    HStack(spacing: 7) {
                        Image(systemName: "ellipsis")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color(red: 0.07, green: 0.52, blue: 1.0))
                            .frame(width: 7)

                        Text(WidgetText.moreTasks(remainingMediumTaskCount, localeIdentifier: localeIdentifier))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(.top, 1)
                }
            }
        }
        .padding(.top, 22)
        .padding(.bottom, 18)
        .padding(.leading, 22)
        .padding(.trailing, 28)
    }

    private func mediumTaskRow(_ task: WidgetTaskSnapshot) -> some View {
        HStack(spacing: 9) {
            Circle()
                .fill(color(for: task.urgency))
                .frame(width: 7, height: 7)

            VStack(alignment: .leading, spacing: 1) {
                Text(task.taskName)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
                Text(WidgetText.taskMeta(task, localeIdentifier: localeIdentifier))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 1)
    }

    private var totalMinutes: Int {
        entry.snapshot.todayTasks.reduce(0) { $0 + $1.estimatedMinutes }
    }

    private var visibleMediumTasks: [WidgetTaskSnapshot] {
        Array(entry.snapshot.todayTasks.prefix(2))
    }

    private var remainingMediumTaskCount: Int {
        max(entry.snapshot.todayTasks.count - visibleMediumTasks.count, 0)
    }

    private var summaryTitle: String {
        let count = entry.snapshot.todayTasks.count
        if count == 0 {
            return WidgetText.noCleaningToday
        }
        return WidgetText.remainingTasks(count, localeIdentifier: localeIdentifier)
    }

    private var localeIdentifier: String? {
        let snapshotLanguageCode = WidgetText.languageCode(for: entry.snapshot.localeIdentifier)
        let widgetLanguageCode = WidgetText.languageCode(for: locale.identifier)

        if snapshotLanguageCode == nil || snapshotLanguageCode == "en" {
            return widgetLanguageCode == nil ? entry.snapshot.localeIdentifier : locale.identifier
        }

        return entry.snapshot.localeIdentifier ?? locale.identifier
    }

    private func color(for urgency: Double) -> Color {
        if urgency >= 0.9 {
            return Color(red: 0.96, green: 0.55, blue: 0.13)
        }
        if urgency >= 0.7 {
            return Color(red: 0.07, green: 0.52, blue: 1.0)
        }
        if urgency >= 0.4 {
            return Color(red: 0.07, green: 0.74, blue: 0.78)
        }
        return Color(.tertiaryLabel)
    }
}

private struct CleanCueWidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(red: 0.96, green: 0.99, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
