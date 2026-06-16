-- =============================================================
-- GAD - General Administration Dashboard
-- Supabase Schema + Row Level Security
-- Run this in Supabase SQL Editor after creating your project
-- =============================================================

-- 0. EXTENSIONS
create extension if not exists "pgcrypto";

-- 1. EMPLOYEES
create table employees (
  id uuid primary key default gen_random_uuid(),
  staff_id text unique not null,
  name text not null,
  role text not null check (role in ('staff', 'admin')),
  department text not null,
  position text not null,
  email text unique not null,
  created_at timestamptz default now()
);

-- 2. ATTENDANCE RECORDS
create table attendance_records (
  id uuid primary key default gen_random_uuid(),
  staff_id text not null references employees(staff_id),
  date date not null default current_date,
  clock_in timestamptz not null,
  clock_out timestamptz,
  clock_in_time text,       -- Display format e.g. "8:15 AM"
  clock_out_time text,      -- Display format e.g. "5:30 PM"
  unique(staff_id, date)
);

-- 3. LEAVE REQUESTS
create table leave_requests (
  id uuid primary key default gen_random_uuid(),
  staff_id text not null references employees(staff_id),
  leave_type text not null,
  start_date date not null,
  end_date date not null,
  reason text,
  status text not null default 'Pending' check (status in ('Pending', 'Approved', 'Rejected')),
  submitted_at timestamptz default now(),
  reviewed_at timestamptz,
  reviewed_by text references employees(staff_id)
);

-- 4. APPRAISAL CYCLES
create table appraisal_cycles (
  id text primary key,       -- e.g. 'q1_2026'
  title text not null,
  start_date date not null,
  end_date date not null,
  is_open boolean not null default false
);

-- 5. KPI QUESTIONS
create table kpi_questions (
  id text primary key,       -- e.g. 'quality', 'communication'
  question text not null,
  max_score int not null default 5
);

-- 6. APPRAISAL SUBMISSIONS
create table appraisal_submissions (
  id uuid primary key default gen_random_uuid(),
  cycle_id text not null references appraisal_cycles(id),
  staff_id text not null references employees(staff_id),
  self_scores jsonb not null default '{}',
  comment text,
  submitted boolean not null default false,
  manager_scores jsonb default null,
  manager_comment text default null,
  reviewed boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(cycle_id, staff_id)
);

-- 7. WEEKEND PERMISSIONS
create table weekend_permissions (
  id uuid primary key default gen_random_uuid(),
  staff_id text not null references employees(staff_id),
  approved_by text not null references employees(staff_id),
  granted_at timestamptz default now(),
  expires_at date
);

-- =============================================================
-- INDEXES
-- =============================================================
create index idx_attendance_staff_date on attendance_records(staff_id, date);
create index idx_leave_staff on leave_requests(staff_id);
create index idx_leave_status on leave_requests(status);
create index idx_appraisal_staff_cycle on appraisal_submissions(staff_id, cycle_id);
create index idx_weekend_staff on weekend_permissions(staff_id);

-- =============================================================
-- ROW LEVEL SECURITY
-- Using auth.email() throughout since employees.id is a
-- random UUID (not the auth user's UUID). The link between
-- auth.users and employees is via the email field.
-- =============================================================

-- Enable RLS on all tables
alter table employees enable row level security;
alter table attendance_records enable row level security;
alter table leave_requests enable row level security;
alter table appraisal_cycles enable row level security;
alter table kpi_questions enable row level security;
alter table appraisal_submissions enable row level security;
alter table weekend_permissions enable row level security;

-- EMPLOYEES: everyone can read, only admins can insert/update
create policy "employees_read_all"
  on employees for select
  using (true);

create policy "employees_insert_admins"
  on employees for insert
  with check (
    exists (select 1 from employees where email = auth.email() and role = 'admin')
  );

create policy "employees_update_own"
  on employees for update
  using (email = auth.email());

-- ATTENDANCE: staff see own, admins see all
create policy "attendance_select_own"
  on attendance_records for select
  using (
    staff_id = (select staff_id from employees where email = auth.email())
    or
    exists (select 1 from employees where email = auth.email() and role = 'admin')
  );

create policy "attendance_insert_own"
  on attendance_records for insert
  with check (
    staff_id = (select staff_id from employees where email = auth.email())
  );

create policy "attendance_update_own"
  on attendance_records for update
  using (
    staff_id = (select staff_id from employees where email = auth.email())
  );

-- LEAVE: staff see own, admins see all
create policy "leave_select_own"
  on leave_requests for select
  using (
    staff_id = (select staff_id from employees where email = auth.email())
    or
    exists (select 1 from employees where email = auth.email() and role = 'admin')
  );

create policy "leave_insert_own"
  on leave_requests for insert
  with check (
    staff_id = (select staff_id from employees where email = auth.email())
  );

create policy "leave_update_admins"
  on leave_requests for update
  using (
    exists (select 1 from employees where email = auth.email() and role = 'admin')
  );

-- APPRAISAL CYCLES: everyone can read
create policy "cycles_read_all"
  on appraisal_cycles for select
  using (true);

-- KPI QUESTIONS: everyone can read
create policy "kpi_read_all"
  on kpi_questions for select
  using (true);

-- SUBMISSIONS: staff see own, admins see all
create policy "submissions_select_own"
  on appraisal_submissions for select
  using (
    staff_id = (select staff_id from employees where email = auth.email())
    or
    exists (select 1 from employees where email = auth.email() and role = 'admin')
  );

create policy "submissions_insert_own"
  on appraisal_submissions for insert
  with check (
    staff_id = (select staff_id from employees where email = auth.email())
  );

create policy "submissions_update_own"
  on appraisal_submissions for update
  using (
    staff_id = (select staff_id from employees where email = auth.email())
  );

create policy "submissions_update_admins"
  on appraisal_submissions for update
  using (
    exists (select 1 from employees where email = auth.email() and role = 'admin')
  );

-- WEEKEND PERMISSIONS: staff see own, admins see all
create policy "weekend_select_own"
  on weekend_permissions for select
  using (
    staff_id = (select staff_id from employees where email = auth.email())
    or
    exists (select 1 from employees where email = auth.email() and role = 'admin')
  );

create policy "weekend_insert_admins"
  on weekend_permissions for insert
  with check (
    exists (select 1 from employees where email = auth.email() and role = 'admin')
  );

create policy "weekend_delete_admins"
  on weekend_permissions for delete
  using (
    exists (select 1 from employees where email = auth.email() and role = 'admin')
  );

-- =============================================================
-- SEED DATA
-- =============================================================

insert into employees (staff_id, name, role, department, position, email) values
  ('staff001', 'John Doe', 'staff', 'Media', 'Content Officer', 'john@gad.church'),
  ('staff002', 'Mary James', 'staff', 'Protocol', 'Coordinator', 'mary@gad.church'),
  ('mgr001', 'Pastor Daniel', 'admin', 'Operations', 'Team Manager', 'daniel@gad.church');

insert into appraisal_cycles (id, title, start_date, end_date, is_open) values
  ('q1_2026', 'Q1 2026 Performance Review', '2026-01-01', '2026-03-31', true),
  ('q2_2026', 'Q2 2026 Performance Review', '2026-04-01', '2026-06-30', false);

insert into kpi_questions (id, question, max_score) values
  ('quality', 'Quality of Work', 5),
  ('communication', 'Communication', 5),
  ('teamwork', 'Team Collaboration', 5),
  ('initiative', 'Initiative', 5),
  ('leadership', 'Leadership', 5);
