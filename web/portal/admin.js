// ============================================================
// MediQR Admin Dashboard v2 — JavaScript
// Full analytics: Risk Score, Peak Hours, Growth, Response Time,
// Map (clustering + heatmap), Incident Table, CSV Export
// ============================================================

const SUPABASE_URL = 'https://krpmrkxustljymgnwrzq.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtycG1ya3h1c3RsanltZ253cnpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MjIxNDIsImV4cCI6MjA4NzM5ODE0Mn0.SmP5GhPK9u2K-hpMFmIAwR00T9CzFLEY8ROGeC0m69w';

let sb, allIncidents = [], allProfiles = [], allUsers = [];
let map, markerLayer, heatLayer, currentMapMode = 'markers';
let charts = {};

// ═════════════════════════════════════════════════════════════
// INIT
// ═════════════════════════════════════════════════════════════

async function initApp() {
    if (!window.supabase?.createClient) {
        alert('Failed to load Supabase SDK. Refresh the page.');
        return;
    }
    sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    // Auth + admin check
    const { data: sess } = await sb.auth.getSession();
    if (!sess.session) { window.location.href = 'admin_login.html'; return; }

    const uid = sess.session.user.id;
    const { data: admin } = await sb.from('admin_users').select('id').eq('user_id', uid).single();
    if (!admin) {
        alert('Access denied. Admin role required.');
        await sb.auth.signOut();
        window.location.href = 'admin_login.html';
        return;
    }

    document.getElementById('user-email').textContent = sess.session.user.email;

    // Load all data
    await Promise.all([loadIncidents(), loadProfiles(), loadUsers()]);

    // Hide loading
    document.getElementById('loading-overlay').style.display = 'none';

    // Render all modules
    renderKPIs();
    renderRiskScores();
    renderPeakHours();
    renderGrowthTrend();
    renderResponseTime();
    renderIncidentTable();
    initMap();
    renderUsers();

    // Setup
    setupNav();
    setupFilters();
    setupLogout();
}

// ═════════════════════════════════════════════════════════════
// DATA LOADING
// ═════════════════════════════════════════════════════════════

async function loadIncidents() {
    const { data } = await sb.from('incidents').select('*').order('scan_time', { ascending: false });
    allIncidents = data || [];
}

async function loadProfiles() {
    const { data } = await sb.from('profiles').select('*');
    allProfiles = data || [];
}

async function loadUsers() {
    const { data } = await sb.from('user_roles').select('*');
    allUsers = data || [];
}

function getProfileName(pid) {
    const p = allProfiles.find(p => p.user_id === pid);
    return p?.full_name || 'Unknown';
}

// ── Reverse Geocoding (cached) ──

const geoCache = {};

async function reverseGeocode(lat, lng) {
    const key = Number(lat).toFixed(3) + ',' + Number(lng).toFixed(3);
    if (geoCache[key]) return geoCache[key];
    try {
        const r = await fetch(`https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json&zoom=10`);
        const d = await r.json();
        const a = d.address || {};
        let name = a.city || a.town || a.village || a.county || '';
        if (a.state && name !== a.state) name += (name ? ', ' : '') + a.state;
        geoCache[key] = name || 'Unknown';
        return geoCache[key];
    } catch { return 'Unknown'; }
}

// Get city for incident — use stored city or geocode
async function getCity(inc) {
    if (inc.city) return inc.city;
    if (inc.latitude && inc.longitude) return await reverseGeocode(inc.latitude, inc.longitude);
    return 'Unknown';
}

// ═════════════════════════════════════════════════════════════
// NAVIGATION
// ═════════════════════════════════════════════════════════════

function setupNav() {
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', () => {
            const target = item.dataset.section;
            if (!target) return;
            document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
            item.classList.add('active');
            document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
            document.getElementById('section-' + target).classList.add('active');
            document.querySelector('.sidebar').classList.remove('open');
            if (target === 'map' && map) setTimeout(() => map.invalidateSize(), 100);
        });
    });
    document.getElementById('mobile-toggle').addEventListener('click', () => {
        document.querySelector('.sidebar').classList.toggle('open');
    });
}

function setupLogout() {
    document.getElementById('logout-btn').addEventListener('click', async () => {
        await sb.auth.signOut();
        window.location.href = 'admin_login.html';
    });
}

