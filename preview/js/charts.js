/* ==========================================================================
   LifePulse — js/charts.js
   Minimalist SVG Donut Chart & Progress Rings
   ========================================================================== */

(function (global) {
  'use strict';

  function renderDonutChartSVG(fin) {
    const size = 116;
    const center = size / 2;
    const radius = 46;
    const circum = 2 * Math.PI * radius;
    const incDash = (fin.incomePct / 100) * circum;
    const expDash = Math.max(0, circum - incDash);

    return `
      <div class="donut-svg-wrap">
        <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" style="transform: rotate(-90deg);">
          <circle cx="${center}" cy="${center}" r="${radius}" fill="none" stroke="var(--track)" stroke-width="11" />
          <circle
            cx="${center}" cy="${center}" r="${radius}"
            fill="none"
            stroke="var(--green)"
            stroke-width="11"
            stroke-dasharray="${incDash} ${circum}"
            stroke-dashoffset="0"
          />
          <circle
            cx="${center}" cy="${center}" r="${radius}"
            fill="none"
            stroke="var(--coral)"
            stroke-width="11"
            stroke-dasharray="${expDash} ${circum}"
            stroke-dashoffset="${-incDash}"
          />
        </svg>
        <div class="donut-center">
          <span class="donut-center-sub">Доход / Расход</span>
          <span class="donut-center-num">${fin.incomePct}% / ${fin.expensePct}%</span>
        </div>
      </div>
    `;
  }

  function renderMiniRingSVG(pct, colorVar) {
    const size = 44;
    const center = 22;
    const radius = 17;
    const circum = 2 * Math.PI * radius;
    const offset = circum * (1 - Math.min(100, Math.max(0, pct)) / 100);

    return `
      <div style="position:relative;width:44px;height:44px;display:inline-flex;align-items:center;justify-content:center;flex-shrink:0;">
        <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" style="transform:rotate(-90deg);">
          <circle cx="${center}" cy="${center}" r="${radius}" fill="none" stroke="var(--track)" stroke-width="4.5" />
          <circle
            cx="${center}" cy="${center}" r="${radius}"
            fill="none"
            stroke="${colorVar || 'var(--accent)'}"
            stroke-width="4.5"
            stroke-dasharray="${circum}"
            stroke-dashoffset="${offset}"
            stroke-linecap="round"
          />
        </svg>
        <span style="position:absolute;font-size:11px;font-weight:600;color:var(--text-main);">${pct}%</span>
      </div>
    `;
  }

  global.LP = global.LP || {};
  global.LP.charts = {
    renderDonutChartSVG,
    renderMiniRingSVG
  };
})(window);
