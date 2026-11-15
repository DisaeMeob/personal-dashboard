import SwiftUI

enum AppThemePreference: String, CaseIterable, Identifiable {
    case system = "Системная"
    case light = "Светлая"
    case dark = "Тёмная"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }
}

@main
struct LifePulseApp: App {
    @State private var viewModel = DashboardViewModel()
    @AppStorage("lifepulse.theme.preference") private var themeRawValue: String = AppThemePreference.system.rawValue

    private var currentTheme: AppThemePreference {
        AppThemePreference(rawValue: themeRawValue) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            LifePulseRootTabView(
                viewModel: viewModel,
                themeRawValue: $themeRawValue
            )
            .preferredColorScheme(currentTheme.colorScheme)
        }
    }
}

struct LifePulseRootTabView: View {
    @Bindable var viewModel: DashboardViewModel
    @Binding var themeRawValue: String

    private var selectedTheme: AppThemePreference {
        AppThemePreference(rawValue: themeRawValue) ?? .system
    }

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            NavigationStack {
                BentoDashboardView(viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            themeMenuButton
                        }
                    }
            }
            .tabItem {
                Label("Дашборд", systemImage: "square.grid.2x2.fill")
            }
            .tag(DashboardViewModel.AppTab.dashboard)

            NavigationStack {
                ScheduleTimelineView(viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            themeMenuButton
                        }
                    }
            }
            .tabItem {
                Label("Расписание", systemImage: "calendar.day.timeline.left")
            }
            .tag(DashboardViewModel.AppTab.schedule)

            NavigationStack {
                FocusAndGoalsView(viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            themeMenuButton
                        }
                    }
            }
            .tabItem {
                Label("Фокус & Цели", systemImage: "target")
            }
            .tag(DashboardViewModel.AppTab.focusAndGoals)

            NavigationStack {
                FinanceDashboardView(viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            themeMenuButton
                        }
                    }
            }
            .tabItem {
                Label("Финансы", systemImage: "chart.pie.fill")
            }
            .tag(DashboardViewModel.AppTab.finance)
        }
        .tint(.indigo)
    }

    private var themeMenuButton: some View {
        Menu {
            Picker("Тема оформления", selection: $themeRawValue) {
                ForEach(AppThemePreference.allCases) { theme in
                    Label(theme.rawValue, systemImage: theme.icon)
                        .tag(theme.rawValue)
                }
            }
        } label: {
            Image(systemName: selectedTheme.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel("Тема оформления")
    }
}

#Preview("LifePulse App Tabs") {
    LifePulseRootTabView(
        viewModel: DashboardViewModel(),
        themeRawValue: .constant(AppThemePreference.system.rawValue)
    )
}
