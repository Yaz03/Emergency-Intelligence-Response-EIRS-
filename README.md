# 🚨 EIRS — Emergency Intelligence & Response System

A full-stack emergency medical response platform with a **Flutter patient app**, a **web-based emergency portal**, a **paramedic dashboard**, and an **admin intelligence dashboard**.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Database Schema](#database-schema)
- [Setup Guide](#setup-guide)
- [Configuration (What to Change)](#configuration-what-to-change)
- [Features Breakdown](#features-breakdown)
- [Web Portal Pages](#web-portal-pages)
- [Deployment](#deployment)

---

## Overview

EIRS lets patients store their medical profile and generate encrypted QR codes. When scanned during an emergency, the QR opens a web portal showing the patient's medical data instantly — no login needed. The system logs incidents, sends GPS-based SMS alerts, and provides analytics dashboards.

### How It Works

```
Patient registers → Fills medical profile → Generates QR code
                                                    ↓
                                        QR is scanned in emergency
                                                    ↓
                                    Web portal shows patient data
                                    Incident is logged to database
                                                    ↓
                              Paramedic completes incident report
                              Admin reviews analytics & insights
```

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                   FLUTTER APP (Patient)              │
│  Auth │ Profile │ QR Code │ Emergency SOS │ Account  │
└──────────────────────┬───────────────────────────────┘
                       │ Supabase SDK
                       ▼
┌──────────────────────────────────────────────────────┐
│                   SUPABASE BACKEND                   │
│      Auth │ Postgres DB │ RLS Policies │ Triggers    │
└──────────────────────┬───────────────────────────────┘
                       │ Supabase JS CDN
                       ▼
┌──────────────────────────────────────────────────────┐
│                    WEB PORTAL                        │
│  Emergency Page │ Paramedic Dashboard │ Admin Panel  │
│          Hosted on Vercel (auto-deploy)              │
└──────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Mobile App** | Flutter / Dart |
| **State Management** | Provider |
| **Backend** | Supabase (Auth + Postgres + RLS) |
| **Web Portal** | HTML, CSS, Vanilla JS |
| **Charts** | Chart.js |
| **Maps** | Leaflet.js + Leaflet.heat + MarkerCluster |
| **QR Generation** | qr_flutter + pdf (Flutter) |
| **Location** | geolocator + geocoding (Flutter) |
| **Hosting** | Vercel (web portal) |

---

## Project Structure

```
EIRS/
├── lib/                              # Flutter app source
│   ├── main.dart                     # App entry point
│   ├── app.dart                      # MaterialApp + routing
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart    # ⚙️ App name, storage keys
│   │   │   └── supabase_config.dart  # ⚙️ SUPABASE URL + ANON KEY
│   │   ├── network/
│   │   │   └── dio_client.dart       # HTTP client setup
│   │   ├── storage/
│   │   │   └── secure_storage.dart   # Token storage
│   │   ├── theme/
│   │   │   └── app_theme.dart        # Light/dark theme
│   │   └── utils/
│   │       └── encryption_helper.dart # QR token encryption
│   │
│   └── features/
│       ├── auth/                     # Login, register, auth state
│       │   ├── data/
│       │   │   └── repositories/
│       │   │       └── auth_repository.dart
│       │   └── presentation/
│       │       ├── providers/
│       │       │   └── auth_provider.dart
│       │       └── screens/
│       │           ├── login_screen.dart
│       │           └── register_screen.dart
│       │
│       ├── profile/                  # Medical profile CRUD
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   └── profile_model.dart   # ⚙️ All profile fields
│       │   │   └── repositories/
│       │   │       └── profile_repository.dart
│       │   └── presentation/
│       │       ├── providers/
│       │       │   └── profile_provider.dart
│       │       └── screens/
│       │           └── profile_screen.dart
│       │
│       ├── qr/                       # QR code generation + sharing
│       │   └── presentation/screens/
│       │       └── qr_screen.dart
│       │
│       ├── emergency/                # SOS trigger + SMS + incident logging
│       │   └── presentation/
│       │       ├── providers/
│       │       │   └── emergency_provider.dart  # ⚙️ SMS message format
│       │       └── screens/
│       │           └── emergency_screen.dart
│       │
│       ├── home/                     # Home screen + tutorial
│       │   └── presentation/screens/
│       │       └── home_screen.dart
│       │
│       └── account/                  # Avatar, name edit, password reset
│           └── presentation/screens/
│               └── account_screen.dart
│
├── web/
│   └── portal/                       # Web portal (hosted on Vercel)
│       ├── emergency.html            # Public emergency page (QR scan target)
│       ├── login.html                # Paramedic login
│       ├── dashboard.html            # Paramedic incident dashboard
│       ├── scanner.html              # Web QR scanner
│       ├── admin_login.html          # Admin login
│       ├── admin.html                # Admin intelligence dashboard
│       ├── admin.js                  # ⚙️ All admin dashboard logic
│       ├── admin.css                 # Admin dashboard styles
│       ├── schema.sql                # Core DB schema
│       ├── roles_schema.sql          # User roles schema
│       ├── admin_users_schema.sql    # Admin users table
│       ├── admin_migration.sql       # Adds 'admin' role
│       ├── migration_v2.sql          # Profile field additions
│       └── migration_v3.sql          # City + completed_time columns
│
├── pubspec.yaml                      # Flutter dependencies
└── README.md                         # This file
```

> Files marked with ⚙️ are the main ones you'd modify for customization.

---

## Database Schema

### Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `profiles` | Patient medical data | `user_id`, `full_name`, `blood_group`, `allergies`, `medications`, `medical_conditions`, `emergency_contact_name/phone`, `city` |
| `incidents` | Emergency event log | `patient_id`, `scan_time`, `completed_time`, `latitude`, `longitude`, `incident_type`, `severity`, `status`, `city` |
| `emergency_tokens` | Time-limited QR tokens | `patient_id`, `token`, `expires_at` |
| `user_roles` | Role assignments | `user_id`, `role` (patient / paramedic / admin) |
| `admin_users` | Admin access list | `user_id`, `name`, `email` |

### SQL Setup Order

Run these in **Supabase SQL Editor** in this order:

1. `schema.sql` — Creates `emergency_tokens` + `incidents` tables + RLS
2. `roles_schema.sql` — Creates `user_roles` + auto-assign trigger
3. `admin_migration.sql` — Adds `admin` to valid roles + update policies
4. `admin_users_schema.sql` — Creates `admin_users` table
5. `migration_v2.sql` — Adds `medical_notes`, 2nd emergency contact, `avatar_index` to profiles
6. `migration_v3.sql` — Adds `city` and `completed_time` to incidents, `city` to profiles

---

## Setup Guide

### Prerequisites

- Flutter SDK (3.x+)
- A Supabase project (free tier works)
- Node.js (for Vercel, optional)
- Android Studio or Xcode

### 1. Clone & Install

```bash
git clone https://github.com/Yaz03/EIRS.git
cd EIRS
flutter pub get
```

### 2. Supabase Setup

1. Create a project at [supabase.com](https://supabase.com)
2. Go to **Settings → API** and copy your **URL** and **anon key**
3. Run all SQL files (see [SQL Setup Order](#sql-setup-order) above)
4. Make sure **email auth** is enabled in Supabase → Authentication → Providers

### 3. Configure Credentials

Update your Supabase credentials in **two places**:

**Flutter App:**
```
lib/core/constants/supabase_config.dart
```

**Web Portal (all HTML/JS files):**
```
web/portal/admin.js         → SUPABASE_URL, SUPABASE_ANON_KEY
web/portal/admin_login.html → SUPABASE_URL, SUPABASE_ANON_KEY
web/portal/login.html       → SUPABASE_URL, SUPABASE_ANON_KEY
web/portal/dashboard.html   → SUPABASE_URL, SUPABASE_ANON_KEY
web/portal/emergency.html   → SUPABASE_URL, SUPABASE_ANON_KEY
```

### 4. Run the App

```bash
flutter run
```

### 5. Deploy Web Portal

Push to GitHub → connect repo to [Vercel](https://vercel.com):
- **Root Directory:** `web/portal`
- **Framework:** None (static)

---

## Configuration (What to Change)

### 🔑 Supabase Credentials

| File | What to Change |
|------|----------------|
| `lib/core/constants/supabase_config.dart` | `supabaseUrl` and `supabaseAnonKey` |
| All `web/portal/*.html` and `admin.js` | `SUPABASE_URL` and `SUPABASE_ANON_KEY` |

### 🏷️ App Name / Branding

| File | What to Change |
|------|----------------|
| `lib/core/constants/app_constants.dart` | `appName` |
| `lib/app.dart` | MaterialApp `title` |
| All web portal HTML files | `<title>` tags and header text |
| `admin.html` | Sidebar header `<h1>` |
| `admin_login.html` | Logo text |
| `emergency.html` | Footer text |

### 🏥 Medical Profile Fields

To add/remove profile fields:

1. **Model:** `lib/features/profile/data/models/profile_model.dart` — Add field + update `fromJson`, `toJson`, `copyWith`, `empty()`
2. **Screen:** `lib/features/profile/presentation/screens/profile_screen.dart` — Add form field
3. **Database:** Run `ALTER TABLE profiles ADD COLUMN your_field TEXT;` in Supabase SQL
4. **Web portal:** Update `emergency.html` to display the new field

### 🚨 Emergency SMS Message

Edit the SMS template in:
```
lib/features/emergency/presentation/providers/emergency_provider.dart
```
Look for the `_sendEmergencySms` method.

### 📊 Admin Dashboard Analytics

All analytics logic is in a single file:
```
web/portal/admin.js
```

| Module | Function |
|--------|----------|
| KPIs | `renderKPIs()` |
| Risk Scores | `renderRiskScores()` |
| Peak Hours | `renderPeakHours()` |
| Growth Trend | `renderGrowthTrend()` |
| Handling Time | `renderResponseTime()` |
| Map + Heatmap | `initMap()`, `setMapMode()` |
| Incident Table | `renderIncidentTable()` |
| CSV Export | `exportCSV()` |
| User Management | `renderUsers()`, `addNewUser()` |

### 🎨 Theme / Colors

- **Flutter app:** `lib/core/theme/app_theme.dart`
- **Admin dashboard:** `web/portal/admin.css` (CSS variables at top)
- **Paramedic dashboard:** Inline styles in `dashboard.html`
- **Emergency page:** Inline styles in `emergency.html`

---

## Features Breakdown

### 📱 Flutter App (Patient)

| Feature | Description |
|---------|-------------|
| **Auth** | Email/password registration & login via Supabase |
| **Medical Profile** | Blood group, allergies, medications, conditions, notes, 2 emergency contacts |
| **QR Code** | Encrypted, time-limited QR linking to emergency portal |
| **Emergency SOS** | GPS capture → reverse geocode → SMS to contacts → log incident |
| **Account** | Emoji avatar picker, name edit, password reset, logout |

### 🌐 Web Portal

| Page | Access | Description |
|------|--------|-------------|
| `emergency.html` | Public | Shows patient medical data when QR is scanned |
| `login.html` | Paramedic | Role-gated login (paramedic only) |
| `dashboard.html` | Paramedic | View/complete incident reports |
| `scanner.html` | Public | Web-based QR scanner |
| `admin_login.html` | Admin | Admin-only login |
| `admin.html` | Admin | Full analytics dashboard |

### 📊 Admin Dashboard Modules

| Module | Details |
|--------|---------|
| **KPIs** | Patients, incidents, pending, completed, avg severity, avg handling time |
| **Risk Scores** | Per-city risk = (Frequency×0.5) + (AvgSeverity×0.3) + (7-Day Growth×0.2) |
| **Peak Hours** | Incidents grouped by hour (0–23) |
| **Growth Trend** | Last 7 vs previous 7 days, % change |
| **Handling Time** | Per-city avg, fastest/slowest, 14-day trend |
| **Map** | Leaflet with marker clustering + heatmap toggle |
| **Incident Table** | Filterable by name, city, date, severity, status + CSV export |
| **User Management** | Add users, promote/demote roles |

---

## Web Portal Pages

### Emergency Page Flow

```
QR Scanned → emergency.html?token=xxx
  → Validates token in emergency_tokens table
  → Fetches patient profile
  → Displays medical data (blood group, allergies, medications, contacts)
  → Logs incident with GPS coords
  → Links to paramedic dashboard
```

### Role System

| Role | Access |
|------|--------|
| `patient` | Flutter app only (auto-assigned on signup) |
| `paramedic` | `login.html` → `dashboard.html` |
| `admin` | `admin_login.html` → `admin.html` |

Promote users via admin dashboard or SQL:
```sql
-- Make paramedic
UPDATE user_roles SET role = 'paramedic' WHERE user_id = '<UUID>';

-- Make admin
UPDATE user_roles SET role = 'admin' WHERE user_id = '<UUID>';
INSERT INTO admin_users (user_id, name, email) VALUES ('<UUID>', 'Name', 'email');
```

---

## Deployment

### Flutter App
```bash
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

### Web Portal (Vercel)
1. Push to GitHub
2. Connect to Vercel
3. Set root directory to `web/portal`
4. Auto-deploys on every push

---

## License

This project is for educational purposes.

---

> Built with Flutter, Supabase, Chart.js, and Leaflet.js
