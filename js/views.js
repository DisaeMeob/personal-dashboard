/* ==========================================================================
   LifePulse — js/views.js
   Minimalist, Eye-Friendly Views for Overview, Schedule, Focus, Finance & Widgets
   ========================================================================== */

(function (global) {
  'use strict';

  function renderHeader(title, subtitle) {
    const state = global.LP.store.getState();
    const isDark = state.theme === 'dark';
    return `
      <div class="page-header">
        <div>
          <div class="page-date">${subtitle}</div>
          <h1 class="page-title">${title}</h1>
        </div>
        <div class="header-actions">
          <button class="icon-btn" onclick="LP.app.toggleDisplayMode()" title="Виджеты iOS">
            ${state.displayMode === 'widgets' ? '📱' : '🧩'}
          </button>
          <button class="icon-btn" onclick="LP.app.toggleTheme()" title="Сменить тему">
            ${isDark ? '☀️' : '🌙'}
          </button>
        </div>
      </div>
    `;
  }

  /* ------------------------------------------------------------------------
     1. OVERVIEW TAB (Calm, Focused Summary)
     ------------------------------------------------------------------------ */
  function renderOverviewTab() {
    const store = global.LP.store;
    const charts = global.LP.charts;
    const state = store.getState();
    const focus = store.getActiveFocusTask();
    const goals = store.getGoalsProgress();
    const sg = store.getActiveSavingsGoal();
    const fin = store.getFinanceTotals();
    const nextSchedule = state.schedule.filter(s => !s.done).slice(0, 2);

    return `
      ${renderHeader('Сегодня', 'Суббота, 14 ноября')}

      <!-- 1. Фокус сейчас -->
      <div class="card">
        <div class="card-head">
          <span class="card-label">Фокус на задаче</span>
          <button class="card-link" onclick="LP.app.switchTab('focus')">Все задачи →</button>
        </div>
        <div style="display:flex;align-items:center;justify-content:space-between;gap:12px;">
          <div style="min-width:0;flex:1;">
            <div style="font-size:15px;font-weight:600;color:var(--text-main);margin-bottom:4px;">
              ${focus ? store.escapeHtml(focus.title) : 'Все задачи выполнены'}
            </div>
            <div class="item-meta">Таймер: <span id="pomoLiveReadout">${store.formatTimer(state.pomodoro.secondsLeft)}</span></div>
          </div>
          <button class="btn-primary" onclick="LP.app.togglePomodoro()">
            ${state.pomodoro.isRunning ? 'Пауза' : 'Старт'}
          </button>
        </div>
      </div>

      <!-- 2. Цели на день -->
      <div class="card">
        <div class="card-head">
          <span class="card-label">Цели на день</span>
          <span class="item-meta">${goals.done} из ${goals.total}</span>
        </div>
        <div class="progress-track" style="margin-top:4px;margin-bottom:12px;">
          <div class="progress-fill green" style="width:${goals.pct}%;"></div>
        </div>
        <div class="item-list">
          ${state.dailyGoals.slice(0, 3).map(g => `
            <div class="item-row" onclick="LP.app.toggleDailyGoal('${g.id}')" style="cursor:pointer;">
              <div class="item-left">
                <span class="check-circle ${g.done ? 'done' : ''}">✓</span>
                <span class="item-title ${g.done ? 'done' : ''}">${store.escapeHtml(g.title)}</span>
              </div>
            </div>
          `).join('')}
        </div>
      </div>

      <!-- 3. Моё расписание (ближайшее) -->
      <div class="card">
        <div class="card-head">
          <span class="card-label">Ближайшее в расписании</span>
          <button class="card-link" onclick="LP.app.switchTab('schedule')">Открыть →</button>
        </div>
        ${nextSchedule.length > 0 ? `
          <div class="item-list">
            ${nextSchedule.map(s => `
              <div class="item-row">
                <div class="item-left">
                  <span style="font-size:12px;font-weight:600;color:var(--accent);width:42px;flex-shrink:0;">${s.start}</span>
                  <span class="item-title">${store.escapeHtml(s.title)}</span>
                </div>
                <span class="item-meta">${s.category}</span>
              </div>
            `).join('')}
          </div>
        ` : `<div class="item-meta">На сегодня все дела из расписания завершены.</div>`}
      </div>

      <!-- 4. Копилка и Финансы (Кратко) -->
      <div class="card">
        <div class="card-head">
          <span class="card-label">Мои финансы</span>
          <button class="card-link" onclick="LP.app.switchTab('finance')">Подробнее →</button>
        </div>
        ${sg ? `
          <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px;">
            <span style="font-size:14px;font-weight:600;">${store.escapeHtml(sg.title)}</span>
            <span style="font-size:13px;color:var(--text-sec);">${sg.pctDone}%</span>
          </div>
          <div class="progress-track" style="margin:6px 0 8px;">
            <div class="progress-fill ${sg.isCompleted ? 'green' : ''}" style="width:${sg.pctDone}%;"></div>
          </div>
          <div style="display:flex;justify-content:space-between;align-items:center;font-size:12.5px;color:var(--text-sec);">
            <span>Накоплено: <strong style="color:var(--text-main);">${store.formatRub(sg.saved)}</strong></span>
            <span>${sg.isCompleted ? 'Цель достигнута ✓' : `Осталось: <strong style="color:var(--text-main);">${store.formatRub(sg.remainingAmount)}</strong>`}</span>
          </div>
          ${sg.isCompleted ? `
            <button class="btn-success" onclick="LP.app.completeSavingsGoal('${sg.id}')">
              ✓ Завершить и убрать цель
            </button>
          ` : ''}
        ` : `<div class="item-meta">Нет активных целей накопления.</div>`}

        <div style="border-top:1px solid var(--border);margin-top:14px;padding-top:12px;display:flex;align-items:center;justify-content:space-between;">
          <div>
            <div class="item-meta">Доходы / Расходы за месяц</div>
            <div style="font-size:14px;font-weight:600;margin-top:2px;">
              <span style="color:var(--green);">+${store.formatRub(fin.income)}</span>
              <span style="color:var(--text-muted);margin:0 4px;">/</span>
              <span style="color:var(--coral);">−${store.formatRub(fin.expense)}</span>
            </div>
          </div>
          ${charts.renderMiniRingSVG(fin.incomePct, 'var(--green)')}
        </div>
      </div>
    `;
  }

  /* ------------------------------------------------------------------------
     2. SCHEDULE TAB (Моё расписание)
     ------------------------------------------------------------------------ */
  function renderScheduleTab() {
    const store = global.LP.store;
    const state = store.getState();

    return `
      ${renderHeader('Расписание', 'План на день')}

      <div class="card">
        <div class="item-list">
          ${state.schedule.length > 0 ? state.schedule.map(s => `
            <div class="item-row">
              <div class="item-left" onclick="LP.app.toggleScheduleDone('${s.id}')" style="cursor:pointer;">
                <span class="check-circle ${s.done ? 'done' : ''}">✓</span>
                <div>
                  <div class="item-title ${s.done ? 'done' : ''}">${store.escapeHtml(s.title)}</div>
                  <div class="item-meta">${s.start} – ${s.end} · ${s.category}</div>
                </div>
              </div>
              <button class="del-btn" onclick="LP.app.deleteScheduleItem('${s.id}')" title="Удалить">✕</button>
            </div>
          `).join('') : `<div class="item-meta">Расписание пусто. Добавьте событие ниже.</div>`}
        </div>
      </div>

      <div class="card">
        <div class="card-head">
          <span class="card-label">Добавить событие</span>
        </div>
        <div class="inline-form">
          <input id="schedStart" type="time" value="18:00" class="input-field" style="max-width:96px;" />
          <input id="schedEnd" type="time" value="19:00" class="input-field" style="max-width:96px;" />
          <select id="schedCat" class="input-field">
            <option value="Работа">Работа</option>
            <option value="Спорт">Спорт</option>
            <option value="Личное">Личное</option>
            <option value="Учёба">Учёба</option>
          </select>
        </div>
        <div class="inline-form">
          <input id="schedTitle" type="text" placeholder="Название события..." class="input-field" />
          <button class="btn-primary" onclick="LP.app.addScheduleItem()">Добавить</button>
        </div>
      </div>
    `;
  }

  /* ------------------------------------------------------------------------
     3. FOCUS & GOALS TAB (Фокус на задачах + Цели на день)
     ------------------------------------------------------------------------ */
  function renderFocusTab() {
    const store = global.LP.store;
    const state = store.getState();
    const focus = store.getActiveFocusTask();
    const goals = store.getGoalsProgress();

    return `
      ${renderHeader('Фокус и Цели', 'Продуктивность')}

      <!-- Таймер фокуса -->
      <div class="card" style="text-align:center;padding:22px 18px;">
        <div class="item-meta" style="margin-bottom:6px;">Сейчас в фокусе</div>
        <div style="font-size:16px;font-weight:600;margin-bottom:14px;">
          ${focus ? store.escapeHtml(focus.title) : 'Выберите задачу ниже'}
        </div>
        <div id="pomoLiveReadout" style="font-size:40px;font-weight:700;letter-spacing:-0.03em;margin-bottom:14px;">
          ${store.formatTimer(state.pomodoro.secondsLeft)}
        </div>
        <div style="display:flex;justify-content:center;gap:8px;margin-bottom:12px;">
          <button class="btn-primary" onclick="LP.app.togglePomodoro()">
            ${state.pomodoro.isRunning ? 'Пауза' : 'Старт фокуса'}
          </button>
          <button class="btn-soft" onclick="LP.app.resetPomodoro()">Сброс</button>
        </div>
        <div style="display:inline-flex;gap:6px;">
          ${[25, 15, 5].map(m => `
            <button class="pill-tab ${state.pomodoro.presetMinutes === m ? 'active' : ''}" onclick="LP.app.setPomodoroPreset(${m})">${m} мин</button>
          `).join('')}
        </div>
      </div>

      <!-- Список задач -->
      <div class="card">
        <div class="card-head">
          <span class="card-label">Задачи</span>
        </div>
        <div class="item-list">
          ${state.tasks.map(t => {
            const isCurrent = focus && focus.id === t.id && !t.done;
            return `
              <div class="item-row">
                <div class="item-left" onclick="LP.app.toggleTaskDone('${t.id}')" style="cursor:pointer;">
                  <span class="check-circle ${t.done ? 'done' : ''}">✓</span>
                  <span class="item-title ${t.done ? 'done' : ''}">${store.escapeHtml(t.title)}</span>
                </div>
                <div class="item-right">
                  ${!t.done ? `
                    <button class="btn-soft" style="padding:4px 8px;font-size:11px;${isCurrent ? 'color:var(--accent);' : ''}" onclick="LP.app.selectFocusTask('${t.id}')">
                      ${isCurrent ? 'В фокусе' : 'Фокус'}
                    </button>
                  ` : ''}
                  <button class="del-btn" onclick="LP.app.deleteTask('${t.id}')" title="Удалить">✕</button>
                </div>
              </div>
            `;
          }).join('')}
        </div>
        <div class="inline-form">
          <input id="newTaskTitle" type="text" placeholder="Новая задача..." class="input-field" />
          <button class="btn-primary" onclick="LP.app.addTask()">+</button>
        </div>
      </div>

      <!-- Цели на день -->
      <div class="card">
        <div class="card-head">
          <span class="card-label">Цели на день</span>
          <span class="item-meta">Выполнено ${goals.done} из ${goals.total} (${goals.pct}%)</span>
        </div>
        <div class="progress-track" style="margin-top:4px;margin-bottom:12px;">
          <div class="progress-fill green" style="width:${goals.pct}%;"></div>
        </div>
        <div class="item-list">
          ${state.dailyGoals.map(g => `
            <div class="item-row">
              <div class="item-left" onclick="LP.app.toggleDailyGoal('${g.id}')" style="cursor:pointer;">
                <span class="check-circle ${g.done ? 'done' : ''}">✓</span>
                <span class="item-title ${g.done ? 'done' : ''}">${store.escapeHtml(g.title)}</span>
              </div>
              <button class="del-btn" onclick="LP.app.deleteDailyGoal('${g.id}')" title="Удалить">✕</button>
            </div>
          `).join('')}
        </div>
        <div class="inline-form">
          <input id="newGoalTitle" type="text" placeholder="Добавить цель на день..." class="input-field" />
          <button class="btn-primary" onclick="LP.app.addDailyGoal()">+</button>
        </div>
      </div>
    `;
  }

  /* ------------------------------------------------------------------------
     4. FINANCE TAB (Копилка с удалением/завершением + Круговая диаграмма)
     ------------------------------------------------------------------------ */
  function renderFinanceTab() {
    const store = global.LP.store;
    const charts = global.LP.charts;
    const state = store.getState();
    const sg = store.getActiveSavingsGoal();
    const fin = store.getFinanceTotals();

    return `
      ${renderHeader('Финансы', 'Копилка и баланс месяца')}

      <!-- 1. КОПИЛКА (На что я коплю) -->
      <div class="card">
        <div class="card-head">
          <span class="card-label">На что я коплю</span>
          ${sg ? `
            <button class="btn-danger-soft" onclick="LP.app.deleteSavingsGoal('${sg.id}')" title="Удалить эту цель">
              Удалить цель
            </button>
          ` : ''}
        </div>

        <!-- Переключатель целей -->
        ${state.savingsGoals.length > 0 ? `
          <div class="pill-tabs">
            ${state.savingsGoals.map(g => `
              <button class="pill-tab ${sg && sg.id === g.id ? 'active' : ''}" onclick="LP.app.selectSavingsGoal('${g.id}')">
                ${store.escapeHtml(g.title)}
              </button>
            `).join('')}
          </div>
        ` : ''}

        ${sg ? `
          <div style="display:flex;align-items:baseline;justify-content:space-between;margin-top:4px;">
            <div>
              <div class="item-meta">Накоплено</div>
              <div class="metric-big">${store.formatRub(sg.saved)}</div>
            </div>
            <div style="text-align:right;">
              <div class="item-meta">Цель</div>
              <div style="font-size:16px;font-weight:600;color:var(--text-sec);">${store.formatRub(sg.target)}</div>
            </div>
          </div>

          <div class="progress-track">
            <div class="progress-fill ${sg.isCompleted ? 'green' : ''}" style="width:${sg.pctDone}%;"></div>
          </div>

          <!-- Блок "Сколько осталось накопить" или "Цель достигнута" -->
          ${sg.isCompleted ? `
            <div class="remaining-box completed">
              <span style="font-size:13.5px;font-weight:600;">🎉 Цель полностью накоплена!</span>
              <span style="font-size:13px;font-weight:700;">100%</span>
            </div>
            <button class="btn-success" onclick="LP.app.completeSavingsGoal('${sg.id}')">
              ✓ Завершить и убрать цель из списка
            </button>
          ` : `
            <div class="remaining-box">
              <span style="font-size:13px;color:var(--text-sec);">Осталось накопить</span>
              <span style="font-size:15px;font-weight:700;color:var(--text-main);">
                ${store.formatRub(sg.remainingAmount)} <span style="font-weight:500;color:var(--text-sec);font-size:12px;">(${sg.pctRemaining}%)</span>
              </span>
            </div>

            <!-- Быстрое пополнение -->
            <div class="quick-amounts">
              <button class="btn-soft" onclick="LP.app.quickTopUp(1000)">+1 000 ₽</button>
              <button class="btn-soft" onclick="LP.app.quickTopUp(5000)">+5 000 ₽</button>
              <button class="btn-soft" onclick="LP.app.quickTopUp(10000)">+10 000 ₽</button>
            </div>

            <div class="inline-form">
              <input id="topUpAmount" type="number" placeholder="Сумма пополнения, ₽" class="input-field" />
              <button class="btn-primary" onclick="LP.app.customTopUp()">Пополнить</button>
            </div>
          `}

          <!-- История пополнений (с возможностью отменить ошибочное пополнение) -->
          ${sg.history && sg.history.length > 0 ? `
            <div style="margin-top:16px;padding-top:12px;border-top:1px solid var(--border);">
              <div class="item-meta" style="margin-bottom:6px;">Последние пополнения</div>
              <div class="item-list">
                ${sg.history.slice(0, 4).map(h => `
                  <div class="item-row" style="padding:7px 0;">
                    <div class="item-left">
                      <span style="font-size:13px;font-weight:600;color:var(--green);">+${store.formatRub(h.amount)}</span>
                      <span class="item-meta">${store.escapeHtml(h.comment || 'Пополнение')} · ${h.date}</span>
                    </div>
                    <button class="del-btn" onclick="LP.app.deleteContribution('${sg.id}', '${h.id}')" title="Отменить пополнение">✕</button>
                  </div>
                `).join('')}
              </div>
            </div>
          ` : ''}
        ` : `
          <div style="padding:12px 0;color:var(--text-sec);font-size:13.5px;">
            Все цели накопления завершены или удалены. Создайте новую цель ниже.
          </div>
        `}

        <!-- Создание новой цели накопления -->
        <div style="margin-top:14px;padding-top:12px;border-top:1px solid var(--border);">
          <div class="item-meta" style="margin-bottom:6px;">Новая цель накопления</div>
          <div class="inline-form" style="margin-top:6px;">
            <input id="newSavingsTitle" type="text" placeholder="На что копим?" class="input-field" />
            <input id="newSavingsTarget" type="number" placeholder="Сумма, ₽" class="input-field" style="max-width:110px;" />
            <button class="btn-soft" onclick="LP.app.createSavingsGoal()">Создать</button>
          </div>
        </div>
      </div>

      <!-- 2. КРУГОВАЯ ДИАГРАММА (Доходы и Расходы за месяц) -->
      <div class="card">
        <div class="card-head">
          <span class="card-label">Доходы и расходы за месяц</span>
        </div>

        <div class="donut-row">
          ${charts.renderDonutChartSVG(fin)}
          <div class="donut-legend">
            <div class="legend-item">
              <span style="color:var(--text-sec);"><span class="legend-dot" style="background:var(--green);"></span>Доходы</span>
              <span style="font-weight:600;">${store.formatRub(fin.income)}</span>
            </div>
            <div class="legend-item">
              <span style="color:var(--text-sec);"><span class="legend-dot" style="background:var(--coral);"></span>Расходы</span>
              <span style="font-weight:600;">${store.formatRub(fin.expense)}</span>
            </div>
            <div class="legend-item" style="padding-top:8px;border-top:1px solid var(--border);">
              <span style="color:var(--text-sec);">Остаток</span>
              <span style="font-weight:700;color:${fin.net >= 0 ? 'var(--green)' : 'var(--coral)'};">
                ${fin.net >= 0 ? '+' : ''}${store.formatRub(fin.net)}
              </span>
            </div>
          </div>
        </div>

        <!-- Форма добавления операции -->
        <div class="inline-form">
          <select id="txType" class="input-field" style="max-width:105px;">
            <option value="expense">Расход</option>
            <option value="income">Доход</option>
          </select>
          <input id="txTitle" type="text" placeholder="Категория / описание" class="input-field" />
        </div>
        <div class="inline-form">
          <input id="txAmount" type="number" placeholder="Сумма, ₽" class="input-field" />
          <button class="btn-primary" onclick="LP.app.addTransaction()">Добавить</button>
        </div>

        <!-- Список последних операций -->
        ${state.transactions.length > 0 ? `
          <div class="item-list" style="margin-top:14px;padding-top:10px;border-top:1px solid var(--border);">
            ${state.transactions.slice(0, 6).map(t => `
              <div class="item-row" style="padding:8px 0;">
                <div class="item-left">
                  <div>
                    <div class="item-title">${store.escapeHtml(t.title)}</div>
                    <div class="item-meta">${t.date}</div>
                  </div>
                </div>
                <div class="item-right">
                  <span style="font-size:13.5px;font-weight:600;color:${t.type === 'income' ? 'var(--green)' : 'var(--text-main)'};">
                    ${t.type === 'income' ? '+' : '−'}${store.formatRub(t.amount)}
                  </span>
                  <button class="del-btn" onclick="LP.app.deleteTransaction('${t.id}')" title="Удалить">✕</button>
                </div>
              </div>
            `).join('')}
          </div>
        ` : ''}
      </div>
    `;
  }

  /* ------------------------------------------------------------------------
     5. MINIMALIST iOS WIDGETS SCREEN
     ------------------------------------------------------------------------ */
  function renderWidgetsScreen() {
    const store = global.LP.store;
    const charts = global.LP.charts;
    const state = store.getState();
    const goals = store.getGoalsProgress();
    const focus = store.getActiveFocusTask();
    const sg = store.getActiveSavingsGoal();
    const fin = store.getFinanceTotals();
    const nextSlot = state.schedule.find(s => !s.done);

    return `
      ${renderHeader('Виджеты iOS', 'Превью на экране iPhone 15 Pro')}

      <div class="widget-grid">
        <!-- Small Widget 1: Цели дня -->
        <div class="ios-widget">
          <div class="card-label" style="margin-bottom:8px;">Цели дня</div>
          <div style="font-size:24px;font-weight:700;">${goals.done}/${goals.total}</div>
          <div class="progress-track" style="margin:8px 0;">
            <div class="progress-fill green" style="width:${goals.pct}%;"></div>
          </div>
          <div class="item-meta">${goals.pct}% выполнено</div>
        </div>

        <!-- Small Widget 2: Фокус -->
        <div class="ios-widget">
          <div class="card-label" style="margin-bottom:8px;">Фокус</div>
          <div style="font-size:13.5px;font-weight:600;line-height:1.35;margin-bottom:8px;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;">
            ${focus ? store.escapeHtml(focus.title) : 'Свободно'}
          </div>
          <div class="item-meta">${store.formatTimer(state.pomodoro.secondsLeft)}</div>
        </div>

        <!-- Medium Widget: Копилка -->
        <div class="ios-widget span-2">
          <div style="display:flex;justify-content:space-between;align-items:center;">
            <div>
              <div class="card-label">Копилка</div>
              <div style="font-size:16px;font-weight:700;margin-top:2px;">
                ${sg ? store.escapeHtml(sg.title) : 'Нет активной цели'}
              </div>
            </div>
            ${sg ? `<span style="font-size:14px;font-weight:600;color:var(--accent);">${sg.pctDone}%</span>` : ''}
          </div>
          ${sg ? `
            <div class="progress-track" style="margin:10px 0;">
              <div class="progress-fill ${sg.isCompleted ? 'green' : ''}" style="width:${sg.pctDone}%;"></div>
            </div>
            <div style="display:flex;justify-content:space-between;font-size:12.5px;color:var(--text-sec);">
              <span>Баланс: <strong style="color:var(--text-main);">${store.formatRub(sg.saved)}</strong></span>
              <span>${sg.isCompleted ? 'Цель достигнута ✓' : `Осталось: <strong style="color:var(--text-main);">${store.formatRub(sg.remainingAmount)}</strong>`}</span>
            </div>
          ` : ''}
        </div>

        <!-- Large Widget: Сводка дня и Баланс -->
        <div class="ios-widget span-2">
          <div class="card-label" style="margin-bottom:10px;">Расписание и баланс месяца</div>
          <div style="padding-bottom:12px;margin-bottom:12px;border-bottom:1px solid var(--border);display:flex;justify-content:space-between;align-items:center;">
            <div>
              <div class="item-meta">Далее по плану</div>
              <div style="font-size:14px;font-weight:600;margin-top:2px;">
                ${nextSlot ? `${nextSlot.start} · ${store.escapeHtml(nextSlot.title)}` : 'Все события завершены'}
              </div>
            </div>
          </div>
          <div style="display:flex;align-items:center;justify-content:space-between;">
            <div>
              <div class="item-meta">Доходы: <strong style="color:var(--green);">+${store.formatRub(fin.income)}</strong></div>
              <div class="item-meta" style="margin-top:3px;">Расходы: <strong style="color:var(--coral);">−${store.formatRub(fin.expense)}</strong></div>
            </div>
            ${charts.renderMiniRingSVG(fin.incomePct, 'var(--green)')}
          </div>
        </div>
      </div>

      <div style="margin-top:16px;text-align:center;">
        <button class="btn-soft" onclick="LP.app.toggleDisplayMode()">← Вернуться в приложение</button>
      </div>
    `;
  }

  global.LP = global.LP || {};
  global.LP.views = {
    renderOverviewTab,
    renderScheduleTab,
    renderFocusTab,
    renderFinanceTab,
    renderWidgetsScreen
  };
})(window);
