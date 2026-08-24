-- ============================================================
-- Vidya Campus SMS — Migration: GPS-Verified Live Presence
-- Run this in SQL Editor after migration_messaging_presence.sql.
-- ============================================================

alter table student_presence add column if not exists latitude numeric;
alter table student_presence add column if not exists longitude numeric;
alter table student_presence add column if not exists verified boolean default false;
alter table student_presence add column if not exists distance_meters numeric;

comment on column student_presence.verified is
  'true if the student''s device GPS was within CAMPUS_RADIUS_METERS of the campus center at the moment they set their location. false means either GPS was denied/unavailable, or the device reported a location outside campus.';
