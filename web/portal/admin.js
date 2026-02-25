// ============================================================
// MediQR Admin Dashboard — JavaScript
// ============================================================

const SUPABASE_URL = 'https://krpmrkxustljymgnwrzq.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtycG1ya3h1c3RsanltZ253cnpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MjIxNDIsImV4cCI6MjA4NzM5ODE0Mn0.SmP5GhPK9u2K-hpMFmIAwR00T9CzFLEY8ROGeC0m69w';

let sb;
let allIncidents = [];
let allProfiles = [];
let allUsers = [];
let map;
let markers = [];

// ── Init ─────────────────────────────────────────────────────

async function initApp() {
    if (!window.supabase || !window.supabase.createClient) {
        alert('Failed to load Supabase SDK. Refresh the page.');
        return;
    }

    sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    // Auth check
    const { data: sessionData } = await sb.auth.getSession();
    if (!sessionData.session) {
        window.location.href = 'admin_login.html';
        return;
    }

    // Admin check
    const userId = sessionData.session.user.id;
    const { data: adminData } = await sb.from('admin_users').select('id').eq('user_id', userId).single();

    if (!adminData) {
        alert('Access denied. Admin role required.');
        await sb.auth.signOut();
        window.location.href = 'admin_login.html';
        return;
    }

    // Set user email
    document.getElementById('user-email').textContent = sessionData.session.user.email;

    // Load data
    await Promise.all([loadIncidents(), loadProfiles(), loadUsers()]);

    // Hide loading
    document.getElementById('loading-overlay').style.display = 'none';

    // Render everything
    renderKPIs();
    renderIncidentTable();
    renderCharts();
    initMap();
    renderUsers();

    // Setup navigation
    setupNav();
    setupFilters();
    setupLogout();
}

// ── Data Loading ─────────────────────────────────────────────

async function loadIncidents() {
    const { data, error } = await sb.from('incidents').select('*').order('scan_time', { ascending: false });
    if (error) { console.error('Incidents error:', error.message); return; }
    allIncidents = data || [];
}

async function loadProfiles() {
    const { data, error } = await sb.from('profiles').select('*');
    if (error) { console.error('Profiles error:', error.message); return; }
    allProfiles = data || [];
}

async function loadUsers() {
    const { data, error } = await sb.from('user_roles').select('*');
    if (error) { console.error('Users error:', error.message); return; }
    allUsers = data || [];
}

function getProfileName(patientId) {
    const p = allProfiles.find(p => p.user_id === patientId);
    return p ? p.full_name || 'Unknown' : 'Unknown';
}

// ── Reverse Geocoding ────────────────────────────────────────

const geoCache = {};

async function reverseGeocode(lat, lng) {
    const key = Number(lat).toFixed(3) + ',' + Number(lng).toFixed(3);
    if (geoCache[key]) return geoCache[key];
    try {
        const resp = await fetch(`https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json&zoom=10`);
        const data = await resp.json();
        const addr = data.address || {};
        let name = addr.city || addr.town || addr.village || addr.county || '';
        if (addr.state && name !== addr.state) name += (name ? ', ' : '') + addr.state;
        geoCache[key] = name || 'Unknown';
        return geoCache[key];
    } catch (e) { return 'Unknown'; }
}

// ── Navigation ───────────────────────────────────────────────

function setupNav() {
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', () => {
            const target = item.dataset.section;
            if (!target) return;

            document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
            item.classList.add('active');

            document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
            document.getElementById('section-' + target).classList.add('active');

            // Close sidebar on mobile
            document.querySelector('.sidebar').classList.remove('open');

            // Resize map if switching to map section
            if (target === 'map' && map) setTimeout(() => map.invalidateSize(), 100);
        });
    });

    // Mobile toggle
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

// ── KPIs ─────────────────────────────────────────────────────

function renderKPIs() {
    const total = allIncidents.length;
    const today = new Date().toDateString();
    const todayCount = allIncidents.filter(i => new Date(i.scan_time).toDateString() === today).length;
    const pending = allIncidents.filter(i => i.status === 'pending').length;
    const completed = allIncidents.filter(i => i.status === 'completed').length;

    const severities = allIncidents.filter(i => i.severity).map(i => i.severity);
    const avgSeverity = severities.length ? (severities.reduce((a, b) => a + b, 0) / severities.length).toFixed(1) : '—';

    // Avg response time: diff between scan_time and when status changed to completed
    // Since we don't track completed_at, we'll show '—' for now
    const avgResponse = '—';

    document.getElementById('kpi-patients').textContent = allProfiles.length;
    document.getElementById('kpi-total').textContent = total;
    document.getElementById('kpi-today').textContent = todayCount;
    document.getElementById('kpi-pending').textContent = pending;
    document.getElementById('kpi-completed').textContent = completed;
    document.getElementById('kpi-severity').textContent = avgSeverity;
    document.getElementById('kpi-response').textContent = avgResponse;
}