// ═════════════════════════════════════════════════════════════
// 1️⃣ KPIs
// ═════════════════════════════════════════════════════════════

function renderKPIs() {
    const total = allIncidents.length;
    const today = new Date().toDateString();
    const todayCount = allIncidents.filter(i => new Date(i.scan_time).toDateString() === today).length;
    const pending = allIncidents.filter(i => i.status === 'pending').length;
    const completed = allIncidents.filter(i => i.status === 'completed').length;

    // Avg severity
    const sevs = allIncidents.filter(i => i.severity).map(i => i.severity);
    const avgSev = sevs.length ? (sevs.reduce((a, b) => a + b, 0) / sevs.length).toFixed(1) : '—';

    // Avg response time
    const responseTimes = allIncidents
        .filter(i => i.completed_time && i.scan_time)
        .map(i => (new Date(i.completed_time) - new Date(i.scan_time)) / 60000); // minutes
    const avgResp = responseTimes.length
        ? formatDuration(responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length)
        : '—';

    document.getElementById('kpi-patients').textContent = allProfiles.length;
    document.getElementById('kpi-total').textContent = total;
    document.getElementById('kpi-today').textContent = todayCount;
    document.getElementById('kpi-pending').textContent = pending;
    document.getElementById('kpi-completed').textContent = completed;
    document.getElementById('kpi-severity').textContent = avgSev;
    document.getElementById('kpi-response').textContent = avgResp;
}

function formatDuration(mins) {
    if (mins < 1) return '<1m';
    if (mins < 60) return Math.round(mins) + 'm';
    const h = Math.floor(mins / 60);
    const m = Math.round(mins % 60);
    return h + 'h ' + m + 'm';
}

// ═════════════════════════════════════════════════════════════
// 2️⃣ RISK SCORE MODULE
// ═════════════════════════════════════════════════════════════

async function renderRiskScores() {
    const now = new Date();
    const d7 = new Date(now - 7 * 86400000);
    const d14 = new Date(now - 14 * 86400000);

    // Group by city
    const cityMap = {};

    for (const inc of allIncidents) {
        const city = await getCity(inc);
        if (!cityMap[city]) cityMap[city] = { total: 0, sevSum: 0, sevCount: 0, last7: 0, prev7: 0 };
        const c = cityMap[city];
        c.total++;
        if (inc.severity) { c.sevSum += inc.severity; c.sevCount++; }
        const t = new Date(inc.scan_time);
        if (t >= d7) c.last7++;
        else if (t >= d14) c.prev7++;
    }

    // Calculate risk scores
    const maxFreq = Math.max(...Object.values(cityMap).map(c => c.total), 1);

    const risks = Object.entries(cityMap).map(([city, c]) => {
        const normFreq = (c.total / maxFreq) * 100;
        const avgSev = c.sevCount ? (c.sevSum / c.sevCount) / 5 * 100 : 0;
        const growth = c.prev7 > 0 ? ((c.last7 - c.prev7) / c.prev7) * 100 : (c.last7 > 0 ? 100 : 0);
        const normGrowth = Math.min(Math.max(growth, -100), 100);
        const riskScore = (normFreq * 0.5) + (avgSev * 0.3) + (Math.max(normGrowth, 0) * 0.2);

        return { city, total: c.total, avgSev: c.sevCount ? (c.sevSum / c.sevCount).toFixed(1) : '—', growth: growth.toFixed(0), risk: Math.round(riskScore) };
    }).sort((a, b) => b.risk - a.risk);

    const tbody = document.getElementById('risk-tbody');
    tbody.innerHTML = risks.slice(0, 15).map((r, i) => {
        const badgeClass = r.risk > 60 ? 'risk-high' : r.risk > 30 ? 'risk-medium' : 'risk-low';
        const growthIcon = r.growth > 0 ? '↑' : r.growth < 0 ? '↓' : '—';
        return `<tr>
      <td style="font-weight:600">${i + 1}</td>
      <td style="font-weight:600">${r.city}</td>
      <td>${r.total}</td>
      <td>${r.avgSev}</td>
      <td>${growthIcon} ${Math.abs(r.growth)}%</td>
      <td><span class="risk-badge ${badgeClass}">${r.risk}</span></td>
    </tr>`;
    }).join('');
}

