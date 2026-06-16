-- =============================================================
-- Migration 003: Daily Reports
--
-- Staff submit what they did today and their plans for the week.
-- Admins can browse all reports.
-- =============================================================

create table daily_reports (
  id uuid primary key default gen_random_uuid(),
  staff_id text not null references employees(staff_id),
  report_date date not null default current_date,
  what_i_did text not null,
  plans_for_week text not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(staff_id, report_date)
);

create index idx_daily_reports_staff_date on daily_reports(staff_id, report_date);

alter table daily_reports enable row level security;

create policy "daily_reports_select_own"
  on daily_reports for select
  using (
    staff_id = (select staff_id from employees where email = auth.email())
    or
    exists (select 1 from employees where email = auth.email() and role = 'admin')
  );

create policy "daily_reports_insert_own"
  on daily_reports for insert
  with check (
    staff_id = (select staff_id from employees where email = auth.email())
  );

create policy "daily_reports_update_own"
  on daily_reports for update
  using (
    staff_id = (select staff_id from employees where email = auth.email())
  );

create policy "daily_reports_delete_own"
  on daily_reports for delete
  using (
    staff_id = (select staff_id from employees where email = auth.email())
  );
