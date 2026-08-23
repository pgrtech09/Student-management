-- ============================================================
-- Vidya Campus SMS — Migration: Messaging + Live Campus Presence
-- Run this in SQL Editor after schema.sql (and after real_data_seed.sql
-- if you've already loaded your real college data).
-- ============================================================

-- ---------- MESSAGES (Student <-> Incharge direct messaging) ----------

create table if not exists messages (
  id bigint generated always as identity primary key,
  sender_id uuid not null references profiles(id) on delete cascade,
  recipient_id uuid not null references profiles(id) on delete cascade,
  body text not null,
  read boolean default false,
  created_at timestamptz default now()
);

create index if not exists messages_sender_idx on messages(sender_id);
create index if not exists messages_recipient_idx on messages(recipient_id);

-- A student needs to know who their incharge is in order to message them.
-- This was a gap in the original schema — students previously had no way to
-- read their own incharge's profile row.
create policy "student views own incharge" on profiles for select
  using (
    public.current_role() = 'student'
    and role = 'incharge'
    and department = public.current_department()
    and section = public.current_section()
  );

alter table messages enable row level security;

-- Either party in a conversation can read it
create policy "participants read own messages" on messages for select
  using (sender_id = auth.uid() or recipient_id = auth.uid());

-- A student may only message their OWN incharge (same department + section);
-- an incharge may only message a student in their OWN section.
create policy "student messages own incharge" on messages for insert
  with check (
    sender_id = auth.uid()
    and public.current_role() = 'student'
    and exists (
      select 1 from profiles p
      where p.id = messages.recipient_id
        and p.role = 'incharge'
        and p.department = public.current_department()
        and p.section = public.current_section()
    )
  );

create policy "incharge messages section student" on messages for insert
  with check (
    sender_id = auth.uid()
    and public.current_role() = 'incharge'
    and exists (
      select 1 from profiles p
      where p.id = messages.recipient_id
        and p.role = 'student'
        and p.department = public.current_department()
        and p.section = public.current_section()
    )
  );

-- Recipient can mark a message as read
create policy "recipient marks read" on messages for update
  using (recipient_id = auth.uid())
  with check (recipient_id = auth.uid());

-- ---------- LIVE CAMPUS PRESENCE ----------
-- One row per student, continuously updated (not a log) — where they say
-- they currently are on campus, and when they last updated it.

create table if not exists student_presence (
  student_id uuid primary key references profiles(id) on delete cascade,
  location text not null,       -- 'Library', 'Lab', 'Classroom', 'Canteen', 'Ground', 'Auditorium', 'Other'
  updated_at timestamptz default now()
);

alter table student_presence enable row level security;

-- Student can see and set only their own presence
create policy "student manages own presence" on student_presence for all
  using (student_id = auth.uid())
  with check (student_id = auth.uid());

-- Incharge sees live presence of their own section
create policy "incharge views section presence" on student_presence for select
  using (
    public.current_role() = 'incharge'
    and exists (
      select 1 from profiles p where p.id = student_presence.student_id
        and p.department = public.current_department()
        and p.section = public.current_section()
    )
  );

-- HOD sees live presence across the whole department
create policy "hod views department presence" on student_presence for select
  using (
    public.current_role() = 'hod'
    and exists (
      select 1 from profiles p where p.id = student_presence.student_id
        and p.department = public.current_department()
    )
  );

-- Enable realtime push for messages and presence, same as notifications/attendance
alter publication supabase_realtime add table messages;
alter publication supabase_realtime add table student_presence;