// ═════════════════════════════════════════════════════════════
// 3️⃣ PEAK HOUR ANALYTICS
// ═════════════════════════════════════════════════════════════

function renderPeakHours() {
    const ctx = document.getElementById('chart-peak').getContext('2d');
    const hours = new Array(24).fill(0);

    allIncidents.forEach(i => {
        const h = new Date(i.scan_time).getHours();
        hours[h]++;
    });

    const maxHour = hours.indexOf(Math.max(...hours));
    const colors = hours.map((_, i) => i === maxHour ? '#ef4444' : 'rgba(99,102,241,0.6)');

    if (charts.peak) charts.peak.destroy();
    charts.peak = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: hours.map((_, i) => i.toString().padStart(2, '0') + ':00'),
            datasets: [{ data: hours, backgroundColor: colors, borderRadius: 4 }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { display: false },
                title: { display: true, text: `Peak Hour: ${maxHour.toString().padStart(2, '0')}:00`, color: '#ef4444', font: { size: 13, weight: 600 } }
            },
            scales: {
                y: { beginAtZero: true, ticks: { precision: 0, color: '#9ca3af' }, grid: { color: 'rgba(0,0,0,0.04)' } },
                x: { ticks: { color: '#9ca3af', font: { size: 10 } }, grid: { display: false } }
            }
        }
    });
}

// ═════════════════════════════════════════════════════════════
// 4️⃣ GROWTH TREND
// ═════════════════════════════════════════════════════════════

function renderGrowthTrend() {
    const now = new Date();
    const d7 = new Date(now - 7 * 86400000);
    const d14 = new Date(now - 14 * 86400000);

    const last7 = allIncidents.filter(i => new Date(i.scan_time) >= d7).length;
    const prev7 = allIncidents.filter(i => { const t = new Date(i.scan_time); return t >= d14 && t < d7; }).length;

    const growth = prev7 > 0 ? ((last7 - prev7) / prev7 * 100).toFixed(1) : (last7 > 0 ? '100.0' : '0.0');
    const isUp = parseFloat(growth) > 0;

    document.getElementById('growth-last7').textContent = last7;
    document.getElementById('growth-prev7').textContent = prev7;
    document.getElementById('growth-pct').innerHTML =
        `<span style="color:${isUp ? 'var(--red)' : 'var(--green)'};font-size:28px;font-weight:800">${isUp ? '↑' : '↓'} ${Math.abs(growth)}%</span>`;

    // 14-day line chart
    const ctx = document.getElementById('chart-growth').getContext('2d');
    const days = [], counts = [];
    for (let i = 13; i >= 0; i--) {
        const d = new Date(); d.setDate(d.getDate() - i);
        days.push(d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }));
        counts.push(allIncidents.filter(inc => new Date(inc.scan_time).toDateString() === d.toDateString()).length);
    }

    if (charts.growth) charts.growth.destroy();
    charts.growth = new Chart(ctx, {
        type: 'line',
        data: {
            labels: days,
            datasets: [{
                data: counts, borderColor: '#6366f1', backgroundColor: 'rgba(99,102,241,0.08)',
                fill: true, tension: 0.4, pointRadius: 3, pointBackgroundColor: '#6366f1', borderWidth: 2,
            }]
        },
        options: {
            responsive: true,
            plugins: { legend: { display: false } },
            scales: {
                y: { beginAtZero: true, ticks: { precision: 0, color: '#9ca3af' }, grid: { color: 'rgba(0,0,0,0.04)' } },
                x: { ticks: { color: '#9ca3af', font: { size: 10 } }, grid: { display: false } }
            }
        }
    });
}

// ═════════════════════════════════════════════════════════════
// 5️⃣ RESPONSE TIME ANALYTICS
// ═════════════════════════════════════════════════════════════

