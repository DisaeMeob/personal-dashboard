import SwiftUI

struct FocusAndGoalsView: View {
    @Bindable var viewModel: DashboardViewModel
    @State private var showAddTaskSheet = false
    @State private var showAddGoalSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                interactivePomodoroCard
                focusTasksSection
                dailyGoalsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 30)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Фокус & Цели")
        .sheet(isPresented: $showAddTaskSheet) {
            AddFocusTaskSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAddGoalSheet) {
            AddDailyGoalSheet(viewModel: viewModel)
                .presentationDetents([.height(310)])
        }
    }

    // MARK: - 1. Interactive 25-Minute Pomodoro Timer Ring

    private var interactivePomodoroCard: some View {
        VStack(spacing: 18) {
            HStack {
                Label("Таймер глубокого фокуса", systemImage: "timer")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("Сегодня: \(viewModel.completedPomodorosToday) 🍅")
                        .font(.caption.bold())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.orange.opacity(0.14), in: Capsule())
            }

            // Animated Time Ring
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.16), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: max(0.02, 1.0 - viewModel.timerProgress))
                    .stroke(
                        AngularGradient(
                            colors: [.orange, .red, .pink, .orange],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.35), value: viewModel.remainingFocusSeconds)

                VStack(spacing: 6) {
                    Text(viewModel.isTimerRunning ? "В ФОКУСЕ" : "ПОМОДОРО 25 МИН")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .tracking(1)

                    Text(viewModel.formattedTimer)
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText())

                    if let active = viewModel.activeFocusTask {
                        Text(active.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 24)
                    }
                }
            }
            .frame(width: 215, height: 215)
            .padding(.vertical, 4)

            // Controls: Start / Pause / Reset / Complete Session
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.toggleTimer()
                    }
                } label: {
                    Label(
                        viewModel.isTimerRunning ? "Пауза" : "Старт",
                        systemImage: viewModel.isTimerRunning ? "pause.fill" : "play.fill"
                    )
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        viewModel.isTimerRunning ? Color.red : Color.orange,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.snappy) {
                        viewModel.resetTimer()
                    }
                } label: {
                    Label("Сброс", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(
                            Color(uiColor: .tertiarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.spring(duration: 0.35)) {
                        viewModel.completePomodoroSession()
                    }
                } label: {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .padding(12)
                        .background(
                            Color.green.opacity(0.14),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Завершить сессию Помодоро")
            }
        }
        .padding(18)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    // MARK: - 2. Tasks List with Priorities & "Взять в фокус"

    private var focusTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Задачи для фокуса", systemImage: "checklist")
                    .font(.headline)

                Spacer()

                Button {
                    showAddTaskSheet = true
                } label: {
                    Label("Добавить", systemImage: "plus.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.indigo)
                }
            }

            ForEach(viewModel.focusTasks) { task in
                let isCurrentFocus = viewModel.activeFocusTask?.id == task.id

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        Button {
                            withAnimation(.snappy) {
                                viewModel.toggleTaskCompletion(task)
                            }
                        } label: {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(task.isCompleted ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Label(task.priority.rawValue, systemImage: task.priority.badgeIcon)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(task.priority.color.opacity(0.14), in: Capsule())
                                    .foregroundStyle(task.priority.color)

                                Text("\(task.completedPomodoros)/\(task.estimatedPomodoros) 🍅")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)

                                if isCurrentFocus {
                                    Text("Активна")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.18), in: Capsule())
                                        .foregroundStyle(.orange)
                                }
                            }

                            Text(task.title)
                                .font(.subheadline.bold())
                                .strikethrough(task.isCompleted)
                                .foregroundStyle(task.isCompleted ? .secondary : .primary)

                            if !task.note.isEmpty {
                                Text(task.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer(minLength: 0)
                    }

                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.snappy) {
                                viewModel.selectTaskForFocus(task)
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: isCurrentFocus ? "scope" : "bolt.Horizontal.circle")
                                Text(isCurrentFocus ? "В фокусе сейчас" : "Взять в фокус")
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                isCurrentFocus ? Color.orange : Color.indigo.opacity(0.14),
                                in: Capsule()
                            )
                            .foregroundStyle(isCurrentFocus ? .white : .indigo)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            isCurrentFocus ? Color.orange.opacity(0.65) : Color.clear,
                            lineWidth: 1.5
                        )
                )
            }
        }
    }

    // MARK: - 3. "Цели на день" with Streak & Progress

    private var dailyGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Цели на день", systemImage: "sparkles")
                        .font(.headline)
                    Text("Рекорд серии: \(viewModel.maxGoalStreak) дней подряд 🔥")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showAddGoalSheet = true
                } label: {
                    Label("Новая цель", systemImage: "plus.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.teal)
                }
            }

            // Overall Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Прогресс дня")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text("\(viewModel.completedGoalsCount) из \(viewModel.dailyGoals.count) (\(Int((viewModel.goalsProgress * 100).rounded()))%)")
                        .font(.caption.bold())
                        .foregroundStyle(.teal)
                }

                ProgressView(value: viewModel.goalsProgress)
                    .tint(.teal)
            }
            .padding(14)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )

            ForEach(viewModel.dailyGoals) { goal in
                Button {
                    withAnimation(.snappy) {
                        viewModel.toggleDailyGoal(goal)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(goal.isCompleted ? .teal : .secondary)

                        Image(systemName: goal.icon)
                            .font(.subheadline)
                            .foregroundStyle(.teal)
                            .frame(width: 28, height: 28)
                            .background(Color.teal.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.title)
                                .font(.subheadline.weight(.semibold))
                                .strikethrough(goal.isCompleted)
                                .foregroundStyle(goal.isCompleted ? .secondary : .primary)

                            Text("Цель: \(goal.targetLabel)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text("\(goal.streakDays) дн.")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Color(uiColor: .tertiarySystemGroupedBackground),
                            in: Capsule()
                        )
                    }
                    .padding(13)
                    .background(
                        Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Sheet: Add Focus Task

private struct AddFocusTaskSheet: View {
    @Bindable var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var note: String = ""
    @State private var priority: TaskPriority = .high
    @State private var estimatedPomodoros: Int = 2

    var body: some View {
        NavigationStack {
            Form {
                Section("Задача") {
                    TextField("Название задачи", text: $title)
                    TextField("Заметка / критерий готовности", text: $note)
                }

                Section("Приоритет и оценка") {
                    Picker("Приоритет", selection: $priority) {
                        ForEach(TaskPriority.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)

                    Stepper("Сессий Помодоро: \(estimatedPomodoros) 🍅", value: $estimatedPomodoros, in: 1...10)
                }
            }
            .navigationTitle("Новая задача")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        viewModel.addFocusTask(
                            title: title,
                            note: note,
                            priority: priority,
                            estimatedPomodoros: estimatedPomodoros
                        )
                        dismiss()
                    }
                    .bold()
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Sheet: Add Daily Goal

private struct AddDailyGoalSheet: View {
    @Bindable var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var targetLabel: String = "Ежедневно"

    var body: some View {
        NavigationStack {
            Form {
                Section("Привычка или цель на день") {
                    TextField("Например: Зарядка 15 минут", text: $title)
                    TextField("Норма (например: 15 мин)", text: $targetLabel)
                }
            }
            .navigationTitle("Новая цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        viewModel.addDailyGoal(title: title, targetLabel: targetLabel)
                        dismiss()
                    }
                    .bold()
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview("Фокус & Цели") {
    NavigationStack {
        FocusAndGoalsView(viewModel: DashboardViewModel())
    }
}
