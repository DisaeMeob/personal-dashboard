import Foundation

// MARK: - Dashboard State Snapshot

public struct DashboardState: Codable, Equatable, Sendable {
    public var schedule: [ScheduleItem]
    public var focusTasks: [FocusTask]
    public var dailyGoals: [DailyGoal]
    public var savingsGoals: [SavingsGoal]
    public var transactions: [FinanceTransaction]
    public var lastUpdated: Date

    public init(
        schedule: [ScheduleItem] = [],
        focusTasks: [FocusTask] = [],
        dailyGoals: [DailyGoal] = [],
        savingsGoals: [SavingsGoal] = [],
        transactions: [FinanceTransaction] = [],
        lastUpdated: Date = Date()
    ) {
        self.schedule = schedule
        self.focusTasks = focusTasks
        self.dailyGoals = dailyGoals
        self.savingsGoals = savingsGoals
        self.transactions = transactions
        self.lastUpdated = lastUpdated
    }

    public var completedGoalsCount: Int {
        dailyGoals.filter(\.isCompleted).count
    }

    public var dailyGoalsProgressFraction: Double {
        guard !dailyGoals.isEmpty else { return 0.0 }
        return Double(completedGoalsCount) / Double(dailyGoals.count)
    }

    public var dailyGoalsProgressPercentage: Double {
        dailyGoalsProgressFraction * 100.0
    }

    public var currentFocusTask: FocusTask? {
        focusTasks.first(where: { $0.isCurrentFocus && !$0.isCompleted })
            ?? focusTasks.first(where: { !$0.isCompleted })
    }

    public var primarySavingsGoal: SavingsGoal? {
        savingsGoals.first
    }

    public var monthlyFinanceSummary: MonthlyFinanceSummary {
        MonthlyFinanceSummary(transactions: transactions)
    }
}

// MARK: - Local Dashboard Store (JSON Persistence on Device)

public final class LocalDashboardStore: @unchecked Sendable {
    public static let appGroupIdentifier = "group.com.lifepulse.shared"
    public static let defaultFileName = "lifepulse_dashboard_state.json"

    public let fileURL: URL
    private let lock = NSLock()
    private var state: DashboardState

    public init(fileURL: URL? = nil, seedDemoDataIfNeeded: Bool = true) {
        let resolvedURL = fileURL ?? Self.resolveDefaultFileURL()
        self.fileURL = resolvedURL

        if let loaded = Self.loadFromDisk(url: resolvedURL) {
            self.state = loaded
        } else if seedDemoDataIfNeeded {
            let demo = Self.makeDemoState()
            self.state = demo
            try? Self.saveToDisk(state: demo, url: resolvedURL)
        } else {
            self.state = DashboardState()
        }
    }

