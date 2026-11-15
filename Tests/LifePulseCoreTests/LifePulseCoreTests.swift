import Foundation
@testable import LifePulseCore

#if canImport(XCTest)
import XCTest

final class LifePulseCoreTests: XCTestCase {

    func testSavingsGoalCalculationsAndTopUp() {
        var goal = SavingsGoal(
            title: "MacBook Pro M4",
            targetAmount: 300_000,
            currentAmount: 120_000,
            currencySymbol: "₽"
        )

        XCTAssertEqual(goal.remainingAmount, 180_000, accuracy: 0.001)
        XCTAssertEqual(goal.progressFraction, 0.4, accuracy: 0.0001)
        XCTAssertEqual(goal.progressPercentage, 40.0, accuracy: 0.01)
        XCTAssertFalse(goal.isGoalReached)

        goal.topUp(amount: 60_000, note: "Премия за проект")
        XCTAssertEqual(goal.currentAmount, 180_000, accuracy: 0.001)
        XCTAssertEqual(goal.remainingAmount, 120_000, accuracy: 0.001)
        XCTAssertEqual(goal.progressPercentage, 60.0, accuracy: 0.01)
        XCTAssertEqual(goal.contributions.count, 1)
        XCTAssertEqual(goal.contributions.first?.note, "Премия за проект")

        goal.topUp(amount: 150_000, note: "Финальный взнос")
        XCTAssertEqual(goal.remainingAmount, 0.0, accuracy: 0.001)
        XCTAssertEqual(goal.progressPercentage, 100.0, accuracy: 0.01)
        XCTAssertTrue(goal.isGoalReached)
    }

    func testMonthlyFinanceSummaryPieChartCalculations() {
        let transactions: [FinanceTransaction] = [
            FinanceTransaction(title: "Зарплата", amount: 200_000, type: .income, category: "Зарплата"),
            FinanceTransaction(title: "Фриланс", amount: 100_000, type: .income, category: "Фриланс"),
            FinanceTransaction(title: "Аренда", amount: 60_000, type: .expense, category: "Жильё"),
            FinanceTransaction(title: "Еда", amount: 40_000, type: .expense, category: "Продукты")
        ]

        let summary = MonthlyFinanceSummary(transactions: transactions)

        XCTAssertEqual(summary.totalIncome, 300_000, accuracy: 0.001)
        XCTAssertEqual(summary.totalExpenses, 100_000, accuracy: 0.001)
        XCTAssertEqual(summary.netBalance, 200_000, accuracy: 0.001)

        // Оборот = 300_000 + 100_000 = 400_000 -> Доходы 75%, Расходы 25%
        XCTAssertEqual(summary.incomePercentage, 75.0, accuracy: 0.01)
        XCTAssertEqual(summary.expensePercentage, 25.0, accuracy: 0.01)

        // Норма сбережений = (300_000 - 100_000) / 300_000 = 66.666...%
        XCTAssertEqual(summary.savingsRatePercentage, 66.666, accuracy: 0.01)

        XCTAssertEqual(summary.expenseCategories.count, 2)
        XCTAssertEqual(summary.expenseCategories[0].category, "Жильё")
        XCTAssertEqual(summary.expenseCategories[0].percentage, 60.0, accuracy: 0.01)
        XCTAssertEqual(summary.expenseCategories[1].category, "Продукты")
        XCTAssertEqual(summary.expenseCategories[1].percentage, 40.0, accuracy: 0.01)
    }

    func testLocalDashboardStorePersistenceAndMutations() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LifePulseTests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = tempDir.appendingPathComponent("dashboard.json")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = LocalDashboardStore(fileURL: fileURL, seedDemoDataIfNeeded: true)
        let initial = store.currentState()

        XCTAssertFalse(initial.schedule.isEmpty)
        XCTAssertFalse(initial.focusTasks.isEmpty)
        XCTAssertFalse(initial.dailyGoals.isEmpty)
        XCTAssertFalse(initial.savingsGoals.isEmpty)
        XCTAssertFalse(initial.transactions.isEmpty)

        // Проверка пополнения копилки и сохранения на диск
        let firstSavingsID = try XCTUnwrap(initial.savingsGoals.first?.id)
        let beforeAmount = try XCTUnwrap(initial.savingsGoals.first?.currentAmount)
        try store.topUpSavingsGoal(id: firstSavingsID, amount: 25_000, note: "Тестовое пополнение")