async function renderResponseTime() {
    const completed = allIncidents.filter(i => i.completed_time && i.scan_time);
    if (completed.length === 0) {
        document.getElementById('resp-fastest-city').textContent = '—';
        document.getElementById('resp-fastest-val').textContent = 'No data';
        document.getElementById('resp-slowest-city').textContent = '—';
        document.getElementById('resp-slowest-val').textContent = 'No data';
        return;
    }

    // Per city
    const cityResp = {};
    for (const inc of completed) {
        const city = (await getCity(inc)).split(',')[0];
        const mins = (new Date(inc.completed_time) - new Date(inc.scan_time)) / 60000;
        if (!cityResp[city]) cityResp[city] = [];
        cityResp[city].push(mins);
    }

    const cityAvgs = Object.entries(cityResp).map(([city, times]) => ({
        city, avg: times.reduce((a, b) => a + b, 0) / times.length
    })).sort((a, b) => a.avg - b.avg);

    if (cityAvgs.length > 0) {
        document.getElementById('resp-fastest-city').textContent = cityAvgs[0].city;
        document.getElementById('resp-fastest-val').textContent = formatDuration(cityAvgs[0].avg);
        document.getElementById('resp-slowest-city').textContent = cityAvgs[cityAvgs.length - 1].city;
        document.getElementById('resp-slowest-val').textContent = formatDuration(cityAvgs[cityAvgs.length - 1].avg);
    }

    // 14-day response time trend
    const ctx = document.getElementById('chart-response').getContext('2d');
    const days = [], avgs = [];
    for (let i = 13; i >= 0; i--) {
        const d = new Date(); d.setDate(d.getDate() - i);
        const ds = d.toDateString();
        const dayIncs = completed.filter(inc => new Date(inc.completed_time).toDateString() === ds);
        days.push(d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }));
        if (dayIncs.length) {
            const avg = dayIncs.reduce((sum, inc) => sum + (new Date(inc.completed_time) - new Date(inc.scan_time)) / 60000, 0) / dayIncs.length;
            avgs.push(Math.round(avg));
        } else {
            avgs.push(null);
        }
    }

    if (charts.response) charts.response.destroy();
    charts.response = new Chart(ctx, {
        type: 'line',
        data: {
            labels: days,
            datasets: [{
                data: avgs, borderColor: '#10b981', backgroundColor: 'rgba(16,185,129,0.08)',
                fill: true, tension: 0.4, pointRadius: 3, pointBackgroundColor: '#10b981', borderWidth: 2,
                spanGaps: true,
            }]
        },
        options: {
            responsive: true,
            plugins: { legend: { display: false } },
            scales: {
                y: { beginAtZero: true, title: { display: true, text: 'Minutes', color: '#9ca3af' }, ticks: { color: '#9ca3af' }, grid: { color: 'rgba(0,0,0,0.04)' } },
                x: { ticks: { color: '#9ca3af', font: { size: 10 } }, grid: { display: false } }
            }
        }
    });
}

// ═════════════════════════════════════════════════════════════
// 6️⃣ + 7️⃣ MAP (Clustering + Heatmap)
// ═════════════════════════════════════════════════════════════

function initMap() {
    map = L.map('map').setView([20.5937, 78.9629], 5);

    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
        attribution: '© OpenStreetMap © CARTO', maxZoom: 18,
    }).addTo(map);

    // Marker cluster layer
    markerLayer = L.markerClusterGroup({
        maxClusterRadius: 50,
        spiderfyOnMaxZoom: true,
        showCoverageOnHover: false,
    });

    // Heatmap data
    const heatData = [];
    const sevColors = { 1: '#10b981', 2: '#10b981', 3: '#f59e0b', 4: '#ef4444', 5: '#ef4444' };

    allIncidents.filter(i => i.latitude && i.longitude).forEach(i => {
        const lat = Number(i.latitude), lng = Number(i.longitude);
        const color = sevColors[i.severity] || '#6366f1';
        const name = getProfileName(i.patient_id);
        const date = new Date(i.scan_time).toLocaleString('en-IN', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });

        const marker = L.circleMarker([lat, lng], {
            radius: 7, fillColor: color, fillOpacity: 0.85,
            color: '#fff', weight: 1.5,
        });

        marker.bindPopup(`
      <div style="font-family:sans-serif;font-size:13px;min-width:170px">
        <b>${name}</b><br>
        <span style="color:#888">Severity:</span> ${'🔴'.repeat(i.severity || 0)}${'⚪'.repeat(5 - (i.severity || 0))}<br>
        <span style="color:#888">Type:</span> ${i.incident_type || '—'}<br>
        <span style="color:#888">Date:</span> ${date}<br>
        <span style="color:#888">City:</span> ${i.city || '—'}
      </div>
    `);

        markerLayer.addLayer(marker);
        const intensity = (i.severity || 1) / 5;
        heatData.push([lat, lng, intensity]);
    });

    // Heatmap layer
    if (typeof L.heatLayer === 'function') {
        heatLayer = L.heatLayer(heatData, { radius: 25, blur: 20, maxZoom: 12 });
    }

    // Default: show markers
    map.addLayer(markerLayer);

    // Fit bounds
    if (allIncidents.filter(i => i.latitude).length > 0) {
        try { map.fitBounds(markerLayer.getBounds().pad(0.2)); } catch { }
    }

    // Toggle buttons
    document.getElementById('btn-markers').addEventListener('click', () => setMapMode('markers'));
    document.getElementById('btn-heatmap').addEventListener('click', () => setMapMode('heatmap'));
}

