import SwiftUI

struct ScheduleTimelineView: View {
    @Bindable var viewModel: DashboardViewModel
    @State private var selectedCategoryFilter: ScheduleCategory? = nil
    @State private var showAddEventSheet = false

    private var filteredItems: [ScheduleItem] {
        let sorted = viewModel.sortedSchedule
        guard let category = selectedCategoryFilter else {
            return sorted
        }
        return sorted.filter { $0.category == category }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                scheduleOverviewBanner
                categoryFilterStrip
                timelineListSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Моё расписание")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showAddEventSheet = true
                } label: {
                    Label("Добавить событие", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .sheet(isPresented: $showAddEventSheet) {
            AddScheduleEventSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Top Banner

    private var scheduleOverviewBanner: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.formattedTodayDate)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text("Запланировано \(viewModel.scheduleItems.count) событий")
                    .font(.headline)

                Text("Выполнено: \(viewModel.completedScheduleCount) из \(viewModel.scheduleItems.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showAddEventSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Новое")
                }
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.indigo, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    // MARK: - Category Filter Strip

    private var categoryFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(
                    title: "Все",
                    icon: "square.grid.2x2",
                    color: .indigo,
                    isSelected: selectedCategoryFilter == nil
                ) {
                    withAnimation(.snappy) {
                        selectedCategoryFilter = nil
                    }
                }

                ForEach(ScheduleCategory.allCases) { category in
                    filterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategoryFilter == category
                    ) {
                        withAnimation(.snappy) {
                            selectedCategoryFilter = category
                        }
                    }
                }
            }
        }
    }

    private func filterChip(
        title: String,
        icon: String,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(
                isSelected ? color : Color(uiColor: .secondarySystemGroupedBackground),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timeline Rows

    private var timelineListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                HStack(alignment: .top, spacing: 14) {
                    // Left Time Column
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.startTime)
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(item.isCompleted ? .secondary : .primary)
                        Text(item.endTime)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 52, alignment: .trailing)
                    .padding(.top, 6)

                    // Vertical Timeline Connector
                    VStack(spacing: 0) {
                        Circle()
                            .fill(item.isCompleted ? Color.green : item.category.color)
                            .frame(width: 12, height: 12)
                            .overlay {
                                Circle()
                                    .stroke(Color(uiColor: .systemGroupedBackground), lineWidth: 2)
                            }
                            .padding(.top, 9)

                        if index < filteredItems.count - 1 {
                            Rectangle()
                                .fill(item.category.color.opacity(0.28))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }

                    // Event Card
                    scheduleEventCard(item)
                        .padding(.bottom, 14)
                }
            }
        }
    }

    private func scheduleEventCard(_ item: ScheduleItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Label(item.category.rawValue, systemImage: item.category.icon)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(item.category.color.opacity(0.15), in: Capsule())
                        .foregroundStyle(item.category.color)

                    Text("\(item.startTime) – \(item.endTime)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Text(item.title)
                    .font(.subheadline.bold())
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 4)

            Button {
                withAnimation(.snappy) {
                    viewModel.toggleScheduleItem(item)
                }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isCompleted ? "Отметить невыполненным" : "Отметить выполненным")
        }
        .padding(14)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(item.category.color.opacity(0.22), lineWidth: 1)
        )
    }
}

// MARK: - Modal Sheet for Adding a Schedule Event

private struct AddScheduleEventSheet: View {
    @Bindable var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var startTime: String = "15:00"
    @State private var endTime: String = "16:00"
    @State private var category: ScheduleCategory = .work

    var body: some View {
        NavigationStack {
            Form {
                Section("Детали события") {
                    TextField("Название (например, Код-ревью)", text: $title)
                    TextField("Описание / место", text: $subtitle)
                }

                Section("Время и категория") {
                    HStack {
                        Text("Начало")
                        Spacer()
                        TextField("09:00", text: $startTime)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                    }

                    HStack {
                        Text("Окончание")
                        Spacer()
                        TextField("10:00", text: $endTime)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                    }

                    Picker("Категория", selection: $category) {
                        ForEach(ScheduleCategory.allCases) { item in
                            Label(item.rawValue, systemImage: item.icon)
                                .tag(item)
                        }
                    }
                }
            }
            .navigationTitle("Новое событие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        viewModel.addScheduleItem(
                            title: title,
                            subtitle: subtitle,
                            startTime: startTime,
                            endTime: endTime,
                            category: category
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

#Preview("Моё расписание") {
    NavigationStack {
        ScheduleTimelineView(viewModel: DashboardViewModel())
    }
}