        // Создаём второй экземпляр хранилища на том же файле, чтобы проверить реальное чтение с диска
        let reloadedStore = LocalDashboardStore(fileURL: fileURL, seedDemoDataIfNeeded: false)
        let reloadedGoal = try XCTUnwrap(reloadedStore.currentState().savingsGoals.first(where: { $0.id == firstSavingsID }))
        XCTAssertEqual(reloadedGoal.currentAmount, beforeAmount + 25_000, accuracy: 0.001)
        XCTAssertEqual(reloadedGoal.contributions.first?.note, "Тестовое пополнение")

        // Проверка переключения ежедневной цели
        let goalID = try XCTUnwrap(reloadedStore.currentState().dailyGoals.first?.id)
        let wasCompleted = try XCTUnwrap(reloadedStore.currentState().dailyGoals.first?.isCompleted)
        let updatedState = try reloadedStore.toggleDailyGoal(id: goalID)
        let toggledGoal = try XCTUnwrap(updatedState.dailyGoals.first(where: { $0.id == goalID }))
        XCTAssertEqual(toggledGoal.isCompleted, !wasCompleted)
    }
}
#else
// Fallback verification suite when full Xcode XCTest framework is not present (CommandLineTools environment)
public enum LifePulseCoreTests {
    public static func runAll() throws {
        var goal = SavingsGoal(
            title: "MacBook Pro M4",
            targetAmount: 300_000,
            currentAmount: 120_000,
            currencySymbol: "₽"
        )
        precondition(abs(goal.remainingAmount - 180_000) < 0.001)
        precondition(abs(goal.progressFraction - 0.4) < 0.0001)
        precondition(abs(goal.progressPercentage - 40.0) < 0.01)
        precondition(!goal.isGoalReached)

        goal.topUp(amount: 60_000, note: "Премия за проект")
        precondition(abs(goal.currentAmount - 180_000) < 0.001)
        precondition(abs(goal.remainingAmount - 120_000) < 0.001)
        precondition(abs(goal.progressPercentage - 60.0) < 0.01)
        precondition(goal.contributions.count == 1)

        goal.topUp(amount: 150_000, note: "Финальный взнос")
        precondition(abs(goal.remainingAmount - 0.0) < 0.001)
        precondition(abs(goal.progressPercentage - 100.0) < 0.01)
        precondition(goal.isGoalReached)

        let transactions: [FinanceTransaction] = [
            FinanceTransaction(title: "Зарплата", amount: 200_000, type: .income, category: "Зарплата"),
            FinanceTransaction(title: "Фриланс", amount: 100_000, type: .income, category: "Фриланс"),
            FinanceTransaction(title: "Аренда", amount: 60_000, type: .expense, category: "Жильё"),
            FinanceTransaction(title: "Еда", amount: 40_000, type: .expense, category: "Продукты")
        ]
        let summary = MonthlyFinanceSummary(transactions: transactions)
        precondition(abs(summary.totalIncome - 300_000) < 0.001)
        precondition(abs(summary.totalExpenses - 100_000) < 0.001)
        precondition(abs(summary.netBalance - 200_000) < 0.001)
        precondition(abs(summary.incomePercentage - 75.0) < 0.01)
        precondition(abs(summary.expensePercentage - 25.0) < 0.01)

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LifePulseTests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = tempDir.appendingPathComponent("dashboard.json")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = LocalDashboardStore(fileURL: fileURL, seedDemoDataIfNeeded: true)
        let initial = store.currentState()
        precondition(!initial.schedule.isEmpty)
        precondition(!initial.savingsGoals.isEmpty)

        let firstSavingsID = initial.savingsGoals[0].id
        let beforeAmount = initial.savingsGoals[0].currentAmount
        try store.topUpSavingsGoal(id: firstSavingsID, amount: 25_000, note: "Тестовое пополнение")

        let reloadedStore = LocalDashboardStore(fileURL: fileURL, seedDemoDataIfNeeded: false)
        let reloadedGoal = reloadedStore.currentState().savingsGoals.first(where: { $0.id == firstSavingsID })!
        precondition(abs(reloadedGoal.currentAmount - (beforeAmount + 25_000)) < 0.001)
    }
}
#endif
