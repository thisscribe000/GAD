# GAD — General Administration Dashboard

A work management app for attendance tracking, leave management, performance appraisals, staff administration, and daily reporting.

Built with **Flutter** + **Supabase** (PostgreSQL + Auth).

## Features

### Authentication
- Login with email or staff ID + password via Supabase Auth
- Biometric (fingerprint/face) enrollment on first login
- Role-based routing: Staff → Staff Dashboard, Admin → Admin Dashboard
- Forgot Password — sends real password reset email via Supabase

### Staff Dashboard
- Greeting with clock status (clocked in/out)
- Stats: Days Present, Pending Appraisals (open cycles not yet submitted)
- Quick Tasks: Performance Appraisal, Attendance History, Request Leave, My Leave Requests, Daily Report

### Admin Dashboard
- Attendance analytics: Present / Late / Absent counts, Average Work Today
- Operations: Leave Requests, Weekend Permissions, Daily Reports, Add Staff
- Performance Overview: employee stats with review buttons
- Staff list with review buttons

### Attendance
- Clock in/out with biometric verification + GPS geofence (200m from office)
- Weekend restriction (requires admin permission grant)
- History with status: On Time, Late, Open, Absent
- Weekly summary with total hours, average, days present

### Leave Management
- Staff: submit request with type, dates, and reason
- Admin: approve or reject
- History with status badges: Approved, Rejected, Pending

### Performance Appraisals
- Appraisal cycles (e.g. Q1 2026) with open/closed status
- Self-assessment: 5 KPI categories scored 1–5 + comment
- Admin review: add manager scores + comment, mark as reviewed
- Results: percentage indicator, category breakdown with progress bars, status pills

### Staff Directory
- Real employee list from database with pull-to-refresh
- Profile: name, staff ID, department, position, role, average work duration
- **Edit Staff**: admin can update name, email, department, position
- **Delete Staff**: admin soft-removes (hides from directory, preserves history)
- **Add Staff**: creates Supabase Auth user + employee record, auto-generates staff ID and temporary password

### Daily Reports
- Staff form: "What I did today" + "Plans for the week" (updatable same-day)
- Admin browser: view all staff reports by date
- RLS: staff see own reports, admins see all

### Weekend Work Control
- Admin grants/revokes weekend clock-in permission per staff member
- Real employee list (no hardcoded data)

## Tech Stack

| Layer | Choice |
|-------|--------|
| Frontend | Flutter (Dart) |
| Backend | Supabase (PostgreSQL) |
| Auth | Supabase Auth (email/password) |
| State | setState |
| Biometrics | local_auth |
| Location | geolocator |
| Device Storage | SharedPreferences (biometric prefs only) |

## Database

8 tables with Row Level Security on all, using email-based identity:
`employees`, `attendance_records`, `leave_requests`, `appraisal_cycles`, `kpi_questions`, `appraisal_submissions`, `weekend_permissions`, `daily_reports`

Seed data: 3 employees, 2 appraisal cycles, 5 KPI questions.

## Setup

```bash
# Prerequisites: Flutter SDK >=3.0.0, a Supabase project

# 1. Clone
git clone https://github.com/thisscribe000/GAD.git
cd GAD

# 2. Create .env (already gitignored)
echo "SUPABASE_URL=https://your-project.supabase.co" > .env
echo "SUPABASE_ANON_KEY=your-anon-key" >> .env

# 3. Run SQL in Supabase Editor (in order):
#    sql/schema.sql
#    sql/002_rls_email_migration.sql
#    sql/003_daily_reports.sql
#    sql/004_employee_active.sql

# 4. Create an admin auth user in Supabase Auth dashboard
#    Insert a matching employee record with role='admin'

# 5. Run
flutter pub get
flutter run
```
