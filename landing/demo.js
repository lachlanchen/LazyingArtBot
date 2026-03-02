(function () {
  "use strict";

  /* ─────────────────────────────────────────────
     INJECT CSS
  ───────────────────────────────────────────── */
  const style = document.createElement("style");
  style.textContent = `
    /* ── Layout ── */
    .kd-wrapper {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 20px;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
    }

    /* ── Tabs ── */
    .kd-tabs {
      display: flex;
      gap: 8px;
      background: rgba(255,255,255,0.05);
      border-radius: 12px;
      padding: 4px;
    }
    .kd-tab {
      padding: 8px 18px;
      border: none;
      border-radius: 9px;
      background: transparent;
      color: rgba(255,255,255,0.5);
      font-size: 13px;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s ease;
      white-space: nowrap;
    }
    .kd-tab:hover {
      color: rgba(255,255,255,0.8);
      background: rgba(255,255,255,0.07);
    }
    .kd-tab.kd-tab--active {
      background: var(--lp-amber, #f59e0b);
      color: #000;
      font-weight: 600;
    }

    /* ── Phone frame ── */
    .kd-phone {
      width: 375px;
      max-width: 100%;
      border-radius: 24px;
      background: #0d1020;
      border: 1px solid rgba(255,255,255,0.08);
      overflow: hidden;
      box-shadow: 0 32px 80px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.04);
      display: flex;
      flex-direction: column;
      height: 520px;
    }

    /* ── Phone header ── */
    .kd-phone-header {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 14px 16px;
      background: #111827;
      border-bottom: 1px solid rgba(255,255,255,0.06);
      flex-shrink: 0;
    }
    .kd-avatar {
      width: 36px;
      height: 36px;
      border-radius: 50%;
      background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      color: #000;
      font-weight: 700;
      font-size: 15px;
      flex-shrink: 0;
    }
    .kd-phone-name {
      font-size: 15px;
      font-weight: 600;
      color: #f3f4f6;
      line-height: 1.2;
    }
    .kd-phone-status {
      font-size: 11px;
      color: #34d399;
      line-height: 1.2;
    }

    /* ── Messages area ── */
    .kd-messages {
      flex: 1;
      overflow-y: auto;
      padding: 16px 12px;
      display: flex;
      flex-direction: column;
      gap: 6px;
      scroll-behavior: smooth;
    }
    .kd-messages::-webkit-scrollbar {
      width: 3px;
    }
    .kd-messages::-webkit-scrollbar-track {
      background: transparent;
    }
    .kd-messages::-webkit-scrollbar-thumb {
      background: rgba(255,255,255,0.1);
      border-radius: 2px;
    }

    /* ── Message rows ── */
    .kd-msg-row {
      display: flex;
      align-items: flex-end;
      gap: 6px;
      animation: kd-fade-in 0.25s ease forwards;
    }
    .kd-msg-row--bot {
      justify-content: flex-start;
    }
    .kd-msg-row--user {
      justify-content: flex-end;
    }

    @keyframes kd-fade-in {
      from { opacity: 0; transform: translateY(6px); }
      to   { opacity: 1; transform: translateY(0); }
    }

    /* ── Bubbles ── */
    .kd-bubble {
      max-width: 78%;
      padding: 9px 13px;
      border-radius: 16px;
      font-size: 13.5px;
      line-height: 1.5;
      word-break: break-word;
      white-space: pre-wrap;
    }
    .kd-bubble--bot {
      background: #1e2435;
      color: #e5e7eb;
      border-bottom-left-radius: 4px;
    }
    .kd-bubble--user {
      background: rgba(245, 158, 11, 0.18);
      color: #fde68a;
      border: 1px solid rgba(245,158,11,0.25);
      border-bottom-right-radius: 4px;
    }
    .kd-bubble b, .kd-bubble strong {
      color: #f9fafb;
      font-weight: 600;
    }
    .kd-bubble em {
      color: #a3cfff;
      font-style: italic;
    }

    /* ── Timestamp ── */
    .kd-ts {
      font-size: 10px;
      color: rgba(255,255,255,0.28);
      margin-top: 2px;
      padding: 0 4px;
    }
    .kd-msg-row--user .kd-ts {
      text-align: right;
    }

    /* ── Rich card (晨報) ── */
    .kd-card {
      background: #1a2030;
      border: 1px solid rgba(255,255,255,0.07);
      border-radius: 14px;
      overflow: hidden;
      max-width: 82%;
      animation: kd-fade-in 0.25s ease forwards;
    }
    .kd-card-header {
      background: rgba(245,158,11,0.12);
      border-bottom: 1px solid rgba(245,158,11,0.15);
      padding: 8px 13px;
      font-size: 11px;
      font-weight: 600;
      color: var(--lp-amber, #f59e0b);
      letter-spacing: 0.04em;
      text-transform: uppercase;
    }
    .kd-card-body {
      padding: 12px 13px;
      font-size: 12.5px;
      color: #d1d5db;
      line-height: 1.65;
    }
    .kd-card-section {
      margin-bottom: 10px;
    }
    .kd-card-section:last-child {
      margin-bottom: 0;
    }
    .kd-card-section-title {
      font-size: 11.5px;
      font-weight: 600;
      color: #f59e0b;
      margin-bottom: 4px;
    }
    .kd-card-item {
      display: flex;
      gap: 6px;
      margin: 2px 0;
      font-size: 12px;
    }
    .kd-card-item::before {
      content: '•';
      color: rgba(255,255,255,0.3);
      flex-shrink: 0;
    }
    .kd-card-item .kd-tag-high {
      color: #f87171;
      font-weight: 600;
      font-size: 10px;
      background: rgba(248,113,113,0.1);
      padding: 1px 5px;
      border-radius: 4px;
    }
    .kd-card-item .kd-tag-med {
      color: #fbbf24;
      font-weight: 600;
      font-size: 10px;
      background: rgba(251,191,36,0.1);
      padding: 1px 5px;
      border-radius: 4px;
    }

    /* ── Typing indicator ── */
    .kd-typing-row {
      display: flex;
      align-items: flex-end;
      gap: 6px;
    }
    .kd-typing {
      background: #1e2435;
      border-radius: 16px;
      border-bottom-left-radius: 4px;
      padding: 10px 14px;
      display: flex;
      gap: 5px;
      align-items: center;
    }
    .kd-dot {
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: rgba(255,255,255,0.35);
      animation: kd-bounce 1.2s ease-in-out infinite;
    }
    .kd-dot:nth-child(2) { animation-delay: 0.2s; }
    .kd-dot:nth-child(3) { animation-delay: 0.4s; }

    @keyframes kd-bounce {
      0%, 60%, 100% { transform: translateY(0); opacity: 0.35; }
      30%           { transform: translateY(-5px); opacity: 1; }
    }

    /* ── Voice bubble ── */
    .kd-voice-bubble {
      display: flex;
      align-items: center;
      gap: 10px;
      background: #1e2435;
      border-radius: 16px;
      border-bottom-left-radius: 4px;
      padding: 10px 14px;
      max-width: 82%;
      animation: kd-fade-in 0.25s ease forwards;
    }
    .kd-play-btn {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      border: none;
      background: var(--lp-amber, #f59e0b);
      color: #000;
      font-size: 11px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      transition: transform 0.15s ease, opacity 0.15s ease;
    }
    .kd-play-btn:hover {
      transform: scale(1.08);
      opacity: 0.9;
    }
    .kd-waveform {
      width: 100px;
      height: 28px;
      flex-shrink: 0;
    }
    .kd-waveform-bar {
      fill: rgba(245,158,11,0.4);
      rx: 2;
      transition: fill 0.2s ease;
    }
    .kd-playing .kd-waveform-bar {
      fill: var(--lp-amber, #f59e0b);
      animation: kd-wave-pulse 0.8s ease-in-out infinite alternate;
    }
    .kd-playing .kd-waveform-bar:nth-child(odd) {
      animation-delay: 0.15s;
    }
    @keyframes kd-wave-pulse {
      from { opacity: 0.6; }
      to   { opacity: 1; }
    }
    .kd-voice-label {
      font-size: 11px;
      color: rgba(255,255,255,0.45);
      line-height: 1.3;
    }
    .kd-voice-label strong {
      color: rgba(255,255,255,0.7);
      font-weight: 600;
      display: block;
    }
    .kd-duration {
      font-size: 11px;
      color: rgba(255,255,255,0.35);
      flex-shrink: 0;
    }

    /* ── Checkbox list ── */
    .kd-checklist {
      list-style: none;
      padding: 0;
      margin: 4px 0 0;
    }
    .kd-checklist li {
      display: flex;
      gap: 7px;
      align-items: flex-start;
      font-size: 12px;
      color: #9ca3af;
      margin: 3px 0;
    }
    .kd-checklist li::before {
      content: '☐';
      color: rgba(255,255,255,0.25);
      flex-shrink: 0;
    }

    /* ── Input area ── */
    .kd-input-area {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 10px 12px;
      background: #111827;
      border-top: 1px solid rgba(255,255,255,0.06);
      flex-shrink: 0;
    }
    .kd-input-field {
      flex: 1;
      background: #1e2435;
      border: 1px solid rgba(255,255,255,0.07);
      border-radius: 20px;
      padding: 8px 14px;
      font-size: 13px;
      color: rgba(255,255,255,0.25);
      pointer-events: none;
      user-select: none;
    }
    .kd-send-btn {
      width: 34px;
      height: 34px;
      border-radius: 50%;
      border: none;
      background: var(--lp-amber, #f59e0b);
      color: #000;
      font-size: 14px;
      font-weight: 700;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      transition: transform 0.15s;
    }
    .kd-send-btn:hover {
      transform: scale(1.08);
    }
  `;
  document.head.appendChild(style);

  /* ─────────────────────────────────────────────
     HELPERS
  ───────────────────────────────────────────── */
  function delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  function nowTime() {
    const d = new Date();
    return (
      d.getHours().toString().padStart(2, "0") + ":" + d.getMinutes().toString().padStart(2, "0")
    );
  }

  // Simple markdown → HTML converter (bold, italic, inline only)
  function md(text) {
    return text.replace(/\*\*(.+?)\*\*/g, "<b>$1</b>").replace(/\*(.+?)\*/g, "<em>$1</em>");
  }

  /* ─────────────────────────────────────────────
     WAVEFORM SVG BUILDER
  ───────────────────────────────────────────── */
  const waveHeights = [
    8, 14, 20, 24, 18, 10, 26, 22, 16, 12, 24, 20, 8, 18, 26, 14, 22, 10, 20, 16,
  ];

  function buildWaveformSVG() {
    const barW = 4;
    const gap = 1.5;
    const svgH = 28;
    const bars = waveHeights
      .map((h, i) => {
        const x = i * (barW + gap);
        const y = (svgH - h) / 2;
        return `<rect class="kd-waveform-bar" x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${barW}" height="${h}" rx="2"/>`;
      })
      .join("");
    const totalW = waveHeights.length * (barW + gap) - gap;
    return `<svg class="kd-waveform" viewBox="0 0 ${totalW.toFixed(0)} ${svgH}" preserveAspectRatio="none">${bars}</svg>`;
  }

  /* ─────────────────────────────────────────────
     DOM BUILDERS
  ───────────────────────────────────────────── */

  function makeBotBubble(text) {
    const row = document.createElement("div");
    row.className = "kd-msg-row kd-msg-row--bot";

    const bubble = document.createElement("div");
    bubble.className = "kd-bubble kd-bubble--bot";
    bubble.innerHTML = md(text);

    const ts = document.createElement("div");
    ts.className = "kd-ts";
    ts.textContent = nowTime();

    const col = document.createElement("div");
    col.style.cssText = "display:flex;flex-direction:column;align-items:flex-start;";
    col.appendChild(bubble);
    col.appendChild(ts);

    row.appendChild(col);
    return row;
  }

  function makeUserBubble(text) {
    const row = document.createElement("div");
    row.className = "kd-msg-row kd-msg-row--user";

    const col = document.createElement("div");
    col.style.cssText = "display:flex;flex-direction:column;align-items:flex-end;";

    const bubble = document.createElement("div");
    bubble.className = "kd-bubble kd-bubble--user";
    bubble.textContent = text;

    const ts = document.createElement("div");
    ts.className = "kd-ts";
    ts.textContent = nowTime();

    col.appendChild(bubble);
    col.appendChild(ts);
    row.appendChild(col);
    return row;
  }

  function makeTypingIndicator() {
    const row = document.createElement("div");
    row.className = "kd-typing-row";

    const typing = document.createElement("div");
    typing.className = "kd-typing";
    typing.innerHTML =
      '<div class="kd-dot"></div><div class="kd-dot"></div><div class="kd-dot"></div>';

    row.appendChild(typing);
    return row;
  }

  function makeRichCard(headerText, sections) {
    // sections: [{title, items}]
    const row = document.createElement("div");
    row.className = "kd-msg-row kd-msg-row--bot";

    const card = document.createElement("div");
    card.className = "kd-card";

    const hdr = document.createElement("div");
    hdr.className = "kd-card-header";
    hdr.textContent = headerText;
    card.appendChild(hdr);

    const body = document.createElement("div");
    body.className = "kd-card-body";

    sections.forEach((s) => {
      const sec = document.createElement("div");
      sec.className = "kd-card-section";

      const title = document.createElement("div");
      title.className = "kd-card-section-title";
      title.textContent = s.title;
      sec.appendChild(title);

      s.items.forEach((item) => {
        const line = document.createElement("div");
        line.className = "kd-card-item";
        if (typeof item === "string") {
          line.innerHTML = item;
        } else {
          // {tag, text}
          const tagEl = document.createElement("span");
          tagEl.className = item.tagClass;
          tagEl.textContent = item.tag;
          line.appendChild(tagEl);
          const t = document.createElement("span");
          t.textContent = " " + item.text;
          line.appendChild(t);
        }
        sec.appendChild(line);
      });

      body.appendChild(sec);
    });

    card.appendChild(body);
    row.appendChild(card);
    return row;
  }

  function makeVoiceBubble(labelMain, labelSub, duration) {
    const row = document.createElement("div");
    row.className = "kd-msg-row kd-msg-row--bot";

    const vb = document.createElement("div");
    vb.className = "kd-voice-bubble";

    const btn = document.createElement("button");
    btn.className = "kd-play-btn";
    btn.innerHTML = "▶";
    btn.setAttribute("aria-label", "Play voice message");

    let playing = false;
    let playTimer = null;
    btn.addEventListener("click", () => {
      playing = !playing;
      btn.innerHTML = playing ? "⏸" : "▶";
      vb.classList.toggle("kd-playing", playing);
      if (playing) {
        // Auto-stop after a few seconds
        clearTimeout(playTimer);
        playTimer = setTimeout(() => {
          playing = false;
          btn.innerHTML = "▶";
          vb.classList.remove("kd-playing");
        }, 4000);
      } else {
        clearTimeout(playTimer);
      }
    });

    vb.appendChild(btn);
    vb.innerHTML += buildWaveformSVG();
    // Re-append because innerHTML clobbers btn listener — use insertAdjacentHTML instead
    // Re-build properly:
    vb.innerHTML = "";
    vb.appendChild(btn);

    const svgWrapper = document.createElement("div");
    svgWrapper.innerHTML = buildWaveformSVG();
    vb.appendChild(svgWrapper.firstChild);

    const info = document.createElement("div");
    info.className = "kd-voice-label";
    info.innerHTML = `<strong>${labelMain}</strong>${labelSub}`;
    vb.appendChild(info);

    const dur = document.createElement("span");
    dur.className = "kd-duration";
    dur.textContent = duration;
    vb.appendChild(dur);

    row.appendChild(vb);
    return row;
  }

  /* ─────────────────────────────────────────────
     SCENARIO DEFINITIONS
  ───────────────────────────────────────────── */

  const scenarios = [
    /* ── 0: 晨報 ─────────────────────────── */
    async function scenarioBriefing(msgs, cancelToken) {
      // 1. Bot greeting with typing
      const t1 = makeTypingIndicator();
      msgs.appendChild(t1);
      scrollBottom(msgs);
      await delay(1500);
      if (cancelToken.cancelled) {
        return;
      }
      t1.remove();

      msgs.appendChild(makeBotBubble("早安 Ken 👋 今天是 3月2日（週一），以下是你的晨報："));
      scrollBottom(msgs);
      await delay(400);
      if (cancelToken.cancelled) {
        return;
      }

      // 2. Rich card
      const card = makeRichCard("📋 今日晨報 · 3月2日 週一", [
        {
          title: "📅 今日日曆",
          items: ["10:00 產品例會 @飛書", "14:00 投資人電話", "17:00 健身打卡"],
        },
        {
          title: "📧 重要郵件 (3)",
          items: ["Y Combinator 申請確認", "Cloudflare 帳單提醒", "技術顧問 Li Wei 回覆"],
        },
        {
          title: "📌 待辦跟進",
          items: [
            { tagClass: "kd-tag-high", tag: "HIGH", text: "完成 Demo 視頻剪輯" },
            { tagClass: "kd-tag-med", tag: "MED", text: "回覆 VC 郵件" },
          ],
        },
      ]);
      msgs.appendChild(card);
      scrollBottom(msgs);
      await delay(2200);
      if (cancelToken.cancelled) {
        return;
      }

      // 3. User message
      msgs.appendChild(makeUserBubble("把 14:00 的電話改到 15:00"));
      scrollBottom(msgs);
      await delay(600);
      if (cancelToken.cancelled) {
        return;
      }

      // 4. Bot typing + reply
      const t2 = makeTypingIndicator();
      msgs.appendChild(t2);
      scrollBottom(msgs);
      await delay(1500);
      if (cancelToken.cancelled) {
        return;
      }
      t2.remove();

      msgs.appendChild(makeBotBubble("✅ 已更新！飛書日曆已同步，**15:00 投資人電話**。"));
      scrollBottom(msgs);
    },

    /* ── 1: 捕捉 ─────────────────────────── */
    async function scenarioCapture(msgs, cancelToken) {
      // 1. User
      msgs.appendChild(makeUserBubble("下週要做一個關於 AI 秘書市場的調研，整理競品對比"));
      scrollBottom(msgs);
      await delay(600);
      if (cancelToken.cancelled) {
        return;
      }

      // 2. Bot typing
      const t1 = makeTypingIndicator();
      msgs.appendChild(t1);
      scrollBottom(msgs);
      await delay(2000);
      if (cancelToken.cancelled) {
        return;
      }
      t1.remove();

      msgs.appendChild(makeBotBubble("📥 已捕捉！正在分析需求並建立任務..."));
      scrollBottom(msgs);
      await delay(500);
      if (cancelToken.cancelled) {
        return;
      }

      // 3. Rich task card
      const taskCard = makeRichCard("⚡ 任務已建立", [
        {
          title: "🗂 AI 秘書市場調研",
          items: [
            "預計完成：3月9日（週日）",
            { tagClass: "kd-tag-high", tag: "HIGH", text: "優先級" },
          ],
        },
        {
          title: "📋 子任務",
          items: ["☐ 競品列表（Notion AI / Mem / Rewind）", "☐ 功能對比矩陣", "☐ 市場規模估算"],
        },
        {
          title: "🔔 提醒",
          items: ["週五（3月7日）截止前提醒", "已加入下週計劃"],
        },
      ]);
      msgs.appendChild(taskCard);
      scrollBottom(msgs);
      await delay(2500);
      if (cancelToken.cancelled) {
        return;
      }

      // 4. User follow-up
      msgs.appendChild(makeUserBubble("好的，順便追蹤 Mem.ai 的最新動態"));
      scrollBottom(msgs);
      await delay(600);
      if (cancelToken.cancelled) {
        return;
      }

      // 5. Bot quick reply
      const t2 = makeTypingIndicator();
      msgs.appendChild(t2);
      scrollBottom(msgs);
      await delay(1000);
      if (cancelToken.cancelled) {
        return;
      }
      t2.remove();

      msgs.appendChild(makeBotBubble("✅ 已添加追蹤：**Mem.ai 動態監控**，每週一彙報至秘書頻道。"));
      scrollBottom(msgs);
    },

    /* ── 2: 課程 ─────────────────────────── */
    async function scenarioLearning(msgs, cancelToken) {
      // 1. Header
      msgs.appendChild(makeBotBubble("🌅 每日語言課 — 今日主題：**商業談判用語**"));
      scrollBottom(msgs);
      await delay(1200);
      if (cancelToken.cancelled) {
        return;
      }

      // 2. EN bubble
      const enText =
        "**English**\n*「I'd like to circle back on this after we've had a chance to review the numbers.」*\n\n讓我們在查看數據後再回來討論這個問題。";
      msgs.appendChild(makeBotBubble(enText));
      scrollBottom(msgs);
      await delay(1800);
      if (cancelToken.cancelled) {
        return;
      }

      // 3. JA bubble
      const jaText =
        "**日本語**\n「数字を確認してから、この件に戻りましょう。」\n\nビジネスシーンで自然に使えます。";
      msgs.appendChild(makeBotBubble(jaText));
      scrollBottom(msgs);
      await delay(1800);
      if (cancelToken.cancelled) {
        return;
      }

      // 4. EN voice bubble
      msgs.appendChild(makeVoiceBubble("🔊 EN 發音練習", "點擊播放", "0:08"));
      scrollBottom(msgs);
      await delay(1000);
      if (cancelToken.cancelled) {
        return;
      }

      // 5. JA voice bubble
      msgs.appendChild(makeVoiceBubble("🔊 JA 発音練習", "タップして再生", "0:07"));
      scrollBottom(msgs);
    },
  ];

  /* ─────────────────────────────────────────────
     SCROLL HELPER
  ───────────────────────────────────────────── */
  function scrollBottom(el) {
    el.scrollTop = el.scrollHeight;
  }

  /* ─────────────────────────────────────────────
     BUILD UI
  ───────────────────────────────────────────── */
  const container = document.getElementById("chat-demo");
  if (!container) {
    return;
  }

  // Wrapper
  const wrapper = document.createElement("div");
  wrapper.className = "kd-wrapper";

  // Tabs
  const tabsEl = document.createElement("div");
  tabsEl.className = "kd-tabs";
  const tabLabels = ["📋 晨報", "⚡ 捕捉", "🎓 課程"];
  tabLabels.forEach((label, i) => {
    const btn = document.createElement("button");
    btn.className = "kd-tab" + (i === 0 ? " kd-tab--active" : "");
    btn.textContent = label;
    btn.dataset.idx = i;
    tabsEl.appendChild(btn);
  });

  // Phone
  const phone = document.createElement("div");
  phone.className = "kd-phone";

  // Header
  const header = document.createElement("div");
  header.className = "kd-phone-header";
  header.innerHTML = `
    <div class="kd-avatar">K</div>
    <div class="kd-phone-info">
      <div class="kd-phone-name">Kairo</div>
      <div class="kd-phone-status">● 在線</div>
    </div>
  `;

  // Messages
  const msgsEl = document.createElement("div");
  msgsEl.className = "kd-messages";
  msgsEl.id = "kd-messages";

  // Input area
  const inputArea = document.createElement("div");
  inputArea.className = "kd-input-area";
  inputArea.innerHTML = `
    <div class="kd-input-field">輸入消息...</div>
    <button class="kd-send-btn" aria-label="Send">→</button>
  `;

  phone.appendChild(header);
  phone.appendChild(msgsEl);
  phone.appendChild(inputArea);

  wrapper.appendChild(tabsEl);
  wrapper.appendChild(phone);
  container.appendChild(wrapper);

  /* ─────────────────────────────────────────────
     PLAYBACK ENGINE
  ───────────────────────────────────────────── */
  let _currentScenarioIdx = 0;
  let cancelToken = { cancelled: false };
  let replayTimer = null;

  async function playScenario(idx) {
    // Cancel previous
    cancelToken.cancelled = true;
    clearTimeout(replayTimer);
    await delay(50); // micro-yield

    // Reset
    msgsEl.innerHTML = "";
    cancelToken = { cancelled: false };
    _currentScenarioIdx = idx;

    try {
      await scenarios[idx](msgsEl, cancelToken);
      if (!cancelToken.cancelled) {
        // Replay after 3.5s
        replayTimer = setTimeout(() => playScenario(idx), 3500);
      }
    } catch (_e) {
      // Silently ignore cancellation errors
    }
  }

  // Tab click handler
  tabsEl.querySelectorAll(".kd-tab").forEach((btn) => {
    btn.addEventListener("click", () => {
      const idx = parseInt(btn.dataset.idx, 10);
      tabsEl.querySelectorAll(".kd-tab").forEach((b) => b.classList.remove("kd-tab--active"));
      btn.classList.add("kd-tab--active");
      void playScenario(idx);
    });
  });

  // Auto-start first scenario
  void playScenario(0);
})();
