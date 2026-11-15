import Foundation
import SwiftUI
import Observation
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - Domain Models for LifePulse App

enum ScheduleCategory: String, Codable, CaseIterable, Identifiable {
    case work = "Работа"
    case health = "Здоровье"
    case learning = "Обучение"
    case personal = "Личное"
    case finance = "Финансы"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .health: return "heart.fill"
        case .learning: return "book.fill"
        case .personal: return "sparkles"
        case .finance: return "rublesign.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .work: return .indigo
        case .health: return .pink
        case .learning: return .orange
        case .personal: return .teal
        case .finance: return .green
        }
    }
}

struct ScheduleItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var subtitle: String
    var startTime: String // "09:00"
    var endTime: String   // "10:30"
    var category: ScheduleCategory
    var isCompleted: Bool = false
}

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case high = "Высокий"
    case medium = "Средний"
    case low = "Низкий"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    var badgeIcon: String {
        switch self {
        case .high: return "flame.fill"
        case .medium: return "bolt.fill"
        case .low: return "leaf.fill"
        }
    }
}

struct FocusTask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var note: String
    var priority: TaskPriority
    var estimatedPomodoros: Int
    var completedPomodoros: Int = 0
    var isCompleted: Bool = false
}

struct DailyGoal: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var icon: String
    var targetLabel: String
    var isCompleted: Bool
    var streakDays: Int
}

struct SavingsContribution: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var amount: Double
    var date: Date
    var comment: String
}

struct PiggyBankGoal: Codable, Equatable {
    var title: String
    var subtitle: String
    var icon: String
    var targetAmount: Double
    var savedAmount: Double
    var deadlineText: String
    var contributions: [SavingsContribution]

    var remainingAmount: Double {
        max(targetAmount - savedAmount, 0)
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(savedAmount / targetAmount, 1.0)
    }

    var progressPercent: Int {
        Int((progress * 100).rounded())
    }
}

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case income = "Доход"
    case expense = "Расход"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .income: return .green
        case .expense: return .red
        }
    }

    var symbol: String {
        switch self {
        case .income: return "+"
        case .expense: return "−"
        }
    }
}

enum FinanceCategory: String, Codable, CaseIterable, Identifiable {
    case salary = "Зарплата и проекты"
    case investments = "Инвестиции и кэшбэк"
    case housing = "Жильё и ЖКУ"
    case groceries = "Продукты и кафе"
    case transport = "Транспорт и такси"
    case subscriptions = "Подписки и сервисы"
    case leisure = "Отдых и хобби"

    var id: String { rawValue }

    var defaultType: TransactionType {
        switch self {
        case .salary, .investments:
            return .income
        case .housing, .groceries, .transport, .subscriptions, .leisure:
            return .expense
        }
    }

    var icon: String {
        switch self {
        case .salary: return "laptopcomputer"
        case .investments: return "chart.line.uptrend.xyaxis"
        case .housing: return "house.fill"
        case .groceries: return "cart.fill"
        case .transport: return "car.fill"
        case .subscriptions: return "sparkles.tv.fill"
        case .leisure: return "Ticket" == "Ticket" ? "theatermasks.fill" : "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .salary: return .green
        case .investments: return .mint
        case .housing: return .indigo
        case .groceries: return .orange
        case .transport: return .blue
        case .subscriptions: return .purple
        case .leisure: return .pink
        }
    }
}

struct FinanceTransaction: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var type: TransactionType
    var category: FinanceCategory
    var date: Date
}

struct FinanceSlice: Identifiable {
    var id: String
    var label: String
    var amount: Double
    var percentage: Double
    var color: Color
    var icon: String
}

// MARK: - Persistent Snapshot

private struct DashboardPersistenceSnapshot: Codable {
    var scheduleItems: [ScheduleItem]
    var focusTasks: [FocusTask]
    var activeFocusTaskID: UUID?
    var dailyGoals: [DailyGoal]
    var piggyBank: PiggyBankGoal
    var transactions: [FinanceTransaction]
    var completedPomodorosToday: Int
}

// MARK: - ViewModel

@Observable
final class DashboardViewModel {
    static let appGroupIdentifier = "group.com.lifepulse.shared"
    private static let storageKey = "lifepulse.dashboard.snapshot.v1"

