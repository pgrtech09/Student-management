// ============================================================
// Vidya Campus SMS — Core shared JavaScript
// Loaded on every page after config.js
// ============================================================

// Register service worker (PWA — see service-worker.js)
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    const swPath = window.location.pathname.includes('/student/') || window.location.pathname.includes('/incharge/') || window.location.pathname.includes('/hod/')
      ? '../service-worker.js' : 'service-worker.js';
    navigator.serviceWorker.register(swPath).catch((err) => console.warn('SW registration failed:', err));
  });
}

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Path prefix helper — pages inside /student/, /incharge/, /hod/ need "../"
// to reach root-level files (login.html, css/, js/, assets/).
const ROOT = (window.location.pathname.includes('/student/') || window.location.pathname.includes('/incharge/') || window.location.pathname.includes('/hod/')) ? '../' : '';

// ---------- AUTH ----------

async function getSessionProfile() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (!session) return null;
  const { data: profile, error } = await supabaseClient
    .from('profiles').select('*').eq('id', session.user.id).single();
  if (error || !profile) return null;
  return profile;
}

async function requireRole(role) {
  const profile = await getSessionProfile();
  if (!profile || profile.role !== role) {
    window.location.href = ROOT + 'login.html';
    return null;
  }
  return profile;
}

// Login accepts Roll Number / Employee ID / Email — resolve to the real
// email via the resolve_login_email() RPC function, then sign in normally.
async function loginUser(identifier, password) {
  const { data: email, error: lookupErr } = await supabaseClient.rpc('resolve_login_email', { identifier });
  if (lookupErr || !email) throw new Error('No account found for that Roll Number / Employee ID / Email.');

  const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
  if (error) throw new Error(error.message);

  const { data: profile, error: profErr } = await supabaseClient
    .from('profiles').select('*').eq('id', data.user.id).single();
  if (profErr || !profile) throw new Error('Login succeeded but no profile found. Contact your HOD.');
  return profile;
}

async function requestPasswordReset(identifier) {
  const { data: email, error: lookupErr } = await supabaseClient.rpc('resolve_login_email', { identifier });
  if (lookupErr || !email) throw new Error('No account found for that Roll Number / Employee ID / Email.');
  const { error } = await supabaseClient.auth.resetPasswordForEmail(email);
  if (error) throw new Error(error.message);
  return email;
}

async function logout() {
  await supabaseClient.auth.signOut();
  window.location.href = ROOT + 'login.html';
}

// ---------- THEME (light / dark) ----------

function initTheme() {
  const saved = localStorage.getItem('sms_theme') || 'light';
  document.documentElement.setAttribute('data-theme', saved);
}

function toggleTheme() {
  const current = document.documentElement.getAttribute('data-theme') || 'light';
  const next = current === 'light' ? 'dark' : 'light';
  document.documentElement.setAttribute('data-theme', next);
  localStorage.setItem('sms_theme', next);
  const btn = document.getElementById('theme-toggle-btn');
  if (btn) btn.textContent = next === 'dark' ? '☀️' : '🌙';
}

// ---------- TOASTS ----------

function toast(title, message) {
  let container = document.getElementById('toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toast-container';
    document.body.appendChild(container);
  }
  const el = document.createElement('div');
  el.className = 'toast';
  el.innerHTML = `<strong>${title}</strong>${message}`;
  container.appendChild(el);
  setTimeout(() => el.remove(), 6000);
}

// ---------- FORMATTING HELPERS ----------

