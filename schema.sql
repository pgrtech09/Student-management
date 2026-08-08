-- ============================================================
-- Vidya Campus — Student Management System
-- MODULE 1: Complete Database Schema
-- Run this ONCE in Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- ---------- DEPARTMENTS & SECTIONS ----------

create table if not exists departments (
  id bigint generated always as identity primary key,
  code text unique not null,        -- 'CSE', 'ECE', etc.
  name text not null                 -- 'Computer Science & Engineering'
);

create table if not exists sections (
  id bigint generated always as identity primary key,
  department_code text not null references departments(code) on delete cascade,
  name text not null,                 -- 'A', 'B', 'C'
  semester int not null,
  unique(department_code, name, semester)
);

-- ---------- PROFILES (students, incharge, hod) ----------
-- One table for all logins. Supabase Auth requires an email internally,
-- but the UI lets people type their Roll Number / Employee ID — we resolve
-- that to an email via the resolve_login_email() function below.

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null,
  role text not null check (role in ('student','incharge','hod')),
  department text not null,
  section text,               -- students/incharge only
  roll_no text,                -- students only — their login identifier
  employee_id text,             -- incharge/hod only — their login identifier
  semester int,
  phone text,
  blood_group text,
  parent_name text,
  parent_phone text,
  profile_photo_url text,
  dob date,
  year int,
  created_at timestamptz default now()
);

create unique index if not exists profiles_roll_no_idx on profiles(roll_no) where roll_no is not null;
create unique index if not exists profiles_employee_id_idx on profiles(employee_id) where employee_id is not null;

-- ---------- FACULTY (display/reports — not necessarily a login) ----------

create table if not exists faculty (
  id bigint generated always as identity primary key,
  name text not null,
  employee_id text unique not null,
  department text not null,
  designation text,
  phone text,
  email text
);

-- ---------- SUBJECTS ----------

create table if not exists subjects (
  id bigint generated always as identity primary key,
  code text not null,
  name text not null,
  department text not null,
  semester int not null,
  faculty_name text,
  credits int default 3
);

-- ---------- ATTENDANCE ----------

create table if not exists attendance (
  id bigint generated always as identity primary key,
  student_id uuid not null references profiles(id) on delete cascade,
  subject_id bigint references subjects(id),
  date date not null,
  status text not null check (status in ('present','absent','leave')),
  marked_by text default 'incharge',   -- 'incharge' or 'checkin'
  location text,
  reason text,
  unique (student_id, date, subject_id)
);

-- ---------- LOCATION CHECK-INS (separate log, spec requirement) ----------

create table if not exists location_checkins (
  id bigint generated always as identity primary key,
  student_id uuid not null references profiles(id) on delete cascade,
  date date not null,
  latitude numeric,
  longitude numeric,
  checkin_time timestamptz default now(),
  unique(student_id, date)
);

-- ---------- MARKS ----------

create table if not exists marks (
  id bigint generated always as identity primary key,
  student_id uuid not null references profiles(id) on delete cascade,
  subject_id bigint references subjects(id),
  subject text not null,
  semester int not null,
  internal1 numeric,
  internal2 numeric,
  assignment numeric,
  lab numeric,
  semester_exam numeric,
  max_marks numeric default 100,
  backlog boolean default false,
  updated_at timestamptz default now(),
  unique(student_id, subject, semester)
);

-- ---------- SEMESTER RESULTS ----------

create table if not exists semester_results (
  id bigint generated always as identity primary key,
  student_id uuid not null references profiles(id) on delete cascade,
  semester int not null,
  sgpa numeric,
  cgpa numeric,
  credits_earned int,
  backlogs int default 0,
  status text default 'pass' check (status in ('pass','fail')),
  unique(student_id, semester)
);

-- ---------- TIMETABLE ----------

create table if not exists timetable (
  id bigint generated always as identity primary key,
  department text not null,
  section text not null,
  day text not null,
  period int not null,
  time_slot text not null,
  subject text not null,
  faculty_name text,
  room_number text
);

-- ---------- LEAVE REQUESTS ----------