    // State
    var selectedTab: AppTab = .dashboard
    var scheduleItems: [ScheduleItem] = []
    var focusTasks: [FocusTask] = []
    var activeFocusTaskID: UUID?
    var dailyGoals: [DailyGoal] = []
    var piggyBank: PiggyBankGoal
    var transactions: [FinanceTransaction] = []
    var completedPomodorosToday: Int = 3

    // Pomodoro Timer State
    let defaultFocusDuration: Int = 25 * 60
    var remainingFocusSeconds: Int = 25 * 60
    var isTimerRunning: Bool = false
    private var timer: Timer?

    enum AppTab: Hashable {
        case dashboard
        case schedule
        case focusAndGoals
        case finance
    }

    init() {
        self.piggyBank = Self.defaultPiggyBank()
        if !loadFromStorage() {
            seedDefaultData()
            saveToStorage()
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Computed Properties: Greeting & Date

    var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Доброе утро"
        case 12..<18: return "Добрый день"
        case 18..<23: return "Добрый вечер"
        default: return "Доброй ночи"
        }
    }

    var formattedTodayDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: Date()).capitalized
    }

    // MARK: - Computed Properties: Schedule

    var sortedSchedule: [ScheduleItem] {
        scheduleItems.sorted { $0.startTime < $1.startTime }
    }

    var upcomingScheduleItems: [ScheduleItem] {
        let pending = sortedSchedule.filter { !$0.isCompleted }
        if pending.count >= 2 {
            return Array(pending.prefix(2))
        }
        return Array(sortedSchedule.prefix(2))
    }

    var completedScheduleCount: Int {
        scheduleItems.filter(\.isCompleted).count
    }

    // MARK: - Computed Properties: Focus & Timer

    var activeFocusTask: FocusTask? {
        if let id = activeFocusTaskID,
           let match = focusTasks.first(where: { $0.id == id }) {
            return match
        }
        return focusTasks.first(where: { !$0.isCompleted }) ?? focusTasks.first
    }

    var timerProgress: Double {
        guard defaultFocusDuration > 0 else { return 0 }
        let elapsed = Double(defaultFocusDuration - remainingFocusSeconds)
        return min(max(elapsed / Double(defaultFocusDuration), 0), 1.0)
    }

    var formattedTimer: String {
        let minutes = remainingFocusSeconds / 60
        let seconds = remainingFocusSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Computed Properties: Daily Goals

    var completedGoalsCount: Int {
        dailyGoals.filter(\.isCompleted).count
    }

    var goalsProgress: Double {
        guard !dailyGoals.isEmpty else { return 0 }
        return Double(completedGoalsCount) / Double(dailyGoals.count)
    }

    var maxGoalStreak: Int {
        dailyGoals.map(\.streakDays).max() ?? 0
    }

    // MARK: - Computed Properties: Finance & Charts

    var totalMonthlyIncome: Double {
        transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    var totalMonthlyExpense: Double {
        transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    var netMonthlyBalance: Double {
        totalMonthlyIncome - totalMonthlyExpense
    }

    var savingsRatePercent: Int {
        guard totalMonthlyIncome > 0 else { return 0 }
        let ratio = max(netMonthlyBalance, 0) / totalMonthlyIncome
        return Int((ratio * 100).rounded())
    }

    /// Slices comparing Monthly Income vs Monthly Expense for overview Donut Chart
    var incomeVsExpenseSlices: [FinanceSlice] {
        let income = totalMonthlyIncome
        let expense = totalMonthlyExpense
        let total = max(income + expense, 1)

        return [
            FinanceSlice(
                id: "income",
                label: "Доходы",
                amount: income,
                percentage: (income / total) * 100,
                color: .green,
                icon: "arrow.down.left.circle.fill"
            ),
            FinanceSlice(
                id: "expense",
                label: "Расходы",
                amount: expense,
                percentage: (expense / total) * 100,
                color: .red,
                icon: "arrow.up.right.circle.fill"
            )
        ]
    }

    /// Detailed breakdown by category for the Finance Dashboard Chart
    var categoryBreakdownSlices: [FinanceSlice] {
        let totalFlow = max(totalMonthlyIncome + totalMonthlyExpense, 1)
        let grouped = Dictionary(grouping: transactions, by: \.category)

        return FinanceCategory.allCases.compactMap { category in
            let items = grouped[category] ?? []
            let sum = items.reduce(0) { $0 + $1.amount }
            guard sum > 0 else { return nil }
            return FinanceSlice(
                id: category.rawValue,
                label: category.rawValue,
                amount: sum,
                percentage: (sum / totalFlow) * 100,
                color: category.color,
                icon: category.icon
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    // MARK: - Actions: Schedule

    func toggleScheduleItem(_ item: ScheduleItem) {
        guard let index = scheduleItems.firstIndex(where: { $0.id == item.id }) else { return }
        scheduleItems[index].isCompleted.toggle()
        saveToStorage()
    }

    func addScheduleItem(
        title: String,
        subtitle: String,
        startTime: String,
        endTime: String,
        category: ScheduleCategory
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newItem = ScheduleItem(
            title: trimmed,
            subtitle: subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            startTime: startTime,
            endTime: endTime,
            category: category,
            isCompleted: false
        )
        scheduleItems.append(newItem)
        saveToStorage()
    }

    func deleteScheduleItems(at offsets: IndexSet) {
        let current = sortedSchedule
        let idsToDelete = offsets.map { current[$0].id }
        scheduleItems.removeAll { idsToDelete.contains($0.id) }
        saveToStorage()
    }

    // MARK: - Actions: Focus & Pomodoro Timer

    func selectTaskForFocus(_ task: FocusTask) {
        activeFocusTaskID = task.id
        saveToStorage()
    }

    func toggleTaskCompletion(_ task: FocusTask) {
        guard let index = focusTasks.firstIndex(where: { $0.id == task.id }) else { return }
        focusTasks[index].isCompleted.toggle()
        saveToStorage()
    }

    func addFocusTask(title: String, note: String, priority: TaskPriority, estimatedPomodoros: Int) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let task = FocusTask(
            title: trimmed,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority,
            estimatedPomodoros: max(1, estimatedPomodoros)
        )
        focusTasks.insert(task, at: 0)
        if activeFocusTaskID == nil {
            activeFocusTaskID = task.id
        }
        saveToStorage()
    }

    func toggleTimer() {
        if isTimerRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }

    func startTimer() {
        guard !isTimerRunning else { return }
        isTimerRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.remainingFocusSeconds > 0 {
                self.remainingFocusSeconds -= 1
            } else {
                self.completePomodoroSession()
            }
        }
    }

    func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }

    func resetTimer() {
        pauseTimer()
        remainingFocusSeconds = defaultFocusDuration
    }

    func completePomodoroSession() {
        pauseTimer()
        remainingFocusSeconds = defaultFocusDuration
        completedPomodorosToday += 1
        if let activeID = activeFocusTask?.id,
           let idx = focusTasks.firstIndex(where: { $0.id == activeID }) {
            focusTasks[idx].completedPomodoros += 1
        }
        saveToStorage()
    }

    // MARK: - Actions: Daily Goals

    func toggleDailyGoal(_ goal: DailyGoal) {
        guard let index = dailyGoals.firstIndex(where: { $0.id == goal.id }) else { return }
        dailyGoals[index].isCompleted.toggle()
        if dailyGoals[index].isCompleted {
            dailyGoals[index].streakDays += 1
        } else {
            dailyGoals[index].streakDays = max(0, dailyGoals[index].streakDays - 1)
        }
        saveToStorage()
    }

    func addDailyGoal(title: String, targetLabel: String, icon: String = "checkmark.seal.fill") {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        dailyGoals.append(
            DailyGoal(
                title: trimmed,
                icon: icon,
                targetLabel: targetLabel.isEmpty ? "Ежедневно" : targetLabel,
                isCompleted: false,
                streakDays: 1
            )
        )
        saveToStorage()
    }

    // MARK: - Actions: Piggy Bank ("Копилка") & Finance

    func depositToPiggyBank(amount: Double, comment: String = "Быстрое пополнение") {
        guard amount > 0 else { return }
        piggyBank.savedAmount += amount
        let entry = SavingsContribution(
            amount: amount,
            date: Date(),
            comment: comment
        )
        piggyBank.contributions.insert(entry, at: 0)
        saveToStorage()
    }

    func updatePiggyBankGoal(title: String, subtitle: String, targetAmount: Double) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, targetAmount > 0 else { return }
        piggyBank.title = trimmed
        piggyBank.subtitle = subtitle
        piggyBank.targetAmount = targetAmount
        saveToStorage()
    }

    func resetOrDeletePiggyBankGoal(newTitle: String = "Новая цель", newTarget: Double = 100_000) {
        piggyBank = PiggyBankGoal(
            title: newTitle,
            subtitle: "Личная цель накопления",
            icon: "target",
            targetAmount: newTarget,
            savedAmount: 0,
            contributions: []
        )
        saveToStorage()
    }

    func deleteContribution(id: UUID) {
        guard let idx = piggyBank.contributions.firstIndex(where: { $0.id == id }) else { return }
        let amount = piggyBank.contributions[idx].amount
        piggyBank.savedAmount = max(0, piggyBank.savedAmount - amount)
        piggyBank.contributions.remove(at: idx)
        saveToStorage()
    }

    func addTransaction(
        title: String,
        amount: Double,
        type: TransactionType,
        category: FinanceCategory
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, amount > 0 else { return }
        let tx = FinanceTransaction(
            title: trimmed,
            amount: amount,
            type: type,
            category: category,
            date: Date()
        )
        transactions.insert(tx, at: 0)
        saveToStorage()
    }

    // MARK: - Currency Formatting Helper

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = . decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        let numberString = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(numberString) ₽"
    }

    // MARK: - Persistence (App Group UserDefaults + Local JSON File)

    private var jsonFileURL: URL? {
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ) {
            return groupURL.appendingPathComponent("lifepulse_dashboard.json")
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("lifepulse_dashboard.json")
    }

    func saveToStorage() {
        let snapshot = DashboardPersistenceSnapshot(
            scheduleItems: scheduleItems,
            focusTasks: focusTasks,
            activeFocusTaskID: activeFocusTaskID,
            dailyGoals: dailyGoals,
            piggyBank: piggyBank,
            transactions: transactions,
            completedPomodorosToday: completedPomodorosToday
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(snapshot) else { return }

        if let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) {
            sharedDefaults.set(data, forKey: Self.storageKey)
        }
        UserDefaults.standard.set(data, forKey: Self.storageKey)

        if let fileURL = jsonFileURL {
            try? data.write(to: fileURL, options: [.atomic])
        }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    @discardableResult
    private func loadFromStorage() -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var rawData: Data?
        if let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier),
           let data = sharedDefaults.data(forKey: Self.storageKey) {
            rawData = data
        } else if let fileURL = jsonFileURL,
                  let data = try? Data(contentsOf: fileURL) {
            rawData = data
        } else if let data = UserDefaults.standard.data(forKey: Self.storageKey) {
            rawData = data
        }

        guard let data = rawData,
              let snapshot = try? decoder.decode(DashboardPersistenceSnapshot.self, from: data) else {
            return false
        }

        self.scheduleItems = snapshot.scheduleItems
        self.focusTasks = snapshot.focusTasks
        self.activeFocusTaskID = snapshot.activeFocusTaskID
        self.dailyGoals = snapshot.dailyGoals
        self.piggyBank = snapshot.piggyBank
        self.transactions = snapshot.transactions
        self.completedPomodorosToday = snapshot.completedPomodorosToday
        return true
    }

    // MARK: - Default Seed Data

    private static func defaultPiggyBank() -> PiggyBankGoal {
        PiggyBankGoal(
            title: "Отпуск мечты в Японии",
            subtitle: "Токио • Киото • Осака весной",
            icon: "airplane.departure",
            targetAmount: 350_000,
            savedAmount: 215_000,
            deadlineText: "Апрель 2025",
            contributions: [
                SavingsContribution(
                    amount: 15_000,
                    date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                    comment: "Отложено с аванса"
                ),
                SavingsContribution(
                    amount: 10_000,
                    date: Calendar.current.date(byAdding: .day, value: -9, to: Date()) ?? Date(),
                    comment: "Кэшбэк и проценты по счёту"
                ),
                SavingsContribution(
                    amount: 25_000,
                    date: Calendar.current.date(byAdding: .day, value: -18, to: Date()) ?? Date(),
                    comment: "Фриланс-проект iOS"
                )
            ]
        )
    }

    private func seedDefaultData() {
        scheduleItems = [
            ScheduleItem(
                title: "Утренняя пробежка и разминка",
                subtitle: "Парк у дома • 5 км в лёгком темпе",
                startTime: "08:00",
                endTime: "08:45",
                category: .health,
                isCompleted: true
            ),
            ScheduleItem(
                title: "Архитектурное ревью iOS-приложения",
                subtitle: "Bento Grid UI + Swift Charts + Виджеты",
                startTime: "10:00",
                endTime: "11:30",
                category: .work,
                isCompleted: false
            ),
            ScheduleItem(
                title: "Глубокий фокус: Финансовый модуль",
                subtitle: "Интеграция копилки и диаграммы расходов",
                startTime: "13:00",
                endTime: "14:30",
                category: .work,
                isCompleted: false
            ),
            ScheduleItem(
                title: "Английский язык с преподавателем",
                subtitle: "Разговорная практика • Tech interview",
                startTime: "17:00",
                endTime: "18:00",
                category: .learning,
                isCompleted: false
            ),
            ScheduleItem(
                title: "Анализ семейного бюджета за месяц",
                subtitle: "Пополнение копилки и проверка подписок",
                startTime: "20:00",
                endTime: "20:40",
                category: .finance,
                isCompleted: false
            )
        ]

        let firstTask = FocusTask(
            title: "Сверстать Bento-дашборд и виджеты iOS 18",
            note: "Адаптивная сетка карточек, кольцо целей и круговая диаграмма",
            priority: .high,
            estimatedPomodoros: 4,
            completedPomodoros: 2,
            isCompleted: false
        )
        focusTasks = [
            firstTask,
            FocusTask(
                title: "Подготовить отчёт по доходам и расходам",
                note: "Сверить категории и перевести остаток в копилку",
                priority: .medium,
                estimatedPomodoros: 2,
                completedPomodoros: 1,
                isCompleted: false
            ),
            FocusTask(
                title: "Прочитать главу по Swift Concurrency",
                note: "Actors, Structured Concurrency и Sendable",
                priority: .low,
                estimatedPomodoros: 2,
                completedPomodoros: 0,
                isCompleted: false
            ),
            FocusTask(
                title: "Утренняя медитация и план на день",
                note: "10 минут тишины перед работой",
                priority: .medium,
                estimatedPomodoros: 1,
                completedPomodoros: 1,
                isCompleted: true
            )
        ]
        activeFocusTaskID = firstTask.id

        dailyGoals = [
            DailyGoal(
                title: "Выпить 2 литра чистой воды",
                icon: "drop.fill",
                targetLabel: "2.0 л",
                isCompleted: true,
                streakDays: 14
            ),
            DailyGoal(
                title: "10 000 шагов за день",
                icon: "figure.walk",
                targetLabel: "10 000 шагов",
                isCompleted: true,
                streakDays: 9
            ),
            DailyGoal(
                title: "4 фокус-сессии Помодоро без соцсетей",
                icon: "timer",
                targetLabel: "100 мин",
                isCompleted: false,
                streakDays: 12
            ),
            DailyGoal(
                title: "Чтение книги перед сном",
                icon: "book.closed.fill",
                targetLabel: "30 стр.",
                isCompleted: false,
                streakDays: 7
            ),
            DailyGoal(
                title: "Отложить минимум 1 000 ₽ в копилку",
                icon: "banknote.fill",
                targetLabel: "1 000 ₽",
                isCompleted: true,
                streakDays: 21
            )
        ]

        piggyBank = Self.defaultPiggyBank()

        transactions = [
            FinanceTransaction(
                title: "Зарплата (основной проект)",
                amount: 210_000,
                type: .income,
                category: .salary,
                date: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()
            ),
            FinanceTransaction(
                title: "Дизайн и разработка iOS-виджета",
                amount: 45_000,
                type: .income,
                category: .salary,
                date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            ),
            FinanceTransaction(
                title: "Дивиденды и процент на остаток",
                amount: 12_500,
                type: .income,
                category: .investments,
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
            FinanceTransaction(
                title: "Аренда квартиры и коммунальные",
                amount: 65_000,
                type: .expense,
                category: .housing,
                date: Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date()
            ),
            FinanceTransaction(
                title: "Супермаркеты, фермерские продукты и кофе",
                amount: 34_200,
                type: .expense,
                category: .groceries,
                date: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date()
            ),
            FinanceTransaction(
                title: "Такси, метро и каршеринг",
                amount: 11_800,
                type: .expense,
                category: .transport,
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            ),
            FinanceTransaction(
                title: "Apple One, облако и рабочие сервисы",
                amount: 4_500,
                type: .expense,
                category: .subscriptions,
                date: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
            ),
            FinanceTransaction(
                title: "Спортзал, кино и встреча с друзьями",
                amount: 16_000,
                type: .expense,
                category: .leisure,
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            )
        ]
    }
}
