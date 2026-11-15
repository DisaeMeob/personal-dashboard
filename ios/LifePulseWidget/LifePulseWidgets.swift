import WidgetKit
import SwiftUI
import LifePulseCore

// MARK: - Timeline Entry

public struct LifePulseWidgetEntry: TimelineEntry {
    public let date: Date
    public let state: DashboardState

    public init(date: Date = Date(), state: DashboardState) {
        self.date = date
        self.state = state
    }

    public static var placeholder: LifePulseWidgetEntry {
        LifePulseWidgetEntry(
            date: Date(),
            state: LocalDashboardStore.makeDemoState()
        )
    }
}

// MARK: - Timeline Provider

public struct LifePulseWidgetProvider: TimelineProvider {
    public static let appGroupSuiteName = "group.com.lifepulse.shared"
    public static let userDefaultsStateKey = "lifepulse.dashboard.state"

    public init() {}

    public func placeholder(in context: Context) -> LifePulseWidgetEntry {
        .placeholder
    }

    public func getSnapshot(in context: Context, completion: @escaping (LifePulseWidgetEntry) -> Void) {
        completion(loadEntry(for: Date()))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<LifePulseWidgetEntry>) -> Void) {
        let now = Date()
        let entry = loadEntry(for: now)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// Читает локальное состояние дашборда из общего контейнера `UserDefaults(suiteName: "group.com.lifepulse.shared")`
    /// или JSON-хранилища App Group (`LocalDashboardStore`).
    public func loadEntry(for date: Date = Date()) -> LifePulseWidgetEntry {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // 1. Чтение из общего UserDefaults(suiteName: "group.com.lifepulse.shared")
        if let sharedDefaults = UserDefaults(suiteName: Self.appGroupSuiteName) {
            let candidateKeys = [
                Self.userDefaultsStateKey,
                "lifepulse_dashboard_state",
                "dashboardState"
            ]
            for key in candidateKeys {
                if let rawData = sharedDefaults.data(forKey: key),
                   let decoded = try? decoder.decode(DashboardState.self, from: rawData) {
                    return LifePulseWidgetEntry(date: date, state: decoded)
                }
            }
        }

        // 2. Чтение из общего контейнера App Group через LocalDashboardStore
        let store = LocalDashboardStore(seedDemoDataIfNeeded: true)
        return LifePulseWidgetEntry(date: date, state: store.currentState())
    }
}

// MARK: - Currency & Number Formatting Helpers

private enum WidgetFormatters {
    static func formatCurrency(_ amount: Double, symbol: String = "₽") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        let absValue = abs(amount)
        let formatted = formatter.string(from: NSNumber(value: absValue)) ?? "\(Int(absValue))"
        return amount < 0 ? "-\(formatted) \(symbol)" : "\(formatted) \(symbol)"
    }
}

// MARK: - 1. Small Widget («Цели и Фокус»)
// Кольцо прогресса целей на день (например, 3/5) + текущая задача в фокусе и ближайший слот расписания.

public struct LifePulseSmallWidgetView: View {
    public let entry: LifePulseWidgetEntry

    public init(entry: LifePulseWidgetEntry) {
        self.entry = entry
    }

    private var completedGoals: Int {
        entry.state.completedGoalsCount
    }

    private var totalGoals: Int {
        max(entry.state.dailyGoals.count, 1)
    }

    private var goalsFraction: Double {
        entry.state.dailyGoalsProgressFraction
    }

    private var nextScheduleSlot: ScheduleItem? {
        entry.state.schedule.first(where: { !$0.isCompleted }) ?? entry.state.schedule.first
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Верхний блок: Кольцо прогресса целей на день
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Color.indigo.opacity(0.2), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: goalsFraction)
                        .stroke(
                            AngularGradient(
                                colors: [.indigo, .purple, .cyan, .indigo],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(completedGoals)/\(totalGoals)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ЦЕЛИ ДНЯ")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("\(Int(entry.state.dailyGoalsProgressPercentage.rounded()))% выполнено")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                Spacer(minLength: 0)
            }

            Divider()

            // Средний блок: Текущая задача в фокусе
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    if let focus = entry.state.currentFocusTask {
                        Text("ФОКУС • \(focus.completedPomodoros)/\(focus.estimatedPomodoros) 🍅")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                    } else {
                        Text("В ФОКУСЕ")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                }

                Text(entry.state.currentFocusTask?.title ?? "Все задачи завершены")
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
            }

