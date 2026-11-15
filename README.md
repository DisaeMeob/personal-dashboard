# LifePulse — Minimalist iOS Personal Dashboard & WidgetKit Suite

![Swift 6.0](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)
![Platform iOS 17+](https://img.shields.io/badge/Platform-iOS%2017%2B%20%7C%20iPhone%2015%20Pro-000000?logo=apple&logoColor=white)
![SwiftUI & WidgetKit](https://img.shields.io/badge/UI-SwiftUI%20%2B%20WidgetKit%20%2B%20Swift%20Charts-0A84FF)
![Offline PWA](https://img.shields.io/badge/PWA-Offline--First%20Service%20Worker-38B27A)

**LifePulse** — минималистичный персональный дашборд для iOS (в эстетике *Things 3* и *Linear*), объединяющий расписание дня, фокус-таймер Помодоро, ежедневные цели и личные финансы с локальным хранением данных на устройстве (`Local-First`).

Проект включает:
1. **`LifePulseCore` (Swift Package)** — типизированное ядро доменной логики, финансовых расчетов и потокобезопасное локальное хранилище (`AppGroup` + JSON).
2. **`LifePulseApp` & `LifePulseWidget` (SwiftUI + WidgetKit + Swift Charts)** — нативное приложение и расширение виджетов для домашнего экрана iOS (`systemSmall`, `systemMedium`, `systemLarge`).
3. **`preview/` (Modular Offline-First iOS Web App / PWA)** — модульное веб-приложение с поддержкой автономной работы (`Service Worker`) и установки на домашний экран **iPhone 15 Pro** без Xcode.

---

## Ключевые возможности

- **Моё расписание (`Schedule`)** — таймлайн событий дня с категориями, временными слотами и отметкой выполнения.
- **Фокус на задачах (`Focus & Pomodoro`)** — выбор главной задачи фокуса, встроенный таймер (`25 / 15 / 5 мин`) и управление приоритетами.
- **Цели на день (`Daily Goals`)** — чек-лист ежедневных привычек с индикатором прогресса и серией дней (`streak`).
- **Мои финансы (`Savings & Monthly Donut Chart`)**:
  - **Копилка («На что я коплю»)**: отслеживание целей накопления, мгновенный расчет суммы **«Осталось накопить»**, пополнение в один клик, отмена ошибочных операций, удаление и завершение достигнутых целей (`100%`).
  - **Круговая диаграмма (`Donut Chart`)**: визуализация соотношения **Доходов и Расходов за месяц** и чистого остатка.
- **Виджеты для телефона (`iOS Widgets`)** — виджеты малого, среднего и большого размера для рабочего стола iPhone.

---

## Структура репозитория

```text
.
├── .github/workflows/
│   └── deploy-pages.yml                   # Автодеплой PWA-версии на GitHub Pages
├── Package.swift                          # Манифест Swift Package Manager (Swift 6)
├── Sources/LifePulseCore/
│   ├── Models.swift                       # Доменные модели, расчёт Копилки и баланса месяца
│   └── LocalDashboardStore.swift          # Потокобезопасное локальное хранилище (AppGroup + JSON)
├── Tests/LifePulseCoreTests/
│   └── LifePulseCoreTests.swift           # Unit-тесты ядра и финансовых расчётов
├── ios/
│   ├── project.yml                        # Конфигурация XcodeGen (App + WidgetKit Extension)
│   ├── LifePulseApp/
│   │   ├── LifePulseApp.swift             # Точка входа @main и TabView-навигация
│   │   ├── DashboardViewModel.swift       # Реактивная @Observable ViewModel
│   │   ├── BentoDashboardView.swift       # Главный экран обзора дня
│   │   ├── ScheduleTimelineView.swift     # Экран расписания
│   │   ├── FocusAndGoalsView.swift        # Экран таймера Помодоро, задач и целей дня
│   │   └── FinanceDashboardView.swift     # Экран Копилки и круговой диаграммы (Swift Charts)
│   └── LifePulseWidget/
│       └── LifePulseWidgets.swift         # Виджеты WidgetKit (Small, Medium, Large)
└── preview/                               # Модульное автономное PWA-приложение (iPhone 15 Pro)
    ├── index.html                         # HTML-оболочка и iOS PWA мета-теги
    ├── manifest.json                      # Web App Manifest
    ├── sw.js                              # Offline-First Service Worker
    ├── assets/icon.svg                    # Иконка приложения для рабочего стола iOS
    ├── css/
    │   ├── theme.css                      # Дизайн-токены и минималистичная палитра (Dark / Light)
    │   ├── layout.css                     # Адаптивный каркас iPhone 15 Pro и полноэкранный режим
    │   └── components.css                 # Стили карточек, списков, форм и виджетов
    └── js/
        ├── store.js                       # LocalStorage-хранилище и селекторы данных
        ├── charts.js                      # Генератор SVG круговой диаграммы (Donut Chart)
        ├── views.js                       # Компоненты экранов и превью виджетов iOS
        └── app.js                         # Контроллер приложения и таймер фокуса
```

---

## Быстрый старт

### 1. Запуск интерактивной версии / Установка на iPhone (PWA)

Приложение автоматически публикуется через **GitHub Pages** при пуше в ветку `main` / `master` (благодаря `.github/workflows/deploy-pages.yml`).

Для локального запуска на Mac:
```bash
python3 -m http.server 8080 --directory preview
# Откройте http://localhost:8080
```

Для установки на **iPhone 15 Pro** без компьютера:
1. Откройте ссылку GitHub Pages (**https://disaemeob.github.io/personal-dashboard/**) в **Safari** на iPhone.
2. Нажмите **«Поделиться»** → **«На экран „Домой“» (Add to Home Screen)**.
3. Все файлы кэшируются через `sw.js`, а данные сохраняются локально на устройстве — приложение работает полностью офлайн.

### 2. Сборка и тестирование Swift-ядра

```bash
swift build
swift test
```

### 3. Сборка нативного iOS-приложения и виджетов в Xcode

```bash
brew install xcodegen
cd ios && xcodegen generate
open LifePulse.xcodeproj
```
Выберите таргет `LifePulseApp`, укажите ваш Apple ID в *Signing & Capabilities* и запустите на симуляторе или реальном iPhone (`⌘R`).