function setMapMode(mode) {
    currentMapMode = mode;
    document.getElementById('btn-markers').classList.toggle('active', mode === 'markers');
    document.getElementById('btn-heatmap').classList.toggle('active', mode === 'heatmap');

    if (mode === 'markers') {
        if (heatLayer) map.removeLayer(heatLayer);
        map.addLayer(markerLayer);
    } else {
        map.removeLayer(markerLayer);
        if (heatLayer) map.addLayer(heatLayer);
    }
}

// ═════════════════════════════════════════════════════════════
// 8️⃣ INCIDENT TABLE
// ═════════════════════════════════════════════════════════════

function setupFilters() {
    ['filter-search', 'filter-city'].forEach(id =>
        document.getElementById(id).addEventListener('input', renderIncidentTable));
    ['filter-status', 'filter-severity', 'filter-date-from', 'filter-date-to'].forEach(id =>
        document.getElementById(id).addEventListener('change', renderIncidentTable));
}

function getFilteredIncidents() {
    const search = document.getElementById('filter-search').value.toLowerCase();
    const status = document.getElementById('filter-status').value;
    const severity = document.getElementById('filter-severity').value;
    const city = document.getElementById('filter-city').value.toLowerCase();
    const dateFrom = document.getElementById('filter-date-from').value;
    const dateTo = document.getElementById('filter-date-to').value;

    return allIncidents.filter(i => {
        const name = getProfileName(i.patient_id).toLowerCase();
        if (search && !name.includes(search)) return false;
        if (status && i.status !== status) return false;
        if (severity && i.severity !== parseInt(severity)) return false;
        if (city && !(i.city || '').toLowerCase().includes(city)) return false;
        if (dateFrom && new Date(i.scan_time) < new Date(dateFrom)) return false;
        if (dateTo && new Date(i.scan_time) > new Date(dateTo + 'T23:59:59')) return false;
        return true;
    });
}