            Spacer(minLength: 0)

            // Нижний блок: Ближайший слот расписания
            if let nextSlot = nextScheduleSlot {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 6, height: 6)
                    Text(nextSlot.startTime)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(nextSlot.title)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - 2. Medium Widget («Расписание и Копилка»)
// Слева — ближайшие события расписания; справа — прогресс копилки («Коплю на ...», текущий баланс и сколько осталось накопить).

public struct LifePulseMediumWidgetView: View {
    public let entry: LifePulseWidgetEntry

    public init(entry: LifePulseWidgetEntry) {
        self.entry = entry
    }

    private var upcomingSchedule: [ScheduleItem] {
        let pending = entry.state.schedule.filter { !$0.isCompleted }
        if !pending.isEmpty {
            return Array(pending.prefix(3))
        }
        return Array(entry.state.schedule.prefix(3))
    }

    private var primarySavings: SavingsGoal {
        entry.state.primarySavingsGoal ?? SavingsGoal(
            title: "MacBook Pro M4 Max",
            targetAmount: 320_000,
            currentAmount: 215_000,
            currencySymbol: "₽"
        )
    }

    public var body: some View {
        HStack(spacing: 14) {
            // Левая колонка: Ближайшие события расписания
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.indigo)
                    Text("РАСПИСАНИЕ")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                ForEach(upcomingSchedule) { item in
                    HStack(alignment: .top, spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(item.isCompleted ? Color.green : Color.indigo)
                            .frame(width: 3, height: 26)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                            Text("\(item.startTime) – \(item.endTime) • \(item.category)")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Правая колонка: Копилка («Коплю на ...», баланс и сколько осталось накопить)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: primarySavings.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.mint)
                    Text("КОПИЛКА")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(primarySavings.progressPercentage.rounded()))%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.mint)
                }

                Text("Коплю на \(primarySavings.title)")
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                Text(WidgetFormatters.formatCurrency(primarySavings.currentAmount, symbol: primarySavings.currencySymbol))
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.mint)

                // Прогресс-бар накопления
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.mint.opacity(0.2))
                            .frame(height: 6)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.mint, .teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geo.size.width * primarySavings.progressFraction, 6), height: 6)
                    }
                }
                .frame(height: 6)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Осталось накопить:")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(WidgetFormatters.formatCurrency(primarySavings.remainingAmount, symbol: primarySavings.currencySymbol))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - 3. Large Widget («Полный дашборд LifePulse»)
// Расписание на день + Задача в фокусе + Цели на день + Копилка (с остатком до цели) + мини-кольцо соотношения Доходы / Расходы за месяц.

public struct LifePulseLargeWidgetView: View {
    public let entry: LifePulseWidgetEntry

    public init(entry: LifePulseWidgetEntry) {
        self.entry = entry
    }

    private var financeSummary: MonthlyFinanceSummary {
        entry.state.monthlyFinanceSummary
    }

    private var primarySavings: SavingsGoal {
        entry.state.primarySavingsGoal ?? SavingsGoal(
            title: "MacBook Pro M4 Max",
            targetAmount: 320_000,
            currentAmount: 215_000,
            currencySymbol: "₽"
        )
    }