function fmtDate(d) {
  return new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

function timeAgo(dateStr) {
  const diff = (Date.now() - new Date(dateStr).getTime()) / 1000;
  if (diff < 60) return 'just now';
  if (diff < 3600) return Math.floor(diff / 60) + 'm ago';
  if (diff < 86400) return Math.floor(diff / 3600) + 'h ago';
  return Math.floor(diff / 86400) + 'd ago';
}

function attendanceStatsFrom(rows) {
  const total = rows.length;
  const present = rows.filter(r => r.status === 'present').length;
  const leave = rows.filter(r => r.status === 'leave').length;
  const absent = rows.filter(r => r.status === 'absent').length;
  const pct = total ? Math.round((present / total) * 1000) / 10 : 0;
  // classes needed to reach 75% (simple projection assuming future classes all attended)
  let neededFor75 = 0;
  if (pct < 75 && total > 0) {
    // find smallest n such that (present+n)/(total+n) >= 0.75
    let p = present, t = total;
    while (t > 0 && (p / t) < 0.75 && n_guard(neededFor75)) { p++; t++; neededFor75++; }
  }
  function n_guard(n) { return n < 200; } // safety cap
  return { total, present, absent, leave, percentage: pct, neededFor75 };
}

function attendanceRingSVG(pct, size = 76) {
  const r = (size - 10) / 2;
  const c = 2 * Math.PI * r;
  const offset = c - (pct / 100) * c;
  const color = pct >= 75 ? 'var(--present)' : 'var(--absent)';
  return `
    <div class="ring-wrap" style="width:${size}px;height:${size}px;">
      <svg width="${size}" height="${size}">
        <circle cx="${size/2}" cy="${size/2}" r="${r}" stroke="var(--border)" stroke-width="7" fill="none"/>
        <circle cx="${size/2}" cy="${size/2}" r="${r}" stroke="${color}" stroke-width="7" fill="none"
          stroke-dasharray="${c}" stroke-dashoffset="${offset}" stroke-linecap="round"/>
      </svg>
      <div class="ring-label">${pct}%</div>
    </div>`;
}

function progressBarHTML(pct, color) {
  color = color || (pct >= 75 ? 'var(--present)' : 'var(--absent)');
  return `<div class="progress-bar"><div class="fill" style="width:${Math.min(pct,100)}%;background:${color};"></div></div>`;
}

// ---------- SIMPLE CANVAS CHARTS (no external libraries) ----------

function drawBarChart(canvas, labels, values, opts = {}) {
  const ctx = canvas.getContext('2d');
  const w = canvas.width = canvas.clientWidth * 2;
  const h = canvas.height = canvas.clientHeight * 2;
  ctx.scale(2, 2);
  const cw = canvas.clientWidth, ch = canvas.clientHeight;
  ctx.clearRect(0, 0, cw, ch);
  const max = Math.max(...values, 100);
  const barW = cw / values.length * 0.55;
  const gap = cw / values.length;
  const color = opts.color || '#1B2A4A';
  ctx.font = '11px Inter, sans-serif';
  values.forEach((v, i) => {
    const barH = (v / max) * (ch - 30);
    const x = i * gap + (gap - barW) / 2;
    const y = ch - barH - 20;
    ctx.fillStyle = v >= 75 ? '#2F7A4F' : color;
    ctx.fillRect(x, y, barW, barH);
    ctx.fillStyle = '#6B7280';
    ctx.textAlign = 'center';
    ctx.fillText(labels[i], x + barW / 2, ch - 5);
    ctx.fillStyle = '#1B2A4A';
    ctx.fillText(v + '%', x + barW / 2, y - 5);
  });
}

function drawLineChart(canvas, labels, values, opts = {}) {
  const ctx = canvas.getContext('2d');
  canvas.width = canvas.clientWidth * 2;
  canvas.height = canvas.clientHeight * 2;
  ctx.scale(2, 2);
  const cw = canvas.clientWidth, ch = canvas.clientHeight;
  ctx.clearRect(0, 0, cw, ch);
  const max = 100, min = 0;
  const stepX = cw / Math.max(values.length - 1, 1);
  ctx.strokeStyle = opts.color || '#C9A227';
  ctx.lineWidth = 2;
  ctx.beginPath();
  values.forEach((v, i) => {
    const x = i * stepX;
    const y = ch - 20 - ((v - min) / (max - min)) * (ch - 30);
    if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
  });
  ctx.stroke();
  ctx.fillStyle = '#6B7280';
  ctx.font = '10px Inter, sans-serif';
  ctx.textAlign = 'center';
  labels.forEach((l, i) => ctx.fillText(l, i * stepX, ch - 5));
}

// ---------- CSV EXPORT ("Export Excel") ----------

function exportToCSV(filename, headers, rows) {
  const csvRows = [headers.join(',')];
  rows.forEach(r => {
    csvRows.push(r.map(cell => `"${String(cell ?? '').replace(/"/g, '""')}"`).join(','));
  });
  const blob = new Blob([csvRows.join('\n')], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = filename;
  document.body.appendChild(a); a.click(); document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// ---------- PRINT / "Export PDF" (uses browser's print-to-PDF) ----------

function printReport(titleHtml, bodyHtml) {
  const win = window.open('', '_blank');
  win.document.write(`
    <html><head><title>${titleHtml}</title>
    <style>
      body { font-family: Arial, sans-serif; padding: 30px; color: #1B2A4A; }
      h1 { font-size: 20px; border-bottom: 2px solid #C9A227; padding-bottom: 10px; }
      table { width: 100%; border-collapse: collapse; margin-top: 16px; }
      th, td { border: 1px solid #ccc; padding: 8px; text-align: left; font-size: 13px; }
      th { background: #f5f5f5; }
    </style></head><body>
    <h1>${titleHtml}</h1>
    ${bodyHtml}
    </body></html>
  `);
  win.document.close();
  setTimeout(() => win.print(), 400);
}

// ---------- NOTIFICATIONS (realtime) ----------

let notificationChannel = null;

async function fetchNotifications(profile) {
  let query = supabaseClient.from('notifications').select('*').order('created_at', { ascending: false }).limit(30);
  if (profile.role === 'student') {
    query = query.or(`student_id.eq.${profile.id},and(student_id.is.null,department.eq.${profile.department})`);
  } else {
    query = query.eq('department', profile.department);
  }
  const { data } = await query;
  return data || [];
}

function renderNotificationPanel(notifications) {
  const panel = document.getElementById('notif-panel');
  const badge = document.getElementById('notif-badge');
  if (!panel) return;
  panel.innerHTML = notifications.length ? notifications.map(n => `
    <div class="notif-item">
      <div class="notif-title">${n.title}</div>
      <div>${n.message || ''}</div>
      <div class="notif-time">${timeAgo(n.created_at)}</div>
    </div>`).join('') : '<div class="notif-item muted">No notifications yet.</div>';
  if (badge) {
    const unread = notifications.length;
    badge.textContent = unread > 9 ? '9+' : unread;
    badge.style.display = unread ? 'grid' : 'none';
  }
}

function initNotificationBell(profile) {
  const bell = document.getElementById('notif-bell');
  const panel = document.getElementById('notif-panel');
  if (!bell || !panel) return;

  fetchNotifications(profile).then(renderNotificationPanel);

  bell.addEventListener('click', (e) => {
    e.stopPropagation();
    panel.classList.toggle('open');
  });
  document.addEventListener('click', () => panel.classList.remove('open'));
  panel.addEventListener('click', (e) => e.stopPropagation());

  // Realtime: subscribe to new notifications for this department
  notificationChannel = supabaseClient
    .channel('notifications-' + profile.department)
    .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'notifications', filter: `department=eq.${profile.department}` },
      (payload) => {
        const n = payload.new;
        if (n.student_id && n.student_id !== profile.id) return;
        if (n.section && profile.section && n.section !== profile.section && profile.role !== 'hod') return;
        toast('🔔 ' + n.title, n.message || '');
        fetchNotifications(profile).then(renderNotificationPanel);
      })
    .subscribe();
}

async function pushNotification({ title, message, type, department, section, student_id }) {
  const { error } = await supabaseClient.from('notifications').insert({ title, message, type, department, section, student_id });
  if (error) console.error('Notification insert failed:', error.message);
}
