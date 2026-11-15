import SwiftUI
import Charts

struct FinanceDashboardView: View {
    @Bindable var viewModel: DashboardViewModel

    @State private var chartMode: ChartDisplayMode = .incomeVsExpense
    @State private var showCustomDepositSheet = false
    @State private var showEditGoalSheet = false
    @State private var showAddTransactionSheet = false

    enum ChartDisplayMode: String, CaseIterable, Identifiable {
        case incomeVsExpense = "Доходы vs Расходы"
        case byCategory = "По категориям"

        var id: String { rawValue }
    }

    private var activeSlices: [FinanceSlice] {
        switch chartMode {
        case .incomeVsExpense:
            return viewModel.incomeVsExpenseSlices
        case .byCategory:
            return viewModel.categoryBreakdownSlices
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Piggy Bank Block ("Копилка: На что я коплю")
                piggyBankDetailedSection

                // 2. Donut Chart Block ("Круговая диаграмма Доходы / Расходы за месяц")
                monthlyDonutChartSection

                // 3. Monthly Transactions List + Add Transaction Button
                transactionsListSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Мои финансы")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showAddTransactionSheet = true
                } label: {
                    Label("Операция", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .sheet(isPresented: $showCustomDepositSheet) {
            CustomPiggyDepositSheet(viewModel: viewModel)
                .presentationDetents([.height(350)])
        }
        .sheet(isPresented: $showEditGoalSheet) {
            EditPiggyGoalSheet(viewModel: viewModel)
                .presentationDetents([.height(360)])
        }
        .sheet(isPresented: $showAddTransactionSheet) {
            AddFinanceTransactionSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - 1. Блок «Копилка (На что я коплю)»

    private var piggyBankDetailedSection: some View {
        let piggy = viewModel.piggyBank

        return VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    Image(systemName: piggy.icon)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(
                            LinearGradient(
                                colors: [.pink, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("КОПИЛКА • НА ЧТО Я КОПЛЮ")
                            .font(.caption2.bold())
                            .foregroundStyle(.pink)
                            .tracking(0.6)

                        Text(piggy.title)
                            .font(.title3.bold())

                        Text(piggy.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    showEditGoalSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                        .padding(9)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Изменить цель копилки")
            }

            // Highlighted Banner: "Осталось накопить: X ₽" + Completion Percentage
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Осталось накопить:")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))

                        Text(viewModel.formatCurrency(piggy.remainingAmount))
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(piggy.progressPercent)%")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("выполнено")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }

                // Progress bar inside hero banner
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.25))
                            .frame(height: 10)
                        Capsule()
                            .fill(.white)
                            .frame(width: max(12, proxy.size.width * piggy.progress), height: 10)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("Накоплено: \(viewModel.formatCurrency(piggy.savedAmount))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("Цель: \(viewModel.formatCurrency(piggy.targetAmount))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.pink, Color.orange.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )

            // Quick Top-Up Buttons: +1 000 ₽, +5 000 ₽, +10 000 ₽, and "Своя сумма"
            VStack(alignment: .leading, spacing: 8) {
                Text("Быстрое пополнение копилки")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    quickDepositButton(amount: 1_000, label: "+1 000 ₽")
                    quickDepositButton(amount: 5_000, label: "+5 000 ₽")
                    quickDepositButton(amount: 10_000, label: "+10 000 ₽")
                }

                Button {
                    showCustomDepositSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Своя сумма пополнения")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.pink.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.pink)
                }
                .buttonStyle(.plain)
            }

            // Contribution History ("История пополнений")
            VStack(alignment: .leading, spacing: 8) {
                Text("История пополнений (\(piggy.contributions.count))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(piggy.contributions.prefix(4)) { entry in
                    HStack {
                        Image(systemName: "arrow.up.Heart.fill" == "arrow.up.Heart.fill" ? "sparkles" : "plus")
                            .font(.caption)
                            .foregroundStyle(.pink)
                            .frame(width: 26, height: 26)
                            .background(Color.pink.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.comment)
                                .font(.caption.weight(.semibold))
                            Text(Self.shortDateFormatter.string(from: entry.date))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("+\(viewModel.formatCurrency(entry.amount))")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(18)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private func quickDepositButton(amount: Double, label: String) -> some View {
        Button {
            withAnimation(.spring(duration: 0.35)) {
                viewModel.depositToPiggyBank(
                    amount: amount,
                    comment: "Быстрое пополнение (\(label))"
                )
            }
        } label: {
            Text(label)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Color(uiColor: .tertiarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 2. Блок «Круговая диаграмма Доходы / Расходы за месяц» (Swift Charts SectorMark)

    private var monthlyDonutChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Доходы / Расходы за месяц", systemImage: "chart.pie.fill")
                        .font(.headline)
                    Text("Аналитика денежного потока и баланса")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Picker("Режим диаграммы", selection: $chartMode) {
                ForEach(ChartDisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            // Swift Charts SectorMark with innerRadius: .ratio(0.62)
            ZStack {
                Chart(activeSlices) { slice in
                    SectorMark(
                        angle: .value("Сумма", slice.amount),
                        innerRadius: .ratio(0.62),
                        angularInset: 2.0
                    )
                    .cornerRadius(6)
                    .foregroundStyle(slice.color)
                }
                .frame(height: 220)

                VStack(spacing: 4) {
                    Text("Чистый баланс")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text((viewModel.netMonthlyBalance >= 0 ? "+" : "") + viewModel.formatCurrency(viewModel.netMonthlyBalance))
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.netMonthlyBalance >= 0 ? .green : .red)

                    Text("Норма сбережений \(viewModel.savingsRatePercent)%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Summary KPI Cards: Total Income / Total Expense / Net Balance
            HStack(spacing: 10) {
                financeMetricBox(
                    title: "Доходы",
                    amount: viewModel.totalMonthlyIncome,
                    color: .green,
                    icon: "arrow.down.left.circle.fill"
                )
                financeMetricBox(
                    title: "Расходы",
                    amount: viewModel.totalMonthlyExpense,
                    color: .red,
                    icon: "arrow.up.right.circle.fill"
                )
            }

            // Legend with Percentages and Amounts
            VStack(alignment: .leading, spacing: 8) {
                Text("Легенда и распределение")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(activeSlices) { slice in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 10, height: 10)

                        Text(slice.label)
                            .font(.subheadline)
                            .lineLimit(1)

                        Spacer()

                        Text("\(Int(slice.percentage.rounded()))%")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 42, alignment: .trailing)

                        Text(viewModel.formatCurrency(slice.amount))
                            .font(.subheadline.bold().monospacedDigit())
                            .frame(minWidth: 95, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(18)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private func financeMetricBox(
        title: String,
        amount: Double,
        color: Color,
        icon: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.formatCurrency(amount))
                    .font(.subheadline.bold())
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            Color(uiColor: .tertiarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    // MARK: - 3. Список операций за месяц + Добавление дохода/расхода

    private var transactionsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Операции за месяц", systemImage: "list.bullet.rectangle.portrait")
                    .font(.headline)

                Spacer()

                Button {
                    showAddTransactionSheet = true
                } label: {
                    Label("Добавить", systemImage: "plus.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.indigo)
                }
            }

            ForEach(viewModel.transactions) { tx in
                HStack(spacing: 12) {
                    Image(systemName: tx.category.icon)
                        .font(.subheadline.bold())
                        .foregroundStyle(tx.category.color)
                        .frame(width: 38, height: 38)
                        .background(
                            tx.category.color.opacity(0.14),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(tx.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(tx.category.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(Self.shortDateFormatter.string(from: tx.date))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Text("\(tx.type.symbol)\(viewModel.formatCurrency(tx.amount))")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(tx.type.color)
                }
                .padding(13)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
        }
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM"
        return formatter
    }()
}

// MARK: - Sheet: Custom Piggy Bank Deposit ("Своя сумма")

private struct CustomPiggyDepositSheet: View {
    @Bindable var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var amountString: String = ""
    @State private var comment: String = "Пополнение копилки"

    var body: some View {
        NavigationStack {
            Form {
                Section("Цель: \(viewModel.piggyBank.title)") {
                    HStack {
                        Text("Уже накоплено")
                        Spacer()
                        Text(viewModel.formatCurrency(viewModel.piggyBank.savedAmount))
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Осталось накопить")
                        Spacer()
                        Text(viewModel.formatCurrency(viewModel.piggyBank.remainingAmount))
                            .font(.headline)
                            .foregroundStyle(.pink)
                    }
                }

                Section("Пополнение") {
                    TextField("Сумма в рублях (например, 15000)", text: $amountString)
                        .keyboardType(.numberPad)
                    TextField("Комментарий", text: $comment)
                }
            }
            .navigationTitle("Своя сумма")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Пополнить") {
                        let cleaned = amountString.replacingOccurrences(of: " ", with: "")
                        if let value = Double(cleaned), value > 0 {
                            viewModel.depositToPiggyBank(amount: value, comment: comment)
                            dismiss()
                        }
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Sheet: Edit Piggy Bank Goal

private struct EditPiggyGoalSheet: View {
    @Bindable var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var targetAmountString: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Параметры цели накопления") {
                    TextField("На что коплю", text: $title)
                    TextField("Описание", text: $subtitle)
                    TextField("Целевая сумма (₽)", text: $targetAmountString)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Настройка копилки")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                title = viewModel.piggyBank.title
                subtitle = viewModel.piggyBank.subtitle
                targetAmountString = "\(Int(viewModel.piggyBank.targetAmount))"
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        if let target = Double(targetAmountString.replacingOccurrences(of: " ", with: "")),
                           target > 0 {
                            viewModel.updatePiggyBankGoal(
                                title: title,
                                subtitle: subtitle,
                                targetAmount: target
                            )
                            dismiss()
                        }
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Sheet: Add Income / Expense Transaction

private struct AddFinanceTransactionSheet: View {
    @Bindable var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var type: TransactionType = .expense
    @State private var category: FinanceCategory = .groceries

    var body: some View {
        NavigationStack {
            Form {
                Section("Тип операции") {
                    Picker("Тип", selection: $type) {
                        ForEach(TransactionType.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Детали") {
                    TextField("Название (например, Супермаркет или Фриланс)", text: $title)
                    TextField("Сумма (₽)", text: $amountText)
                        .keyboardType(.numberPad)

                    Picker("Категория", selection: $category) {
                        ForEach(FinanceCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("Новая операция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        let cleaned = amountText.replacingOccurrences(of: " ", with: "")
                        if let amount = Double(cleaned), amount > 0 {
                            viewModel.addTransaction(
                                title: title,
                                amount: amount,
                                type: type,
                                category: category
                            )
                            dismiss()
                        }
                    }
                    .bold()
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amountText.isEmpty)
                }
            }
        }
    }
}

#Preview("Мои финансы (Копилка + Swift Charts)") {
    NavigationStack {
        FinanceDashboardView(viewModel: DashboardViewModel())
    }
}
