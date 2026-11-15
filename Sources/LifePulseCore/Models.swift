import Foundation

// MARK: - Schedule Item

public struct ScheduleItem: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var startTime: String
    public var endTime: String
    public var category: String
    public var isCompleted: Bool
    public var icon: String

    public init(
        id: UUID = UUID(),
        title: String,
        startTime: String,
        endTime: String,
        category: String,
        isCompleted: Bool = false,
        icon: String = "calendar"
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.category = category
        self.isCompleted = isCompleted
        self.icon = icon
    }
}

// MARK: - Focus Task & Task Priority

public enum TaskPriority: String, Codable, Equatable, CaseIterable, Sendable {
    case high
    case medium
    case low

    public var displayTitle: String {
        switch self {
        case .high: return "Высокий"
        case .medium: return "Средний"
        case .low: return "Низкий"
        }
    }
}

public struct FocusTask: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var priority: TaskPriority
    public var isCompleted: Bool
    public var estimatedPomodoros: Int
    public var completedPomodoros: Int
    public var isCurrentFocus: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        priority: TaskPriority = .medium,
        isCompleted: Bool = false,
        estimatedPomodoros: Int = 2,
        completedPomodoros: Int = 0,
        isCurrentFocus: Bool = false
    ) {
        self.id = id
        self.title = title
        self.priority = priority
        self.isCompleted = isCompleted
        self.estimatedPomodoros = max(1, estimatedPomodoros)
        self.completedPomodoros = max(0, completedPomodoros)
        self.isCurrentFocus = isCurrentFocus
    }

    public var pomodoroProgressFraction: Double {
        guard estimatedPomodoros > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(completedPomodoros) / Double(estimatedPomodoros)))
    }
}

// MARK: - Daily Goal

public struct DailyGoal: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var streakDays: Int
    public var icon: String

    public init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        streakDays: Int = 0,
        icon: String = "checkmark.seal.fill"
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.streakDays = max(0, streakDays)
        self.icon = icon
    }
}

// MARK: - Savings Goal (Копилка)

public struct SavingsContribution: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var amount: Double
    public var date: Date
    public var note: String

    public init(
        id: UUID = UUID(),
        amount: Double,
        date: Date = Date(),
        note: String = ""
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
    }
}

public struct SavingsGoal: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var targetAmount: Double
    public var currentAmount: Double
    public var currencySymbol: String
    public var icon: String
    public var contributions: [SavingsContribution]

    public init(
        id: UUID = UUID(),
        title: String,
        targetAmount: Double,
        currentAmount: Double = 0,
        currencySymbol: String = "₽",
        icon: String = "banknote.fill",
        contributions: [SavingsContribution] = []
    ) {
        self.id = id
        self.title = title
        self.targetAmount = max(0, targetAmount)
        self.currentAmount = max(0, currentAmount)
        self.currencySymbol = currencySymbol
        self.icon = icon
        self.contributions = contributions
    }

    /// Сколько осталось накопить до цели
    public var remainingAmount: Double {
        max(0.0, targetAmount - currentAmount)
    }

    /// Доля прогресса от 0.0 до 1.0
    public var progressFraction: Double {
        guard targetAmount > 0 else { return currentAmount > 0 ? 1.0 : 0.0 }
        return min(1.0, max(0.0, currentAmount / targetAmount))
    }

    /// Процент накопления от 0.0 до 100.0 (ограничено 100%)
    public var progressPercentage: Double {
        progressFraction * 100.0
    }

    /// Достигнута ли цель накопления
    public var isGoalReached: Bool {
        currentAmount >= targetAmount && targetAmount > 0
    }

    /// Пополняет баланс копилки и добавляет запись в историю пополнений
    public mutating func topUp(amount: Double, note: String = "", date: Date = Date()) {
        guard amount > 0 else { return }
        currentAmount += amount
        let contribution = SavingsContribution(amount: amount, date: date, note: note)
        contributions.insert(contribution, at: 0)
    }
}

// MARK: - Finance Transactions & Monthly Summary (Круговая диаграмма Доходы / Расходы)

public enum TransactionType: String, Codable, Equatable, CaseIterable, Sendable {
    case income
    case expense

    public var displayTitle: String {
        switch self {
        case .income: return "Доход"
        case .expense: return "Расход"
        }
    }
}

public struct FinanceTransaction: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var amount: Double
    public var type: TransactionType
    public var category: String
    public var date: Date

    public init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        type: TransactionType,
        category: String,
        date: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.amount = max(0, amount)
        self.type = type
        self.category = category
        self.date = date
    }
}

public struct CategorySlice: Codable, Identifiable, Equatable, Sendable {
    public var id: String { category }
    public var category: String
    public var amount: Double
    public var percentage: Double

    public init(category: String, amount: Double, percentage: Double) {
        self.category = category
        self.amount = amount
        self.percentage = percentage
    }
}

public struct MonthlyFinanceSummary: Codable, Equatable, Sendable {
    public let totalIncome: Double
    public let totalExpenses: Double
    public let netBalance: Double
    public let incomePercentage: Double
    public let expensePercentage: Double
    public let savingsRatePercentage: Double
    public let expenseCategories: [CategorySlice]

    public init(transactions: [FinanceTransaction]) {
        let income = transactions
            .filter { $0.type == .income }
            .reduce(0.0) { $0 + $1.amount }
        let expenses = transactions
            .filter { $0.type == .expense }
            .reduce(0.0) { $0 + $1.amount }

        self.totalIncome = income
        self.totalExpenses = expenses
        self.netBalance = income - expenses

        let turnover = income + expenses
        if turnover > 0 {
            self.incomePercentage = (income / turnover) * 100.0
            self.expensePercentage = (expenses / turnover) * 100.0
        } else {
            self.incomePercentage = 0.0
            self.expensePercentage = 0.0
        }

        if income > 0 {
            self.savingsRatePercentage = max(0.0, ((income - expenses) / income) * 100.0)
        } else {
            self.savingsRatePercentage = 0.0
        }

        var groupedExpenses: [String: Double] = [:]
        for tx in transactions where tx.type == .expense {
            groupedExpenses[tx.category, default: 0.0] += tx.amount
        }

        if expenses > 0 {
            self.expenseCategories = groupedExpenses
                .map { key, value in
                    CategorySlice(
                        category: key,
                        amount: value,
                        percentage: (value / expenses) * 100.0
                    )
                }
                .sorted { $0.amount > $1.amount }
        } else {
            self.expenseCategories = []
        }
    }
}