function renderIncidentTable() {
    const filtered = getFilteredIncidents();
    const tbody = document.getElementById('incident-tbody');

    tbody.innerHTML = filtered.map(i => {
        const name = getProfileName(i.patient_id);
        const date = new Date(i.scan_time).toLocaleString('en-IN', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
        const sev = i.severity ? '🔴'.repeat(i.severity) + '⚪'.repeat(5 - i.severity) : '—';

        return `<tr>
      <td style="font-family:monospace;font-size:12px;color:var(--text-muted)">${i.id.substring(0, 8)}…</td>
      <td>${name}</td>
      <td>${i.city || '—'}</td>
      <td>${date}</td>
      <td><span class="severity-dots">${sev}</span></td>
      <td>${i.incident_type || '—'}</td>
      <td><span class="badge badge-${i.status}">${i.status}</span></td>
    </tr>`;
    }).join('');

    document.getElementById('table-count').textContent = `${filtered.length} incident${filtered.length !== 1 ? 's' : ''}`;
}

// ═════════════════════════════════════════════════════════════
// 9️⃣ CSV EXPORT
// ═════════════════════════════════════════════════════════════

function exportCSV() {
    const filtered = getFilteredIncidents();
    const headers = ['ID', 'Patient', 'City', 'Date', 'Severity', 'Type', 'Status', 'Latitude', 'Longitude'];

    const rows = filtered.map(i => [
        i.id,
        getProfileName(i.patient_id),
        i.city || '',
        new Date(i.scan_time).toISOString(),
        i.severity || '',
        i.incident_type || '',
        i.status,
        i.latitude || '',
        i.longitude || '',
    ]);

    const csv = [headers, ...rows].map(r => r.map(v => `"${String(v).replace(/"/g, '""')}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `mediqr_incidents_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
}

// ═════════════════════════════════════════════════════════════
// USER MANAGEMENT
// ═════════════════════════════════════════════════════════════

function renderUsers() {
    const container = document.getElementById('user-list');
    container.innerHTML = allUsers.map(u => {
        const profile = allProfiles.find(p => p.user_id === u.user_id);
        const name = profile?.full_name || 'Unknown';
        const roleBadge = `<span class="badge badge-${u.role}">${u.role}</span>`;

        let actions = '';
        if (u.role === 'patient') {
            actions = `
        <button class="role-btn role-btn-paramedic" onclick="changeRole('${u.user_id}','paramedic')">→ Paramedic</button>
        <button class="role-btn role-btn-admin" onclick="changeRole('${u.user_id}','admin')">→ Admin</button>`;
        } else if (u.role === 'paramedic') {
            actions = `
        <button class="role-btn role-btn-admin" onclick="changeRole('${u.user_id}','admin')">→ Admin</button>
        <button class="role-btn role-btn-remove" onclick="changeRole('${u.user_id}','patient')">→ Patient</button>`;
        } else if (u.role === 'admin') {
            actions = `<button class="role-btn role-btn-remove" onclick="changeRole('${u.user_id}','patient')">→ Patient</button>`;
        }

        return `<div class="user-card">
      <div><div class="user-email">${name}</div><div class="user-meta">${u.user_id.substring(0, 8)}… · ${roleBadge}</div></div>
      <div>${actions}</div>
    </div>`;
    }).join('');
}

async function changeRole(userId, newRole) {
    if (!confirm(`Change role to "${newRole}"?`)) return;
    await sb.from('user_roles').update({ role: newRole }).eq('user_id', userId);
    if (newRole === 'admin') {
        const profile = allProfiles.find(p => p.user_id === userId);
        await sb.from('admin_users').upsert({ user_id: userId, name: profile?.full_name || '', email: '' }, { onConflict: 'user_id' });
    } else {
        await sb.from('admin_users').delete().eq('user_id', userId);
    }
    await loadUsers();
    renderUsers();
}

async function addNewUser() {
    const email = document.getElementById('new-user-email').value.trim();
    const password = document.getElementById('new-user-password').value;
    const name = document.getElementById('new-user-name').value.trim();
    const role = document.getElementById('new-user-role').value;
    const $msg = document.getElementById('add-user-msg');
    const $btn = document.getElementById('add-user-btn');

    if (!email || !password || !name) { showMsg($msg, '⚠️ Fill all fields.', '#f59e0b'); return; }
    if (password.length < 6) { showMsg($msg, '⚠️ Password min 6 chars.', '#f59e0b'); return; }

    $btn.disabled = true; $btn.textContent = 'Creating…'; $msg.style.display = 'none';

    try {
        const { data, error } = await sb.auth.signUp({ email, password, options: { data: { full_name: name } } });
        if (error) { showMsg($msg, '❌ ' + error.message, '#ef4444'); $btn.disabled = false; $btn.textContent = 'Add User'; return; }

        const uid = data.user?.id;
        if (uid && role !== 'patient') {
            await new Promise(r => setTimeout(r, 1000));
            await sb.from('user_roles').update({ role }).eq('user_id', uid);
        }
        if (uid && role === 'admin') {
            await sb.from('admin_users').upsert({ user_id: uid, name, email }, { onConflict: 'user_id' });
        }

        await sb.auth.refreshSession();
        showMsg($msg, `✅ ${email} created as ${role}!`, '#10b981');
        document.getElementById('new-user-email').value = '';
        document.getElementById('new-user-password').value = '';
        document.getElementById('new-user-name').value = '';
        await loadUsers(); renderUsers();
    } catch (err) { showMsg($msg, '❌ ' + err.message, '#ef4444'); }

    $btn.disabled = false; $btn.textContent = 'Add User';
}

function showMsg(el, text, color) {
    el.innerHTML = text; el.style.color = color; el.style.display = 'block';
}

// ═════════════════════════════════════════════════════════════
// START
// ═════════════════════════════════════════════════════════════

document.addEventListener('DOMContentLoaded', initApp);
