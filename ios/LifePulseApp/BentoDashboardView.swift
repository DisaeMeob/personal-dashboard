import SwiftUI
import Charts

struct BentoDashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    @State private var showQuickDepositSheet = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerHeroCard

                // Row 1: Schedule Bento Card (Full Width)
                scheduleBentoCard

                // Row 2: 2x1 Bento Grid — Focus Timer + Daily Goals Ring
                LazyVGrid(columns: gridColumns, spacing: 14) {
                    focusBentoCard
                    dailyGoalsBentoCard
                }

                // Row 3: Piggy Bank ("Моя копилка") Bento Card
                piggyBankBentoCard

                // Row 4: Monthly Income / Expenses Donut Chart Bento Card
                financeDonutBentoCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("LifePulse")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showQuickDepositSheet) {
            QuickPiggyDepositSheet(viewModel: viewModel)
                .presentationDetents([.height(340)])
        }
    }

    // MARK: - 1. Greeting, Today's Date & Daily Summary

    private var headerHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.formattedTodayDate)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .textCase(.uppercase)

                    Text("\(viewModel.greetingTitle) 👋")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(viewModel.maxGoalStreak) дн.")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.white.opacity(0.18), in: Capsule())
            }

            Text("Сводка дня: выполнено \(viewModel.completedGoalsCount) из \(viewModel.dailyGoals.count) целей, \(viewModel.completedPomodorosToday) сессии Помодоро и накоплено \(viewModel.piggyBank.progressPercent)% в копилке.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                summaryChip(
                    icon: "calendar",
                    title: "\(viewModel.completedScheduleCount)/\(viewModel.scheduleItems.count) дел"
                )
                summaryChip(
                    icon: "timer",
                    title: "\(viewModel.completedPomodorosToday) фокуса"
                )
                summaryChip(
                    icon: "rublesign.circle",
                    title: "+\(viewModel.formatCurrency(viewModel.netMonthlyBalance))"
                )
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.indigo, Color.purple.opacity(0.88), Color.blue.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: .indigo.opacity(0.22), radius: 12, x: 0, y: 6)
    }

    private func summaryChip(icon: String, title: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.bold())
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.16), in: Capsule())
    }

    // MARK: - 2. Bento Card: "Сейчас в расписании" (Next 2 Events)

    private var scheduleBentoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Сейчас в расписании", systemImage: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    viewModel.selectedTab = .schedule
                } label: {
                    HStack(spacing: 4) {
                        Text("Все (\(viewModel.scheduleItems.count))")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
                }
            }

            ForEach(viewModel.upcomingScheduleItems) { item in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.startTime)
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(item.category.color)
                        Text(item.endTime)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 44, alignment: .leading)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(item.category.color)
                        .frame(width: 4, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .strikethrough(item.isCompleted)
                            .lineLimit(1)
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        withAnimation(.snappy) {
                            viewModel.toggleScheduleItem(item)
                        }
                    } label: {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(item.isCompleted ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(
                    Color(uiColor: .tertiarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }

    // MARK: - 3. Bento Card: "Фокус на задаче" (Active Task + Quick 25:00 Timer)

    private var focusBentoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "scope")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                Text("Фокус")
                    .font(.subheadline.bold())
                Spacer()
                Text(viewModel.formattedTimer)
                    .font(.caption.bold().monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.15), in: Capsule())
                    .foregroundStyle(.orange)
            }

            if let task = viewModel.activeFocusTask {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Image(systemName: task.priority.badgeIcon)
                            .font(.caption2)
                        Text("\(task.priority.rawValue) • \(task.completedPomodoros)/\(task.estimatedPomodoros) 🍅")
                            .font(.caption2)
                    }
                    .foregroundStyle(task.priority.color)
                }
            } else {
                Text("Все задачи выполнены")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.toggleTimer()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: viewModel.isTimerRunning ? "pause.fill" : "play.fill")
                        Text(viewModel.isTimerRunning ? "Пауза" : "Старт 25:00")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        viewModel.isTimerRunning ? Color.red : Color.orange,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .buttonStyle(.plain)

                if viewModel.remainingFocusSeconds != viewModel.defaultFocusDuration {
                    Button {
                        withAnimation {
                            viewModel.resetTimer()
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption.bold())
                            .padding(9)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 195, alignment: .topLeading)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }

    // MARK: - 4. Bento Card: "Цели на день" (Ring Progress + Checkboxes)

    private var dailyGoalsBentoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Цели на день")
                        .font(.subheadline.bold())
                    Text("\(viewModel.completedGoalsCount) из \(viewModel.dailyGoals.count) готово")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.teal.opacity(0.18), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: viewModel.goalsProgress)
                        .stroke(
                            AngularGradient(
                                colors: [.teal, .mint, .green],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text("\(Int((viewModel.goalsProgress * 100).rounded()))%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .frame(width: 38, height: 38)
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(viewModel.dailyGoals.prefix(3)) { goal in
                    Button {
                        withAnimation(.snappy) {
                            viewModel.toggleDailyGoal(goal)
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: goal.isCompleted ? "checkmark.square.fill" : "square")
                                .font(.subheadline)
                                .foregroundStyle(goal.isCompleted ? .teal : .secondary)

                            Text(goal.title)
                                .font(.caption)
                                .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                                .strikethrough(goal.isCompleted)
                                .lineLimit(1)

                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 2)

            Button {
                viewModel.selectedTab = .focusAndGoals
            } label: {
                HStack(spacing: 4) {
                    Text("Открыть все цели")
                    Image(systemName: "arrow.up.right")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.teal)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 195, alignment: .topLeading)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }

    // MARK: - 5. Bento Card: "Моя копилка" (Goal, Saved, Remaining Amount, Progress & Quick Deposit)

    private var piggyBankBentoCard: some View {
        let piggy = viewModel.piggyBank

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    Image(systemName: piggy.icon)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            LinearGradient(
                                colors: [.pink, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Моя копилка")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(piggy.title)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button {
                    showQuickDepositSheet = true
                } label: {
                    Label("Пополнить", systemImage: "plus")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.pink.opacity(0.14), in: Capsule())
                        .foregroundStyle(.pink)
                }
                .buttonStyle(.plain)
            }

            // Key Metrics: Already Saved vs Remaining to Save ("Сколько осталось накопить")
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Уже накоплено")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(viewModel.formatCurrency(piggy.savedAmount))
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text("из \(viewModel.formatCurrency(piggy.targetAmount))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(
                    Color(uiColor: .tertiarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Осталось накопить")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.pink)
                    Text(viewModel.formatCurrency(piggy.remainingAmount))
                        .font(.subheadline.bold())
                        .foregroundStyle(.pink)
                    Text("Выполнено \(piggy.progressPercent)%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(
                    Color.pink.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.pink.opacity(0.16))
                            .frame(height: 10)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.pink, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(12, proxy.size.width * piggy.progress), height: 10)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("Срок цели: \(piggy.deadlineText)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Быстро +5 000 ₽") {
                        withAnimation(.spring(duration: 0.35)) {
                            viewModel.depositToPiggyBank(amount: 5_000, comment: "С главного экрана (+5 000 ₽)")
                        }
                    }
                    .font(.caption2.bold())
                    .foregroundStyle(.pink)
                }
            }
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }

    // MARK: - 6. Bento Card: "Доходы / Расходы за месяц" with Swift Charts SectorMark

    private var financeDonutBentoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Доходы / Расходы за месяц", systemImage: "chart.pie.fill")
                    .font(.headline)

                Spacer()

                Button {
                    viewModel.selectedTab = .finance
                } label: {
                    HStack(spacing: 4) {
                        Text("Подробнее")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
                }
            }

            HStack(spacing: 16) {
                Chart(viewModel.incomeVsExpenseSlices) { slice in
                    SectorMark(
                        angle: .value("Сумма", slice.amount),
                        innerRadius: .ratio(0.62),
                        angularInset: 2.0
                    )
                    .cornerRadius(5)
                    .foregroundStyle(slice.color)
                }
                .frame(width: 110, height: 110)
                .overlay {
                    VStack(spacing: 1) {
                        Text("Норма")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.savingsRatePercent)%")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.incomeVsExpenseSlices) { slice in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(slice.color)
                                .frame(width: 9, height: 9)

                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(slice.label) (\(Int(slice.percentage.rounded()))%)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(viewModel.formatCurrency(slice.amount))
                                    .font(.subheadline.bold())
                            }
                        }
                    }

                    Divider()

                    HStack {
                        Text("Чистый баланс:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("+\(viewModel.formatCurrency(viewModel.netMonthlyBalance))")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }
}

// MARK: - Quick Deposit Modal Sheet

private struct QuickPiggyDepositSheet: View {
    @Bindable var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var customAmountText: String = "5000"
    @State private var commentText: String = "Пополнение копилки"

    var body: some View {
        NavigationStack {
            Form {
                Section("На что коплю: \(viewModel.piggyBank.title)") {
                    HStack {
                        Text("Осталось накопить")
                        Spacer()
                        Text(viewModel.formatCurrency(viewModel.piggyBank.remainingAmount))
                            .font(.headline)
                            .foregroundStyle(.pink)
                    }

                    TextField("Сумма пополнения (₽)", text: $customAmountText)
                        .keyboardType(.numberPad)

                    TextField("Комментарий", text: $commentText)
                }

                Section("Быстрый выбор") {
                    HStack(spacing: 8) {
                        ForEach([1_000, 5_000, 10_000], id: \.self) { preset in
                            Button("+\(preset / 1000) тыс. ₽") {
                                customAmountText = "\(preset)"
                            }
                            .buttonStyle(.bordered)
                            .tint(.pink)
                        }
                    }
                }
            }
            .navigationTitle("Пополнить копилку")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Внести") {
                        if let value = Double(customAmountText.replacingOccurrences(of: " ", with: "")),
                           value > 0 {
                            viewModel.depositToPiggyBank(amount: value, comment: commentText)
                            dismiss()
                        }
                    }
                    .bold()
                }
            }
        }
    }
}

#Preview("Bento Dashboard (iOS 18)") {
    NavigationStack {
        BentoDashboardView(viewModel: DashboardViewModel())
    }
}