    private var incomeFraction: Double {
        min(max(financeSummary.incomePercentage / 100.0, 0.0), 1.0)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1. Шапка: Название дашборда + Задача в фокусе
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg.rectangle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.indigo)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("LifePulse")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                        Text("Полный дашборд дня")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let focusTask = entry.state.currentFocusTask {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(focusTask.title)
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(1)
                                .frame(maxWidth: 155, alignment: .trailing)
                            Text("Фокус: \(focusTask.completedPomodoros)/\(focusTask.estimatedPomodoros) помидоров")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                }
            }

            Divider()

            // 2. Средний ряд: Расписание на день (слева) + Цели на день (справа)
            HStack(alignment: .top, spacing: 12) {
                // Расписание на день
                VStack(alignment: .leading, spacing: 5) {
                    Label("РАСПИСАНИЕ ДНЯ", systemImage: "calendar")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)

                    ForEach(Array(entry.state.schedule.prefix(4))) { item in
                        HStack(spacing: 5) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle.dotted")
                                .font(.system(size: 10))
                                .foregroundStyle(item.isCompleted ? .green : .indigo)
                            Text(item.startTime)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Text(item.title)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Цели на день
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Label("ЦЕЛИ ДНЯ", systemImage: "target")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(entry.state.completedGoalsCount)/\(entry.state.dailyGoals.count)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.purple)
                    }

                    ForEach(Array(entry.state.dailyGoals.prefix(4))) { goal in
                        HStack(spacing: 5) {
                            Image(systemName: goal.isCompleted ? "checkmark.seal.fill" : "circle")
                                .font(.system(size: 10))
                                .foregroundStyle(goal.isCompleted ? .purple : .secondary)
                            Text(goal.title)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Text("🔥\(goal.streakDays)")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // 3. Нижний ряд: Копилка (с остатком до цели) + Мини-кольцо Доходы / Расходы за месяц
            HStack(spacing: 10) {
                // Карточка Копилки
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label("КОПИЛКА", systemImage: "banknote.fill")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.mint)
                        Spacer()
                        Text("\(Int(primarySavings.progressPercentage.rounded()))%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.mint)
                    }

                    Text("Коплю на \(primarySavings.title)")
                        .font(.system(size: 11, weight: .bold))
                        .lineLimit(1)

                    Text("Баланс: \(WidgetFormatters.formatCurrency(primarySavings.currentAmount, symbol: primarySavings.currencySymbol))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Осталось: \(WidgetFormatters.formatCurrency(primarySavings.remainingAmount, symbol: primarySavings.currencySymbol))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.mint.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                // Карточка Доходы / Расходы с мини-кольцом
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.pink.opacity(0.35), lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: incomeFraction)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(financeSummary.incomePercentage.rounded()))%")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ДОХОДЫ / РАСХОДЫ")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 3) {
                            Circle().fill(Color.green).frame(width: 5, height: 5)
                            Text("+\(WidgetFormatters.formatCurrency(financeSummary.totalIncome))")
                                .font(.system(size: 9, weight: .semibold))
                                .lineLimit(1)
                        }
                        HStack(spacing: 3) {
                            Circle().fill(Color.pink).frame(width: 5, height: 5)
                            Text("-\(WidgetFormatters.formatCurrency(financeSummary.totalExpenses))")
                                .font(.system(size: 9, weight: .semibold))
                                .lineLimit(1)
                        }
                        Text("Чистый: +\(WidgetFormatters.formatCurrency(financeSummary.netBalance))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.green)
                            .lineLimit(1)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Adaptive Entry View

public struct LifePulseWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    public let entry: LifePulseWidgetEntry

    public init(entry: LifePulseWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        switch family {
        case .systemSmall:
            LifePulseSmallWidgetView(entry: entry)
        case .systemMedium:
            LifePulseMediumWidgetView(entry: entry)
        case .systemLarge:
            LifePulseLargeWidgetView(entry: entry)
        default:
            LifePulseSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configurations

public struct LifePulseGoalsFocusWidget: Widget {
    public let kind: String = "com.lifepulse.widget.small.goals-focus"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LifePulseWidgetProvider()) { entry in
            LifePulseSmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Цели и Фокус")
        .description("Кольцо прогресса целей на день, текущая задача в фокусе и ближайший слот расписания.")
        .supportedFamilies([.systemSmall])
    }
}

public struct LifePulseScheduleSavingsWidget: Widget {
    public let kind: String = "com.lifepulse.widget.medium.schedule-savings"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LifePulseWidgetProvider()) { entry in
            LifePulseMediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Расписание и Копилка")
        .description("Ближайшие события расписания, баланс копилки и сколько осталось накопить до цели.")
        .supportedFamilies([.systemMedium])
    }
}

public struct LifePulseFullDashboardWidget: Widget {
    public let kind: String = "com.lifepulse.widget.large.dashboard"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LifePulseWidgetProvider()) { entry in
            LifePulseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Полный дашборд LifePulse")
        .description("Расписание на день, задача в фокусе, цели, копилка и мини-кольцо Доходы / Расходы за месяц.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle

@main
public struct LifePulseWidgetBundle: WidgetBundle {
    public init() {}

    public var body: some Widget {
        LifePulseGoalsFocusWidget()
        LifePulseScheduleSavingsWidget()
        LifePulseFullDashboardWidget()
    }
}
