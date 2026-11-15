/* ==========================================================================
   LifePulse — js/app.js
   Main Application Controller, Event Handlers & Pomodoro Timer
   ========================================================================== */

(function (global) {
  'use strict';

  let pomoInterval = null;

  function render() {
    const store = global.LP.store;
    const views = global.LP.views;
    const state = store.getState();

    document.documentElement.setAttribute('data-theme', state.theme);

    // Sync top desktop bar buttons if visible
    const btnModeApp = document.getElementById('btnModeApp');
    const btnModeWid = document.getElementById('btnModeWidgets');
    if (btnModeApp && btnModeWid) {
      btnModeApp.classList.toggle('active', state.displayMode === 'app');
      btnModeWid.classList.toggle('active', state.displayMode === 'widgets');
    }

    // Dynamic Island text
    const islandEl = document.getElementById('dynamicIslandText');
    if (islandEl) {
      if (state.pomodoro.isRunning) {
        islandEl.textContent = `Фокус · ${store.formatTimer(state.pomodoro.secondsLeft)}`;
      } else {
        const sg = store.getActiveSavingsGoal();
        islandEl.textContent = sg
          ? (sg.isCompleted ? `${sg.title} ✓` : `Осталось ${store.formatRub(sg.remainingAmount)}`)
          : 'LifePulse';
      }
    }

    // Main viewport content
    const container = document.getElementById('screenContent');
    if (!container) return;

    if (state.displayMode === 'widgets') {
      container.innerHTML = views.renderWidgetsScreen();
    } else {
      switch (state.activeTab) {
        case 'schedule':
          container.innerHTML = views.renderScheduleTab();
          break;
        case 'focus':
          container.innerHTML = views.renderFocusTab();
          break;
        case 'finance':
          container.innerHTML = views.renderFinanceTab();
          break;
        default:
          container.innerHTML = views.renderOverviewTab();
          break;
      }
    }

    // Sync bottom tab bar
    document.querySelectorAll('.tab-item').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.tab === state.activeTab && state.displayMode === 'app');
    });
  }

  /* Navigation & Theme */
  function switchTab(tab) {
    const state = global.LP.store.getState();
    state.displayMode = 'app';
    state.activeTab = tab;
    global.LP.store.saveState();
    render();
  }

  function setDisplayMode(mode) {
    const state = global.LP.store.getState();
    state.displayMode = mode;
    global.LP.store.saveState();
    render();
  }

  function toggleDisplayMode() {
    const state = global.LP.store.getState();
    state.displayMode = state.displayMode === 'widgets' ? 'app' : 'widgets';
    global.LP.store.saveState();
    render();
  }

  function toggleTheme() {
    const state = global.LP.store.getState();
    state.theme = state.theme === 'dark' ? 'light' : 'dark';
    global.LP.store.saveState();
    render();
  }

  function resetAllData() {
    global.LP.store.resetState();
    render();
  }

  /* Pomodoro Timer */
  function startPomodoroLoop() {
    if (pomoInterval) clearInterval(pomoInterval);
    pomoInterval = setInterval(() => {
      const store = global.LP.store;
      const state = store.getState();
      if (!state.pomodoro.isRunning) return;

      if (state.pomodoro.secondsLeft > 0) {
        state.pomodoro.secondsLeft -= 1;
        const readout = document.getElementById('pomoLiveReadout');
        if (readout) readout.textContent = store.formatTimer(state.pomodoro.secondsLeft);
        const islandEl = document.getElementById('dynamicIslandText');
        if (islandEl) islandEl.textContent = `Фокус · ${store.formatTimer(state.pomodoro.secondsLeft)}`;
      } else {
        state.pomodoro.isRunning = false;
        state.pomodoro.secondsLeft = state.pomodoro.presetMinutes * 60;
        store.saveState();
        render();
      }
    }, 1000);
  }

  function togglePomodoro() {
    const state = global.LP.store.getState();
    state.pomodoro.isRunning = !state.pomodoro.isRunning;
    global.LP.store.saveState();
    render();
  }

  function resetPomodoro() {
    const state = global.LP.store.getState();
    state.pomodoro.isRunning = false;
    state.pomodoro.secondsLeft = (state.pomodoro.presetMinutes || 25) * 60;
    global.LP.store.saveState();
    render();
  }

  function setPomodoroPreset(mins) {
    const state = global.LP.store.getState();
    state.pomodoro.isRunning = false;
    state.pomodoro.presetMinutes = mins;
    state.pomodoro.secondsLeft = mins * 60;
    global.LP.store.saveState();
    render();
  }

  /* Schedule Actions */
  function toggleScheduleDone(id) {
    const state = global.LP.store.getState();
    const item = state.schedule.find(s => s.id === id);
    if (item) {
      item.done = !item.done;
      global.LP.store.saveState();
      render();
    }
  }

  function deleteScheduleItem(id) {
    const state = global.LP.store.getState();
    state.schedule = state.schedule.filter(s => s.id !== id);
    global.LP.store.saveState();
    render();
  }

  function addScheduleItem() {
    const start = (document.getElementById('schedStart')?.value || '18:00').trim();
    const end = (document.getElementById('schedEnd')?.value || '19:00').trim();
    const cat = document.getElementById('schedCat')?.value || 'Личное';
    const titleEl = document.getElementById('schedTitle');
    const title = (titleEl?.value || '').trim();
    if (!title) return;

    const state = global.LP.store.getState();
    state.schedule.push({
      id: 's_' + Date.now(),
      start,
      end,
      title,
      category: cat,
      done: false
    });
    state.schedule.sort((a, b) => a.start.localeCompare(b.start));
    global.LP.store.saveState();
    render();
  }

  /* Tasks & Daily Goals Actions */
  function toggleTaskDone(id) {
    const state = global.LP.store.getState();
    const t = state.tasks.find(x => x.id === id);
    if (t) {
      t.done = !t.done;
      global.LP.store.saveState();
      render();
    }
  }

  function selectFocusTask(id) {
    const state = global.LP.store.getState();
    state.focusTaskId = id;
    global.LP.store.saveState();
    render();
  }

  function deleteTask(id) {
    const state = global.LP.store.getState();
    state.tasks = state.tasks.filter(t => t.id !== id);
    global.LP.store.saveState();
    render();
  }

  function addTask() {
    const input = document.getElementById('newTaskTitle');
    const title = (input?.value || '').trim();
    if (!title) return;
    const state = global.LP.store.getState();
    const newId = 't_' + Date.now();
    state.tasks.unshift({ id: newId, title, priority: 'medium', done: false });
    state.focusTaskId = newId;
    global.LP.store.saveState();
    render();
  }

  function toggleDailyGoal(id) {
    const state = global.LP.store.getState();
    const g = state.dailyGoals.find(x => x.id === id);
    if (g) {
      g.done = !g.done;
      global.LP.store.saveState();
      render();
    }
  }

  function deleteDailyGoal(id) {
    const state = global.LP.store.getState();
    state.dailyGoals = state.dailyGoals.filter(g => g.id !== id);
    global.LP.store.saveState();
    render();
  }

  function addDailyGoal() {
    const input = document.getElementById('newGoalTitle');
    const title = (input?.value || '').trim();
    if (!title) return;
    const state = global.LP.store.getState();
    state.dailyGoals.push({ id: 'g_' + Date.now(), title, done: false });
    global.LP.store.saveState();
    render();
  }

  /* Savings Goal (Копилка) Actions — Top-up, Complete & Remove, Delete */
  function selectSavingsGoal(id) {
    const state = global.LP.store.getState();
    state.selectedSavingsId = id;
    global.LP.store.saveState();
    render();
  }

  function quickTopUp(amount) {
    const store = global.LP.store;
    const state = store.getState();
    const sg = store.getActiveSavingsGoal();
    if (!sg) return;
    const targetGoal = state.savingsGoals.find(g => g.id === sg.id);
    if (!targetGoal) return;

    targetGoal.saved += Number(amount) || 0;
    targetGoal.history = targetGoal.history || [];
    targetGoal.history.unshift({
      id: 'h_' + Date.now(),
      amount: Number(amount),
      comment: 'Быстрое пополнение',
      date: 'Сегодня'
    });
    store.saveState();
    render();
  }

  function customTopUp() {
    const amtInput = document.getElementById('topUpAmount');
    const amount = Math.round(Number(amtInput?.value || 0));
    if (amount <= 0) return;
    quickTopUp(amount);
  }

  function completeSavingsGoal(id) {
    global.LP.store.deleteSavingsGoal(id);
    render();
  }

  function deleteSavingsGoal(id) {
    global.LP.store.deleteSavingsGoal(id);
    render();
  }

  function deleteContribution(goalId, contribId) {
    global.LP.store.deleteSavingsContribution(goalId, contribId);
    render();
  }

  function createSavingsGoal() {
    const titleEl = document.getElementById('newSavingsTitle');
    const targetEl = document.getElementById('newSavingsTarget');
    const title = (titleEl?.value || '').trim();
    const target = Math.round(Number(targetEl?.value || 0));
    if (!title || target <= 0) return;

    const state = global.LP.store.getState();
    const newId = 'sv_' + Date.now();
    state.savingsGoals.push({
      id: newId,
      title,
      target,
      saved: 0,
      history: []
    });
    state.selectedSavingsId = newId;
    global.LP.store.saveState();
    render();
  }

  /* Finance Transactions Actions */
  function addTransaction() {
    const type = document.getElementById('txType')?.value || 'expense';
    const title = (document.getElementById('txTitle')?.value || '').trim() || (type === 'income' ? 'Доход' : 'Расход');
    const amount = Math.round(Number(document.getElementById('txAmount')?.value || 0));
    if (amount <= 0) return;

    const state = global.LP.store.getState();
    state.transactions.unshift({
      id: 'tx_' + Date.now(),
      type,
      amount,
      title,
      category: title,
      date: 'Сегодня'
    });
    global.LP.store.saveState();
    render();
  }

  function deleteTransaction(id) {
    const state = global.LP.store.getState();
    state.transactions = state.transactions.filter(t => t.id !== id);
    global.LP.store.saveState();
    render();
  }

  /* Install on iPhone 15 Pro Modal */
  function toggleInstallModal(show) {
    const modal = document.getElementById('installModal');
    if (modal) modal.style.display = show ? 'flex' : 'none';
  }

  function init() {
    render();
    startPomodoroLoop();
    if ('serviceWorker' in navigator && location.protocol.startsWith('http')) {
      navigator.serviceWorker.register('./sw.js').catch(() => {});
    }
  }

  global.LP = global.LP || {};
  global.LP.app = {
    init,
    render,
    switchTab,
    setDisplayMode,
    toggleDisplayMode,
    toggleTheme,
    resetAllData,
    togglePomodoro,
    resetPomodoro,
    setPomodoroPreset,
    toggleScheduleDone,
    deleteScheduleItem,
    addScheduleItem,
    toggleTaskDone,
    selectFocusTask,
    deleteTask,
    addTask,
    toggleDailyGoal,
    deleteDailyGoal,
    addDailyGoal,
    selectSavingsGoal,
    quickTopUp,
    customTopUp,
    completeSavingsGoal,
    deleteSavingsGoal,
    deleteContribution,
    createSavingsGoal,
    addTransaction,
    deleteTransaction,
    toggleInstallModal
  };

  document.addEventListener('DOMContentLoaded', init);
})(window);
