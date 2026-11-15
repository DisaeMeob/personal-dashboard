/* ==========================================================================
   LifePulse — js/store.js
   Minimalist State Store, Savings Goal Completion/Deletion & Finance Totals
   ========================================================================== */

(function (global) {
  'use strict';

  const STORAGE_KEY = 'lifepulse_minimal_state_v2';

  function getDefaultData() {
    return {
      theme: 'dark',
      displayMode: 'app', // 'app' | 'widgets'
      activeTab: 'overview', // 'overview' | 'schedule' | 'focus' | 'finance'
      streakDays: 12,
      schedule: [
        { id: 's1', start: '09:00', end: '10:00', title: 'Утренняя тренировка', category: 'Спорт', done: true },
        { id: 's2', start: '10:30', end: '13:00', title: 'Глубокая работа над проектом', category: 'Работа', done: true },
        { id: 's3', start: '14:00', end: '15:00', title: 'Обед и прогулка', category: 'Личное', done: false },
        { id: 's4', start: '16:00', end: '17:30', title: 'Изучение SwiftUI', category: 'Учёба', done: false }
      ],
      pomodoro: {
        presetMinutes: 25,
        secondsLeft: 25 * 60,
        isRunning: false
      },
      focusTaskId: 't1',
      tasks: [
        { id: 't1', title: 'Доработать главный экран дашборда', priority: 'high', done: false },
        { id: 't2', title: 'Проверить месячный бюджет', priority: 'medium', done: false },
        { id: 't3', title: 'Разобрать заметки за неделю', priority: 'low', done: true }
      ],
      dailyGoals: [
        { id: 'g1', title: 'Выпить 2 литра воды', done: true },
        { id: 'g2', title: '2 фокус-сессии без телефона', done: true },
        { id: 'g3', title: 'Отложить деньги в копилку', done: true },
        { id: 'g4', title: 'Чтение 30 минут вечером', done: false }
      ],
      selectedSavingsId: 'sv1',
      savingsGoals: [
        {
          id: 'sv1',
          title: 'Отпуск в Японии',
          target: 300000,
          saved: 215000,
          history: [
            { id: 'h1', amount: 25000, comment: 'С аванса', date: '12 нояб.' },
            { id: 'h2', amount: 10000, comment: 'Кэшбэк', date: '08 нояб.' }
          ]
        },
        {
          id: 'sv2',
          title: 'MacBook Pro M4',
          target: 250000,
          saved: 180000,
          history: [
            { id: 'h3', amount: 30000, comment: 'Проект', date: '10 нояб.' }
          ]
        }
      ],
      transactions: [
        { id: 'tx1', type: 'income', amount: 185000, title: 'Основной доход', category: 'Зарплата', date: '05 нояб.' },
        { id: 'tx2', type: 'income', amount: 45000, title: 'Дополнительный проект', category: 'Фриланс', date: '11 нояб.' },
        { id: 'tx3', type: 'expense', amount: 55000, title: 'Жильё и счета', category: 'Жильё', date: '06 нояб.' },
        { id: 'tx4', type: 'expense', amount: 32000, title: 'Продукты и супермаркеты', category: 'Продукты', date: '12 нояб.' },
        { id: 'tx5', type: 'expense', amount: 15000, title: 'Подписки, спорт и транспорт', category: 'Повседневное', date: '14 нояб.' }
      ]
    };
  }

  function loadState() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return getDefaultData();
      const parsed = JSON.parse(raw);
      return Object.assign(getDefaultData(), parsed);
    } catch (e) {
      return getDefaultData();
    }
  }

  let state = loadState();

  function saveState() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (e) {}
  }

  function resetState() {
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch (e) {}
    state = getDefaultData();
    saveState();
    return state;
  }

  function formatRub(val) {
    const num = Math.round(Number(val) || 0);
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ') + ' ₽';
  }

  function formatTimer(sec) {
    const s = Math.max(0, Math.floor(sec));
    const m = String(Math.floor(s / 60)).padStart(2, '0');
    const r = String(s % 60).padStart(2, '0');
    return `${m}:${r}`;
  }

  function escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function getActiveSavingsGoal() {
    if (!state.savingsGoals || state.savingsGoals.length === 0) {
      return null;
    }
    let goal = state.savingsGoals.find(g => g.id === state.selectedSavingsId);
    if (!goal) {
      goal = state.savingsGoals[0];
      state.selectedSavingsId = goal.id;
    }
    const remainingAmount = Math.max(0, goal.target - goal.saved);
    const pctDone = goal.target > 0 ? Math.min(100, Math.round((goal.saved / goal.target) * 100)) : 100;
    const pctRemaining = Math.max(0, 100 - pctDone);
    const isCompleted = remainingAmount === 0 && goal.target > 0;
    return Object.assign({}, goal, {
      remainingAmount,
      pctDone,
      pctRemaining,
      isCompleted
    });
  }

  function deleteSavingsGoal(id) {
    state.savingsGoals = state.savingsGoals.filter(g => g.id !== id);
    if (state.selectedSavingsId === id) {
      state.selectedSavingsId = state.savingsGoals[0] ? state.savingsGoals[0].id : null;
    }
    saveState();
  }

  function deleteSavingsContribution(goalId, contribId) {
    const goal = state.savingsGoals.find(g => g.id === goalId);
    if (!goal || !goal.history) return;
    const item = goal.history.find(h => h.id === contribId);
    if (item) {
      goal.saved = Math.max(0, goal.saved - (Number(item.amount) || 0));
      goal.history = goal.history.filter(h => h.id !== contribId);
      saveState();
    }
  }

  function getActiveFocusTask() {
    return state.tasks.find(t => t.id === state.focusTaskId && !t.done)
      || state.tasks.find(t => !t.done)
      || state.tasks[0]
      || null;
  }

  function getGoalsProgress() {
    const total = state.dailyGoals.length;
    const done = state.dailyGoals.filter(g => g.done).length;
    const pct = total > 0 ? Math.round((done / total) * 100) : 0;
    return { total, done, pct };
  }

  function getFinanceTotals() {
    let income = 0;
    let expense = 0;
    state.transactions.forEach(t => {
      const amt = Number(t.amount) || 0;
      if (t.type === 'income') income += amt;
      else expense += amt;
    });
    const volume = income + expense;
    const incomePct = volume > 0 ? Math.round((income / volume) * 100) : 50;
    const expensePct = volume > 0 ? 100 - incomePct : 50;
    const net = income - expense;
    return { income, expense, volume, incomePct, expensePct, net };
  }

  global.LP = global.LP || {};
  global.LP.store = {
    STORAGE_KEY,
    getState: () => state,
    saveState,
    resetState,
    formatRub,
    formatTimer,
    escapeHtml,
    getActiveSavingsGoal,
    deleteSavingsGoal,
    deleteSavingsContribution,
    getActiveFocusTask,
    getGoalsProgress,
    getFinanceTotals
  };
})(window);
