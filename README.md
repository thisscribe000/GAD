# GAD — General Administration Dashboard

A work management app for attendance tracking, leave management, performance appraisals, and staff administration.

Built with **Flutter** + **Supabase** (PostgreSQL + Auth).

## Status

The app is **functional and working** on its first release. Core features are implemented end-to-end. See below for what's done and what's planned.

## Features

### ✅ Implemented

| Feature | Details |
|---------|---------|
| **Authentication** | Email or Staff ID login via Supabase Auth. Optional biometric (fingerprint/face) enrollment on first login. Role-based routing (staff vs admin dashboard). |
| **Attendance** | Clock in/out with biometric verification. GPS geofence check (within 200m of office). Weekend restriction. Real-time clock with work duration tracking. History with On Time / Late / Absent status. |
| **Leave Management** | Staff can submit requests with type, dates, and reason. Admin can approve or reject. History view with status badges (Approved / Rejected / Pending). |
| **Performance Appraisals** | Appraisal cycles (e.g. Q1 2026). Self-assessment with 5 KPI categories rated 1–5. Admin review with manager scores and comment. Results view with percentage indicator and category breakdown. |
| **Staff Directory** | View staff profiles with work duration stats. **Add Staff** flow creates a Supabase Auth user automatically with a generated temporary password. |
| **Weekend Work Control** | Admin can grant weekend work permissions to staff. |
| **Admin Dashboard** | Attendance analytics (present/late/absent counts, average work hours). Operations panel (leave requests, weekend permissions, add staff). Performance overview with staff list and review buttons. |

### 🐛 Known Issues / Stubs

| Issue | Status |
|-------|--------|
| Directory list shows hardcoded employees (not real DB data) | **To fix** |
| Weekend approval screen uses hardcoded staff list | **To fix** |
| Profile screen ignores route argument (always loads current user) | **To fix** |
| Forgot password screen is UI only (no actual reset call) | **To fix** |

### 🗑️ Dead Code (11 files, not used)

Various orphaned service files, widgets, and an old local-only attendance module from before the Supabase migration. Marked for cleanup.

## Planned Features

1. **Fix stubs** — directory list, weekend approval, profile, forgot password
2. **Clean up** — remove dead code
3. **Daily Reports** — staff submit what they did today and plans for the week; admin can browse
4. **Polish** — edit/delete staff, leave balance tracking, reports/export

## Tech Stack

| Layer | Choice |
|-------|--------|
| Frontend | Flutter (Dart) |
| Backend | Supabase (PostgreSQL) |
| Auth | Supabase Auth (email/password) |
| State | setState (no external library) |
| Biometrics | local_auth |
| Location | geolocator |
| Storage | SharedPreferences (device-local prefs only) |

## Getting Started

### Prerequisites

- Flutter SDK >=3.0.0
- A Supabase project with the schema from `sql/schema.sql`

### Setup

1. Clone the repo
2. Create a `.env` file in the project root:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
3. Run the schema in your Supabase SQL Editor: `sql/schema.sql`
4. Run the RLS migration: `sql/002_rls_email_migration.sql`
5. Create an admin auth user manually in Supabase Auth (e.g. `admin@church.org`)
6. Insert a matching employee record (role = `admin`)
7. `flutter pub get`
8. `flutter run`