    public static func resolveDefaultFileURL(fileName: String = defaultFileName) -> URL {
        let fm = FileManager.default
        if let groupURL = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return groupURL.appendingPathComponent(fileName)
        }
        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let folder = appSupport.appendingPathComponent("LifePulse", isDirectory: true)
            try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
            return folder.appendingPathComponent(fileName)
        }
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        return docs.appendingPathComponent(fileName)
    }

    // MARK: - State Access & Persistence

    public func currentState() -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        return state
    }

    @discardableResult
    public func save() throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        state.lastUpdated = Date()
        try Self.saveToDisk(state: state, url: fileURL)
        return state
    }

    @discardableResult
    public func reload() -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        if let loaded = Self.loadFromDisk(url: fileURL) {
            state = loaded
        }
        return state
    }

    @discardableResult
    public func resetToDemoData() throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        state = Self.makeDemoState()
        try Self.saveToDisk(state: state, url: fileURL)
        return state
    }

    // MARK: - Schedule Actions

    @discardableResult
    public func toggleScheduleItem(id: UUID) throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        if let index = state.schedule.firstIndex(where: { $0.id == id }) {
            state.schedule[index].isCompleted.toggle()
            state.lastUpdated = Date()
            try Self.saveToDisk(state: state, url: fileURL)
        }
        return state
    }

    @discardableResult
    public func addScheduleItem(_ item: ScheduleItem) throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        state.schedule.append(item)
        state.schedule.sort { $0.startTime < $1.startTime }
        state.lastUpdated = Date()
        try Self.saveToDisk(state: state, url: fileURL)
        return state
    }

    // MARK: - Focus Task Actions

    @discardableResult
    public func toggleFocusTask(id: UUID) throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        if let index = state.focusTasks.firstIndex(where: { $0.id == id }) {
            state.focusTasks[index].isCompleted.toggle()
            if state.focusTasks[index].isCompleted {
                state.focusTasks[index].completedPomodoros = max(
                    state.focusTasks[index].completedPomodoros,
                    state.focusTasks[index].estimatedPomodoros
                )
            }
            state.lastUpdated = Date()
            try Self.saveToDisk(state: state, url: fileURL)
        }
        return state
    }

    @discardableResult
    public func setCurrentFocusTask(id: UUID) throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        for idx in state.focusTasks.indices {
            state.focusTasks[idx].isCurrentFocus = (state.focusTasks[idx].id == id)
        }
        state.lastUpdated = Date()
        try Self.saveToDisk(state: state, url: fileURL)
        return state
    }

    @discardableResult
    public func incrementPomodoro(forTaskID id: UUID) throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        if let index = state.focusTasks.firstIndex(where: { $0.id == id }) {
            state.focusTasks[index].completedPomodoros += 1
            state.lastUpdated = Date()
            try Self.saveToDisk(state: state, url: fileURL)
        }
        return state
    }

    @discardableResult
    public func addFocusTask(_ task: FocusTask) throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        if task.isCurrentFocus {
            for idx in state.focusTasks.indices {
                state.focusTasks[idx].isCurrentFocus = false
            }
        }
        state.focusTasks.append(task)
        state.lastUpdated = Date()
        try Self.saveToDisk(state: state, url: fileURL)
        return state
    }

    // MARK: - Daily Goal Actions

    @discardableResult
    public func toggleDailyGoal(id: UUID) throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        if let index = state.dailyGoals.firstIndex(where: { $0.id == id }) {
            state.dailyGoals[index].isCompleted.toggle()
            if state.dailyGoals[index].isCompleted {
                state.dailyGoals[index].streakDays += 1
            } else {
                state.dailyGoals[index].streakDays = max(0, state.dailyGoals[index].streakDays - 1)
            }
            state.lastUpdated = Date()
            try Self.saveToDisk(state: state, url: fileURL)
        }
        return state
    }

    @discardableResult
    public func addDailyGoal(_ goal: DailyGoal) throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        state.dailyGoals.append(goal)
        state.lastUpdated = Date()
        try Self.saveToDisk(state: state, url: fileURL)
        return state
    }

    // MARK: - Savings Goal (Копилка) Actions

    @discardableResult
    public func topUpSavingsGoal(id: UUID, amount: Double, note: String = "", date: Date = Date()) throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        if let index = state.savingsGoals.firstIndex(where: { $0.id == id }) {
            state.savingsGoals[index].topUp(amount: amount, note: note, date: date)
            state.lastUpdated = Date()
            try Self.saveToDisk(state: state, url: fileURL)
        }
        return state
    }

    @discardableResult
    public func addSavingsGoal(_ goal: SavingsGoal) throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        state.savingsGoals.append(goal)
        state.lastUpdated = Date()
        try Self.saveToDisk(state: state, url: fileURL)
        return state
    }

    @discardableResult
    public func removeSavingsGoal(id: UUID) throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        state.savingsGoals.removeAll { $0.id == id }
        state.lastUpdated = Date()
        try Self.saveToDisk(state: state, url: fileURL)
        return state
    }

    // MARK: - Finance Transaction Actions

    @discardableResult
    public func addTransaction(_ transaction: FinanceTransaction) throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        state.transactions.insert(transaction, at: 0)
        state.lastUpdated = Date()
        try Self.saveToDisk(state: state, url: fileURL)
        return state
    }

    @discardableResult
    public func removeTransaction(id: UUID) throws -> DashboardState {
        lock.lock()
        defer { lock.unlock() }
        state.transactions.removeAll { $0.id == id }
        state.lastUpdated = Date()
        try Self.saveToDisk(state: state, url: fileURL)
        return state
    }

    // MARK: - Disk Helpers

    private static func saveToDisk(state: DashboardState, url: URL) throws {
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(state)
        try data.write(to: url, options: [.atomic])
    }

    private static func loadFromDisk(url: URL) -> DashboardState? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(DashboardState.self, from: data)
    }

    // MARK: - Pre-seeded Russian Demo Data

    public static func makeDemoState(now: Date = Date()) -> DashboardState {
        let schedule: [ScheduleItem] = [
            ScheduleItem(
                title: "Утренняя пробежка и разминка",
                startTime: "07:30",
                endTime: "08:15",
                category: "Здоровье",
                isCompleted: true,
                icon: "figure.run"
            ),
            ScheduleItem(
                title: "Глубокий фокус: Архитектура iOS-виджетов",
                startTime: "09:30",
                endTime: "11:30",
                category: "Работа",
                isCompleted: true,
                icon: "laptopcomputer"
            ),
            ScheduleItem(
                title: "Синк с продуктовой командой",
                startTime: "12:00",
                endTime: "12:45",
                category: "Встречи",
                isCompleted: false,
                icon: "person.3.fill"
            ),
            ScheduleItem(
                title: "Ревью бюджета и пополнение копилки",
                startTime: "15:00",
                endTime: "15:45",
                category: "Финансы",
                isCompleted: false,
                icon: "chart.pie.fill"
            ),
            ScheduleItem(
                title: "Чтение книги и цифровой детокс",
                startTime: "21:00",
                endTime: "22:00",
                category: "Личное",
                isCompleted: false,
                icon: "book.fill"
            )
        ]

        let focusTasks: [FocusTask] = [
            FocusTask(
                title: "Спроектировать экран Копилки и круговую диаграмму финансов",
                priority: .high,
                isCompleted: false,
                estimatedPomodoros: 4,
                completedPomodoros: 2,
                isCurrentFocus: true
            ),
            FocusTask(
                title: "Настроить локальное сохранение JSON в AppGroup для виджета",
                priority: .high,
                isCompleted: true,
                estimatedPomodoros: 2,
                completedPomodoros: 2,
                isCurrentFocus: false
            ),
            FocusTask(
                title: "Подготовить отчёт по инвестициям за квартал",
                priority: .medium,
                isCompleted: false,
                estimatedPomodoros: 3,
                completedPomodoros: 1,
                isCurrentFocus: false
            )
        ]

        let dailyGoals: [DailyGoal] = [
            DailyGoal(
                title: "10 000 шагов и тренировка",
                isCompleted: true,
                streakDays: 14,
                icon: "flame.fill"
            ),
            DailyGoal(
                title: "Отложить 5 000 ₽ в копилку",
                isCompleted: true,
                streakDays: 9,
                icon: "banknote.fill"
            ),
            DailyGoal(
                title: "4 сессии глубокого фокуса без соцсетей",
                isCompleted: false,
                streakDays: 21,
                icon: "brain.head.profile"
            ),
            DailyGoal(
                title: "Выпить 2 литра воды",
                isCompleted: true,
                streakDays: 30,
                icon: "drop.fill"
            ),
            DailyGoal(
                title: "Чтение 30 минут перед сном",
                isCompleted: false,
                streakDays: 12,
                icon: "book.closed.fill"
            )
        ]

        let savingsGoals: [SavingsGoal] = [
            SavingsGoal(
                title: "MacBook Pro M4 Max",
                targetAmount: 320_000,
                currentAmount: 215_000,
                currencySymbol: "₽",
                icon: "laptopcomputer",
                contributions: [
                    SavingsContribution(amount: 35_000, date: now.addingTimeInterval(-86400 * 2), note: "От фриланс-проекта"),
                    SavingsContribution(amount: 50_000, date: now.addingTimeInterval(-86400 * 10), note: "Часть зарплаты"),
                    SavingsContribution(amount: 130_000, date: now.addingTimeInterval(-86400 * 25), note: "Стартовый взнос")
                ]
            ),
            SavingsGoal(
                title: "Отпуск в Японии (Токио — Киото)",
                targetAmount: 450_000,
                currentAmount: 180_000,
                currencySymbol: "₽",
                icon: "airplane.departure",
                contributions: [
                    SavingsContribution(amount: 30_000, date: now.addingTimeInterval(-86400 * 5), note: "Кэшбэк и бонусы"),
                    SavingsContribution(amount: 150_000, date: now.addingTimeInterval(-86400 * 20), note: "Накопления за весну")
                ]
            )
        ]

        let transactions: [FinanceTransaction] = [
            FinanceTransaction(
                title: "Основная зарплата (Senior iOS)",
                amount: 280_000,
                type: .income,
                category: "Зарплата",
                date: now.addingTimeInterval(-86400 * 12)
            ),
            FinanceTransaction(
                title: "Консалтинг и дизайн-аудит",
                amount: 65_000,
                type: .income,
                category: "Фриланс",
                date: now.addingTimeInterval(-86400 * 4)
            ),
            FinanceTransaction(
                title: "Дивиденды и проценты по вкладу",
                amount: 15_000,
                type: .income,
                category: "Инвестиции",
                date: now.addingTimeInterval(-86400 * 2)
            ),
            FinanceTransaction(
                title: "Аренда квартиры и ЖКУ",
                amount: 75_000,
                type: .expense,
                category: "Жильё",
                date: now.addingTimeInterval(-86400 * 10)
            ),
            FinanceTransaction(
                title: "Супермаркеты и фермерские продукты",
                amount: 38_000,
                type: .expense,
                category: "Продукты",
                date: now.addingTimeInterval(-86400 * 6)
            ),
            FinanceTransaction(
                title: "Кафе, рестораны и спешелти кофе",
                amount: 19_500,
                type: .expense,
                category: "Кафе и рестораны",
                date: now.addingTimeInterval(-86400 * 3)
            ),
            FinanceTransaction(
                title: "Фитнес-клуб, бассейн и чекап",
                amount: 14_500,
                type: .expense,
                category: "Здоровье и спорт",
                date: now.addingTimeInterval(-86400 * 8)
            ),
            FinanceTransaction(
                title: "Такси, каршеринг и подписки",
                amount: 13_000,
                type: .expense,
                category: "Транспорт и сервисы",
                date: now.addingTimeInterval(-86400 * 1)
            )
        ]

        return DashboardState(
            schedule: schedule,
            focusTasks: focusTasks,
            dailyGoals: dailyGoals,
            savingsGoals: savingsGoals,
            transactions: transactions,
            lastUpdated: now
        )
    }
}