// ── Incident Table ───────────────────────────────────────────

function setupFilters() {
    document.getElementById('filter-search').addEventListener('input', renderIncidentTable);
    document.getElementById('filter-status').addEventListener('change', renderIncidentTable);
    document.getElementById('filter-severity').addEventListener('change', renderIncidentTable);
    document.getElementById('filter-date-from').addEventListener('change', renderIncidentTable);
    document.getElementById('filter-date-to').addEventListener('change', renderIncidentTable);
}

function renderIncidentTable() {
    const search = document.getElementById('filter-search').value.toLowerCase();
    const statusFilter = document.getElementById('filter-status').value;
    const severityFilter = document.getElementById('filter-severity').value;
    const dateFrom = document.getElementById('filter-date-from').value;
    const dateTo = document.getElementById('filter-date-to').value;

    let filtered = allIncidents.filter(i => {
        const name = getProfileName(i.patient_id).toLowerCase();
        if (search && !name.includes(search)) return false;
        if (statusFilter && i.status !== statusFilter) return false;
        if (severityFilter && i.severity !== parseInt(severityFilter)) return false;
        if (dateFrom && new Date(i.scan_time) < new Date(dateFrom)) return false;
        if (dateTo && new Date(i.scan_time) > new Date(dateTo + 'T23:59:59')) return false;
        return true;
    });

    const tbody = document.getElementById('incident-tbody');
    tbody.innerHTML = filtered.map(i => {
        const name = getProfileName(i.patient_id);
        const date = new Date(i.scan_time).toLocaleString('en-IN', {
            day: 'numeric', month: 'short', year: 'numeric',
            hour: '2-digit', minute: '2-digit'
        });
        const severity = i.severity
            ? '<span class="severity-dots">' + '🔴'.repeat(i.severity) + '⚪'.repeat(5 - i.severity) + '</span>'
            : '—';
        const status = `<span class="badge badge-${i.status}">${i.status}</span>`;
        const type = i.incident_type || '—';
        const shortId = i.id.substring(0, 8) + '…';

        return `<tr>
      <td style="font-family:monospace;font-size:12px;color:var(--text-muted)">${shortId}</td>
      <td>${name}</td>
      <td class="city-cell" data-lat="${i.latitude || ''}" data-lng="${i.longitude || ''}">…</td>
      <td>${date}</td>
      <td>${severity}</td>
      <td>${type}</td>
      <td>${status}</td>
    </tr>`;
    }).join('');

    // Resolve city names
    document.querySelectorAll('.city-cell').forEach(async cell => {
        const lat = cell.dataset.lat;
        const lng = cell.dataset.lng;
        if (lat && lng) {
            cell.textContent = await reverseGeocode(lat, lng);
        } else {
            cell.textContent = '—';
        }
    });
}

// ── Charts ───────────────────────────────────────────────────

let charts = {};

function renderCharts() {
    renderLineChart();
    renderPieChart();
    renderTypeChart();
    renderCityChart();
}

function renderLineChart() {
    const ctx = document.getElementById('chart-line').getContext('2d');

    // Last 7 days
    const days = [];
    const counts = [];
    for (let i = 6; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        const dateStr = d.toDateString();
        const label = d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
        days.push(label);
        counts.push(allIncidents.filter(inc => new Date(inc.scan_time).toDateString() === dateStr).length);
    }

    if (charts.line) charts.line.destroy();
    charts.line = new Chart(ctx, {
        type: 'line',
        data: {
            labels: days,
            datasets: [{
                label: 'Incidents',
                data: counts,
                borderColor: '#6366f1',
                backgroundColor: 'rgba(99,102,241,0.1)',
                fill: true,
                tension: 0.4,
                pointRadius: 4,
                pointBackgroundColor: '#6366f1',
            }]
        },
        options: {
            responsive: true,
            plugins: { legend: { display: false } },
            scales: {
                y: { beginAtZero: true, ticks: { precision: 0, color: '#555' }, grid: { color: 'rgba(255,255,255,0.04)' } },
                x: { ticks: { color: '#555' }, grid: { display: false } }
            }
        }
    });
}

function renderPieChart() {
    const ctx = document.getElementById('chart-pie').getContext('2d');

    const sevCounts = [0, 0, 0, 0, 0];
    allIncidents.forEach(i => {
        if (i.severity >= 1 && i.severity <= 5) sevCounts[i.severity - 1]++;
    });

    if (charts.pie) charts.pie.destroy();
    charts.pie = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Sev 1', 'Sev 2', 'Sev 3', 'Sev 4', 'Sev 5'],
            datasets: [{
                data: sevCounts,
                backgroundColor: ['#3b82f6', '#22d3ee', '#fbbf24', '#f97316', '#ef4444'],
                borderWidth: 0,
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { position: 'bottom', labels: { color: '#888', padding: 16 } }
            }
        }
    });
}