create table if not exists leave_requests (
  id bigint generated always as identity primary key,
  student_id uuid not null references profiles(id) on delete cascade,
  reason_type text not null check (reason_type in ('Medical','Personal','Emergency','Other')),
  reason_text text,
  certificate_url text,
  from_date date not null,
  to_date date not null,
  status text default 'Pending' check (status in ('Pending','Approved','Rejected')),
  remarks text,
  reviewed_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- ---------- EVENTS / NEWS / ANNOUNCEMENTS / HOLIDAYS ----------

create table if not exists events (
  id bigint generated always as identity primary key,
  title text not null,
  description text,
  type text default 'news' check (type in ('news','event','announcement','holiday','exam')),
  department text not null,        -- specific dept, or 'ALL'
  venue text,
  event_date date,
  event_time text,
  poster_url text,
  posted_by uuid references profiles(id),
  created_at timestamptz default now()
);

create table if not exists event_registrations (
  id bigint generated always as identity primary key,
  event_id bigint not null references events(id) on delete cascade,
  student_id uuid not null references profiles(id) on delete cascade,
  registered_at timestamptz default now(),
  unique(event_id, student_id)
);

-- ---------- NOTIFICATIONS (realtime) ----------

create table if not exists notifications (
  id bigint generated always as identity primary key,
  title text not null,
  message text,
  type text default 'info',   -- 'attendance','marks','leave','event','holiday','exam','notice'
  target_role text,             -- 'student','incharge','hod', or null = everyone in scope
  department text not null,
  section text,                  -- null = whole department
  student_id uuid references profiles(id),  -- null = broadcast to section/department, or a specific student
  created_at timestamptz default now()
);

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Resolve a Roll Number / Employee ID / email to the account's email,
-- so the login page can accept any of the three as the identifier.
-- Callable by anonymous users (needed before login) but only ever
-- returns an email address — nothing else.
create or replace function public.resolve_login_email(identifier text)
returns text
language sql stable security definer set search_path = public as $$
  select email from profiles
  where roll_no = identifier or employee_id = identifier or email = identifier
  limit 1;
$$;

grant execute on function public.resolve_login_email(text) to anon, authenticated;

-- Current user's own role/department/section, used inside RLS policies
-- (SECURITY DEFINER avoids infinite recursion on the profiles table itself)
create or replace function public.current_role() returns text
language sql stable security definer set search_path = public as $$
  select role from profiles where id = auth.uid();
$$;

create or replace function public.current_department() returns text
language sql stable security definer set search_path = public as $$
  select department from profiles where id = auth.uid();
$$;

create or replace function public.current_section() returns text
language sql stable security definer set search_path = public as $$
  select section from profiles where id = auth.uid();
$$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table profiles enable row level security;
alter table faculty enable row level security;
alter table subjects enable row level security;
alter table attendance enable row level security;
alter table location_checkins enable row level security;
alter table marks enable row level security;
alter table semester_results enable row level security;
alter table timetable enable row level security;
alter table leave_requests enable row level security;
alter table events enable row level security;
alter table event_registrations enable row level security;
alter table notifications enable row level security;
alter table departments enable row level security;
alter table sections enable row level security;

-- ---------- PROFILES ----------
create policy "own profile" on profiles for select using (id = auth.uid());
create policy "update own profile" on profiles for update using (id = auth.uid());
create policy "student self-registers" on profiles for insert
  with check (id = auth.uid() and role = 'student');

create policy "incharge sees own section students" on profiles for select
  using (public.current_role() = 'incharge' and role = 'student'
    and department = public.current_department() and section = public.current_section());

create policy "hod sees own department" on profiles for select
  using (public.current_role() = 'hod' and department = public.current_department());

create policy "hod manages own department profiles" on profiles for all
  using (public.current_role() = 'hod' and department = public.current_department())
  with check (public.current_role() = 'hod' and department = public.current_department());

-- ---------- DEPARTMENTS / SECTIONS (readable by any logged-in user) ----------
create policy "view departments" on departments for select using (auth.uid() is not null);
create policy "view sections" on sections for select using (auth.uid() is not null);
create policy "hod manages sections" on sections for all
  using (public.current_role() = 'hod' and department_code = public.current_department())
  with check (public.current_role() = 'hod' and department_code = public.current_department());

-- ---------- FACULTY ----------
create policy "view department faculty" on faculty for select
  using (department = public.current_department());
create policy "hod manages faculty" on faculty for all
  using (public.current_role() = 'hod' and department = public.current_department())
  with check (public.current_role() = 'hod' and department = public.current_department());

-- ---------- SUBJECTS ----------
create policy "view department subjects" on subjects for select
  using (department = public.current_department());
create policy "hod manages subjects" on subjects for all
  using (public.current_role() = 'hod' and department = public.current_department())
  with check (public.current_role() = 'hod' and department = public.current_department());

-- ---------- ATTENDANCE ----------
create policy "student views own attendance" on attendance for select using (student_id = auth.uid());
create policy "student writes own checkin attendance" on attendance for insert with check (student_id = auth.uid());
create policy "student updates own attendance reason" on attendance for update using (student_id = auth.uid());

create policy "incharge views section attendance" on attendance for select
  using (public.current_role() = 'incharge' and exists (
    select 1 from profiles p where p.id = attendance.student_id
      and p.department = public.current_department() and p.section = public.current_section()));
create policy "incharge writes section attendance" on attendance for insert
  with check (public.current_role() = 'incharge' and exists (
    select 1 from profiles p where p.id = attendance.student_id
      and p.department = public.current_department() and p.section = public.current_section()));
create policy "incharge updates section attendance" on attendance for update
  using (public.current_role() = 'incharge' and exists (
    select 1 from profiles p where p.id = attendance.student_id
      and p.department = public.current_department() and p.section = public.current_section()));

create policy "hod views department attendance" on attendance for select
  using (public.current_role() = 'hod' and exists (
    select 1 from profiles p where p.id = attendance.student_id and p.department = public.current_department()));

-- ---------- LOCATION CHECK-INS ----------
create policy "student manages own checkins" on location_checkins for all
  using (student_id = auth.uid()) with check (student_id = auth.uid());
create policy "incharge views section checkins" on location_checkins for select
  using (public.current_role() = 'incharge' and exists (
    select 1 from profiles p where p.id = location_checkins.student_id
      and p.department = public.current_department() and p.section = public.current_section()));
create policy "hod views department checkins" on location_checkins for select
  using (public.current_role() = 'hod' and exists (
    select 1 from profiles p where p.id = location_checkins.student_id and p.department = public.current_department()));

-- ---------- MARKS ----------
create policy "student views own marks" on marks for select using (student_id = auth.uid());
create policy "incharge views section marks" on marks for select
  using (public.current_role() = 'incharge' and exists (
    select 1 from profiles p where p.id = marks.student_id
      and p.department = public.current_department() and p.section = public.current_section()));
create policy "incharge writes section marks" on marks for insert
  with check (public.current_role() = 'incharge' and exists (
    select 1 from profiles p where p.id = marks.student_id
      and p.department = public.current_department() and p.section = public.current_section()));
create policy "incharge updates section marks" on marks for update
  using (public.current_role() = 'incharge' and exists (
    select 1 from profiles p where p.id = marks.student_id
      and p.department = public.current_department() and p.section = public.current_section()));
create policy "hod views department marks" on marks for select
  using (public.current_role() = 'hod' and exists (
    select 1 from profiles p where p.id = marks.student_id and p.department = public.current_department()));

-- ---------- SEMESTER RESULTS ----------
create policy "student views own results" on semester_results for select using (student_id = auth.uid());
create policy "incharge views section results" on semester_results for select
  using (public.current_role() = 'incharge' and exists (
    select 1 from profiles p where p.id = semester_results.student_id
      and p.department = public.current_department() and p.section = public.current_section()));
create policy "hod manages department results" on semester_results for all
  using (public.current_role() = 'hod' and exists (
    select 1 from profiles p where p.id = semester_results.student_id and p.department = public.current_department()))
  with check (public.current_role() = 'hod' and exists (
    select 1 from profiles p where p.id = semester_results.student_id and p.department = public.current_department()));

-- ---------- TIMETABLE ----------
create policy "view own department timetable" on timetable for select
  using (department = public.current_department());
create policy "hod manages timetable" on timetable for all
  using (public.current_role() = 'hod' and department = public.current_department())
  with check (public.current_role() = 'hod' and department = public.current_department());

-- ---------- LEAVE REQUESTS ----------
create policy "student manages own leave requests" on leave_requests for all
  using (student_id = auth.uid()) with check (student_id = auth.uid());
create policy "incharge views section leave requests" on leave_requests for select
  using (public.current_role() = 'incharge' and exists (
    select 1 from profiles p where p.id = leave_requests.student_id
      and p.department = public.current_department() and p.section = public.current_section()));
create policy "incharge reviews section leave requests" on leave_requests for update
  using (public.current_role() = 'incharge' and exists (
    select 1 from profiles p where p.id = leave_requests.student_id
      and p.department = public.current_department() and p.section = public.current_section()));
create policy "hod views department leave requests" on leave_requests for select
  using (public.current_role() = 'hod' and exists (
    select 1 from profiles p where p.id = leave_requests.student_id and p.department = public.current_department()));

-- ---------- EVENTS ----------
create policy "view department events" on events for select
  using (department = public.current_department() or department = 'ALL');
create policy "hod manages events" on events for all
  using (public.current_role() = 'hod' and department = public.current_department())
  with check (public.current_role() = 'hod' and department = public.current_department());
create policy "incharge posts class announcements" on events for insert
  with check (public.current_role() = 'incharge' and department = public.current_department() and type = 'announcement');

-- ---------- EVENT REGISTRATIONS ----------
create policy "student manages own registrations" on event_registrations for all
  using (student_id = auth.uid()) with check (student_id = auth.uid());
create policy "hod views department registrations" on event_registrations for select
  using (public.current_role() = 'hod' and exists (
    select 1 from profiles p where p.id = event_registrations.student_id and p.department = public.current_department()));

-- ---------- NOTIFICATIONS ----------
create policy "student views own notifications" on notifications for select
  using (
    student_id = auth.uid()
    or (student_id is null and department = public.current_department()
        and (section is null or section = public.current_section()))
  );
create policy "incharge views section notifications" on notifications for select
  using (public.current_role() = 'incharge' and department = public.current_department());
create policy "hod manages department notifications" on notifications for all
  using (public.current_role() = 'hod' and department = public.current_department())
  with check (public.current_role() = 'hod' and department = public.current_department());
create policy "incharge inserts notifications" on notifications for insert
  with check (public.current_role() = 'incharge' and department = public.current_department());

-- Enable realtime on notifications and attendance so dashboards get live pushes
alter publication supabase_realtime add table notifications;
alter publication supabase_realtime add table attendance;
alter publication supabase_realtime add table leave_requests;
