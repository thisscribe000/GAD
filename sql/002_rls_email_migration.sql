-- =============================================================
-- Migration 002: Fix RLS to use auth.email() instead of auth.uid()
-- 
-- The employees.id column uses gen_random_uuid() and is NOT
-- the auth user's UUID. The link is through email instead.
-- =============================================================

-- First drop all existing policies so we can recreate them
drop policy if exists "employees_read_all" on employees;
drop policy if exists "employees_insert_admins" on employees;
drop policy if exists "employees_update_own" on employees;

drop policy if exists "attendance_select_own" on attendance_records;
drop policy if exists "attendance_insert_own" on attendance_records;
drop policy if exists "attendance_update_own" on attendance_records;

drop policy if exists "leave_select_own" on leave_requests;
drop policy if exists "leave_insert_own" on leave_requests;
drop policy if exists "leave_update_admins" on leave_requests;

drop policy if exists "cycles_read_all" on appraisal_cycles;
drop policy if exists "kpi_read_all" on kpi_questions;

drop policy if exists "submissions_select_own" on appraisal_submissions;
drop policy if exists "submissions_insert_own" on appraisal_submissions;
drop policy if exists "submissions_update_own" on appraisal_submissions;
drop policy if exists "submissions_update_admins" on appraisal_submissions;

drop policy if exists "weekend_select_own" on weekend_permissions;
drop policy if exists "weekend_insert_admins" on weekend_permissions;
drop policy if exists "weekend_delete_admins" on weekend_permissions;

-- Make email not null (it already has values from seed data)
alter table employees alter column email set not null;

-- EMPLOYEES
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

-- ATTENDANCE
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

-- LEAVE
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

-- APPRAISAL CYCLES
create policy "cycles_read_all"
  on appraisal_cycles for select
  using (true);

-- KPI QUESTIONS
create policy "kpi_read_all"
  on kpi_questions for select
  using (true);

-- SUBMISSIONS
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

-- WEEKEND PERMISSIONS
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