function renderTypeChart() {
    const ctx = document.getElementById('chart-type').getContext('2d');

    const typeCounts = {};
    allIncidents.forEach(i => {
        if (i.incident_type) {
            typeCounts[i.incident_type] = (typeCounts[i.incident_type] || 0) + 1;
        }
    });

    const labels = Object.keys(typeCounts);
    const data = Object.values(typeCounts);

    if (charts.type) charts.type.destroy();
    charts.type = new Chart(ctx, {
        type: 'bar',
        data: {
            labels,
            datasets: [{
                label: 'Count',
                data,
                backgroundColor: 'rgba(99,102,241,0.6)',
                borderRadius: 6,
            }]
        },
        options: {
            responsive: true,
            plugins: { legend: { display: false } },
            scales: {
                y: { beginAtZero: true, ticks: { precision: 0, color: '#555' }, grid: { color: 'rgba(255,255,255,0.04)' } },
                x: { ticks: { color: '#555' }, grid: { display: false } }
            }
        }
    });
}

async function renderCityChart() {
    const ctx = document.getElementById('chart-city').getContext('2d');

    // Get city for each incident
    const cityCounts = {};
    const promises = allIncidents
        .filter(i => i.latitude && i.longitude)
        .map(async i => {
            const city = await reverseGeocode(i.latitude, i.longitude);
            const name = city.split(',')[0] || 'Unknown';
            cityCounts[name] = (cityCounts[name] || 0) + 1;
        });

    await Promise.all(promises);

    // Sort top 8
    const sorted = Object.entries(cityCounts).sort((a, b) => b[1] - a[1]).slice(0, 8);

    if (charts.city) charts.city.destroy();
    charts.city = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: sorted.map(s => s[0]),
            datasets: [{
                label: 'Incidents',
                data: sorted.map(s => s[1]),
                backgroundColor: 'rgba(168,85,247,0.6)',
                borderRadius: 6,
            }]
        },
        options: {
            indexAxis: 'y',
            responsive: true,
            plugins: { legend: { display: false } },
            scales: {
                x: { beginAtZero: true, ticks: { precision: 0, color: '#555' }, grid: { color: 'rgba(255,255,255,0.04)' } },
                y: { ticks: { color: '#888' }, grid: { display: false } }
            }
        }
    });
}

// ── Map ──────────────────────────────────────────────────────

function initMap() {
    map = L.map('map').setView([20.5937, 78.9629], 5); // India center

    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
        attribution: '© OpenStreetMap © CARTO',
        maxZoom: 18,
    }).addTo(map);

    renderMapMarkers();

    // Severity filter
    document.getElementById('map-severity').addEventListener('change', renderMapMarkers);
}

function renderMapMarkers() {
    // Clear existing
    markers.forEach(m => map.removeLayer(m));
    markers = [];

    const severityFilter = document.getElementById('map-severity').value;

    const filtered = allIncidents.filter(i => {
        if (!i.latitude || !i.longitude) return false;
        if (severityFilter && i.severity !== parseInt(severityFilter)) return false;
        return true;
    });

    const sevColors = { 1: '#3b82f6', 2: '#22d3ee', 3: '#fbbf24', 4: '#f97316', 5: '#ef4444' };

    filtered.forEach(i => {
        const name = getProfileName(i.patient_id);
        const color = sevColors[i.severity] || '#6366f1';
        const date = new Date(i.scan_time).toLocaleString('en-IN', {
            day: 'numeric', month: 'short', year: 'numeric',
            hour: '2-digit', minute: '2-digit'
        });

        const marker = L.circleMarker([Number(i.latitude), Number(i.longitude)], {
            radius: 8,
            fillColor: color,
            fillOpacity: 0.8,
            color: '#fff',
            weight: 1.5,
        }).addTo(map);

        marker.bindPopup(`
      <div style="font-family:sans-serif;font-size:13px;min-width:160px">
        <b>${name}</b><br>
        <span style="color:#888">Severity:</span> ${'🔴'.repeat(i.severity || 0)}${'⚪'.repeat(5 - (i.severity || 0))}<br>
        <span style="color:#888">Type:</span> ${i.incident_type || '—'}<br>
        <span style="color:#888">Date:</span> ${date}<br>
        <span style="color:#888">Status:</span> ${i.status}
      </div>
    `);

        markers.push(marker);
    });

    // Fit bounds
    if (markers.length > 0) {
        const group = L.featureGroup(markers);
        map.fitBounds(group.getBounds().pad(0.2));
    }
}

// ── User Management ──────────────────────────────────────────

function renderUsers() {
    const container = document.getElementById('user-list');

    // Combine user roles with profiles for email lookup
    container.innerHTML = allUsers.map(u => {
        const profile = allProfiles.find(p => p.user_id === u.user_id);
        const name = profile ? profile.full_name : 'Unknown';
        const roleBadge = `<span class="badge badge-${u.role}">${u.role}</span>`;

        let actions = '';
        if (u.role === 'patient') {
            actions = `
        <button class="role-btn role-btn-paramedic" onclick="changeRole('${u.user_id}', 'paramedic')">→ Paramedic</button>
        <button class="role-btn role-btn-admin" onclick="changeRole('${u.user_id}', 'admin')">→ Admin</button>
      `;
        } else if (u.role === 'paramedic') {
            actions = `
        <button class="role-btn role-btn-admin" onclick="changeRole('${u.user_id}', 'admin')">→ Admin</button>
        <button class="role-btn role-btn-remove" onclick="changeRole('${u.user_id}', 'patient')">→ Patient</button>
      `;
        } else if (u.role === 'admin') {
            actions = `<button class="role-btn role-btn-remove" onclick="changeRole('${u.user_id}', 'patient')">→ Patient</button>`;
        }

        return `
      <div class="user-card">
        <div>
          <div class="user-email">${name}</div>
          <div class="user-meta">${u.user_id.substring(0, 8)}… · ${roleBadge}</div>
        </div>
        <div>${actions}</div>
      </div>
    `;
    }).join('');
}

async function changeRole(userId, newRole) {
    if (!confirm(`Change this user's role to "${newRole}"?`)) return;

    const { error } = await sb.from('user_roles').update({ role: newRole }).eq('user_id', userId);

    if (error) {
        alert('Failed to update role: ' + error.message);
        return;
    }

    // Refresh
    await loadUsers();
    renderUsers();
}

// ── Add New User ─────────────────────────────────────────────

async function addNewUser() {
    const email = document.getElementById('new-user-email').value.trim();
    const password = document.getElementById('new-user-password').value;
    const name = document.getElementById('new-user-name').value.trim();
    const role = document.getElementById('new-user-role').value;
    const $msg = document.getElementById('add-user-msg');
    const $btn = document.getElementById('add-user-btn');

    if (!email || !password || !name) {
        $msg.textContent = '⚠️ Please fill in all fields.';
        $msg.style.color = '#fbbf24';
        $msg.style.display = 'block';
        return;
    }

    if (password.length < 6) {
        $msg.textContent = '⚠️ Password must be at least 6 characters.';
        $msg.style.color = '#fbbf24';
        $msg.style.display = 'block';
        return;
    }

    $btn.disabled = true;
    $btn.textContent = 'Creating…';
    $msg.style.display = 'none';

    try {
        // Save current admin session
        const { data: currentSession } = await sb.auth.getSession();
        const adminEmail = currentSession.session.user.email;

        // Create the new user via signUp
        const { data: signUpData, error: signUpError } = await sb.auth.signUp({
            email: email,
            password: password,
            options: { data: { full_name: name } }
        });

        if (signUpError) {
            $msg.textContent = '❌ ' + signUpError.message;
            $msg.style.color = '#e63946';
            $msg.style.display = 'block';
            $btn.disabled = false;
            $btn.textContent = 'Add User';
            return;
        }

        const newUserId = signUpData.user?.id;

        // Update the role if not patient (patient is auto-assigned by trigger)
        if (newUserId && role !== 'patient') {
            // Wait a moment for the trigger to create the default role
            await new Promise(r => setTimeout(r, 1000));
            await sb.from('user_roles').update({ role: role }).eq('user_id', newUserId);
        }

        // If admin, also add to admin_users table
        if (newUserId && role === 'admin') {
            await sb.from('admin_users').upsert({
                user_id: newUserId,
                name: name,
                email: email,
            }, { onConflict: 'user_id' });
        }

        // Re-authenticate as admin (signUp may have changed the session)
        // We can't know the admin password, so we'll use the existing refresh token
        await sb.auth.refreshSession();

        // Success
        $msg.innerHTML = '✅ User <b>' + email + '</b> created as <b>' + role + '</b>!';
        $msg.style.color = '#2ec486';
        $msg.style.display = 'block';

        // Clear form
        document.getElementById('new-user-email').value = '';
        document.getElementById('new-user-password').value = '';
        document.getElementById('new-user-name').value = '';

        // Refresh user list
        await loadUsers();
        renderUsers();

    } catch (err) {
        $msg.textContent = '❌ Error: ' + err.message;
        $msg.style.color = '#e63946';
        $msg.style.display = 'block';
    }

    $btn.disabled = false;
    $btn.textContent = 'Add User';
}

// ── Start ────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', initApp);
