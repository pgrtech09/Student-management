-- ============================================================
-- Vidya Campus — MODULE 3: Seed Data
--
-- BEFORE running this file, create these 11 users in
-- Authentication → Users → Add User (tick "Auto Confirm User"):
--
--   hod@college.edu           password123
--   incharge.a@college.edu    password123
--   incharge.b@college.edu    password123
--   aarav0@college.edu        password123
--   diya1@college.edu         password123
--   karthik2@college.edu      password123
--   sneha3@college.edu        password123
--   rohan4@college.edu        password123
--   priya5@college.edu        password123
--   vikram6@college.edu       password123
--   ananya7@college.edu       password123
--
-- THEN run this whole file.
-- ============================================================

-- ---------- DEPARTMENTS & SECTIONS ----------

insert into departments (code, name) values ('CSE', 'Computer Science & Engineering')
on conflict (code) do nothing;

insert into sections (department_code, name, semester) values
  ('CSE', 'A', 3), ('CSE', 'B', 3)
on conflict do nothing;

-- ---------- PROFILES ----------
-- Employee IDs for staff, roll numbers for students — these are what
-- they'll type on the login screen instead of their email.

insert into profiles (id, name, email, role, department, section, employee_id)
select id, 'Dr. Ramesh Rao', email, 'hod', 'CSE', null, 'EMP001'
from auth.users where email = 'hod@college.edu'
on conflict (id) do nothing;

insert into profiles (id, name, email, role, department, section, employee_id)
select id, 'Prof. Anitha Kumar', email, 'incharge', 'CSE', 'A', 'EMP002'
from auth.users where email = 'incharge.a@college.edu'
on conflict (id) do nothing;

insert into profiles (id, name, email, role, department, section, employee_id)
select id, 'Prof. Suresh Babu', email, 'incharge', 'CSE', 'B', 'EMP003'
from auth.users where email = 'incharge.b@college.edu'
on conflict (id) do nothing;

insert into profiles (id, name, email, role, department, section, roll_no, semester, phone, blood_group, parent_name, parent_phone)
select id, 'Aarav Sharma', email, 'student', 'CSE', 'A', 'CSEA001', 3, '9876543210', 'O+', 'Rajesh Sharma', '9876500001'
from auth.users where email = 'aarav0@college.edu'
on conflict (id) do nothing;

insert into profiles (id, name, email, role, department, section, roll_no, semester, phone, blood_group, parent_name, parent_phone)
select id, 'Diya Patel', email, 'student', 'CSE', 'A', 'CSEA002', 3, '9876543211', 'A+', 'Nikhil Patel', '9876500002'
from auth.users where email = 'diya1@college.edu'
on conflict (id) do nothing;

insert into profiles (id, name, email, role, department, section, roll_no, semester, phone, blood_group, parent_name, parent_phone)
select id, 'Karthik Reddy', email, 'student', 'CSE', 'A', 'CSEA003', 3, '9876543212', 'B+', 'Srinivas Reddy', '9876500003'
from auth.users where email = 'karthik2@college.edu'
on conflict (id) do nothing;

insert into profiles (id, name, email, role, department, section, roll_no, semester, phone, blood_group, parent_name, parent_phone)
select id, 'Sneha Iyer', email, 'student', 'CSE', 'A', 'CSEA004', 3, '9876543213', 'AB+', 'Mohan Iyer', '9876500004'
from auth.users where email = 'sneha3@college.edu'
on conflict (id) do nothing;

insert into profiles (id, name, email, role, department, section, roll_no, semester, phone, blood_group, parent_name, parent_phone)
select id, 'Rohan Gupta', email, 'student', 'CSE', 'B', 'CSEB001', 3, '9876543214', 'O-', 'Anil Gupta', '9876500005'
from auth.users where email = 'rohan4@college.edu'
on conflict (id) do nothing;

insert into profiles (id, name, email, role, department, section, roll_no, semester, phone, blood_group, parent_name, parent_phone)
select id, 'Priya Nair', email, 'student', 'CSE', 'B', 'CSEB002', 3, '9876543215', 'A-', 'Suresh Nair', '9876500006'
from auth.users where email = 'priya5@college.edu'
on conflict (id) do nothing;

insert into profiles (id, name, email, role, department, section, roll_no, semester, phone, blood_group, parent_name, parent_phone)
select id, 'Vikram Singh', email, 'student', 'CSE', 'B', 'CSEB003', 3, '9876543216', 'B-', 'Ranjit Singh', '9876500007'
from auth.users where email = 'vikram6@college.edu'
on conflict (id) do nothing;

insert into profiles (id, name, email, role, department, section, roll_no, semester, phone, blood_group, parent_name, parent_phone)
select id, 'Ananya Das', email, 'student', 'CSE', 'B', 'CSEB004', 3, '9876543217', 'AB-', 'Bikash Das', '9876500008'
from auth.users where email = 'ananya7@college.edu'
on conflict (id) do nothing;

-- ---------- FACULTY ----------

insert into faculty (name, employee_id, department, designation, phone, email) values
  ('Dr. Ramesh Rao', 'EMP001', 'CSE', 'HOD & Professor', '9000000001', 'hod@college.edu'),
  ('Prof. Anitha Kumar', 'EMP002', 'CSE', 'Assistant Professor', '9000000002', 'incharge.a@college.edu'),
  ('Prof. Suresh Babu', 'EMP003', 'CSE', 'Assistant Professor', '9000000003', 'incharge.b@college.edu'),
  ('Dr. Lakshmi Menon', 'EMP004', 'CSE', 'Professor', '9000000004', 'lakshmi@college.edu'),
  ('Prof. Vinod Kumar', 'EMP005', 'CSE', 'Associate Professor', '9000000005', 'vinod@college.edu')
on conflict (employee_id) do nothing;

-- ---------- SUBJECTS ----------

insert into subjects (code, name, department, semester, faculty_name, credits) values
  ('CS301', 'Data Structures', 'CSE', 3, 'Prof. Anitha Kumar', 4),
  ('CS302', 'Operating Systems', 'CSE', 3, 'Dr. Lakshmi Menon', 4),
  ('CS303', 'DBMS', 'CSE', 3, 'Prof. Suresh Babu', 4),
  ('CS304', 'Computer Networks', 'CSE', 3, 'Prof. Vinod Kumar', 3)
on conflict do nothing;

-- ---------- MARKS (with internal1/internal2/assignment/lab breakdown) ----------

insert into marks (student_id, subject, semester, internal1, internal2, assignment, lab, semester_exam, max_marks, backlog)
select p.id, s.name, 3, 18+((row_number() over())%10), 16+((row_number() over())%10), 8+((row_number() over())%3),
       9+((row_number() over())%2), 45+((row_number() over())%40), 100,
       (45+((row_number() over())%40)) < 40
from profiles p
cross join subjects s
where p.role = 'student' and p.roll_no != 'CSEA003' and s.department = 'CSE' and s.semester = 3;

-- Karthik Reddy (CSEA003) has a deliberate backlog example
insert into marks (student_id, subject, semester, internal1, internal2, assignment, lab, semester_exam, max_marks, backlog)
select p.id, s.name, 3, 12, 10, 6, 7, 28, 100, true
from profiles p cross join subjects s
where p.roll_no = 'CSEA003' and s.code = 'CS304';

insert into marks (student_id, subject, semester, internal1, internal2, assignment, lab, semester_exam, max_marks, backlog)
select p.id, s.name, 3, 17, 19, 9, 8, 62, 100, false
from profiles p cross join subjects s
where p.roll_no = 'CSEA003' and s.code != 'CS304';

-- ---------- SEMESTER RESULTS ----------

insert into semester_results (student_id, semester, sgpa, cgpa, credits_earned, backlogs, status)
select id, 3, 7.8, 7.6, 15, 0, 'pass' from profiles where role = 'student' and roll_no != 'CSEA003';

insert into semester_results (student_id, semester, sgpa, cgpa, credits_earned, backlogs, status)
select id, 3, 5.2, 6.1, 11, 1, 'fail' from profiles where roll_no = 'CSEA003';

-- ---------- TIMETABLE ----------

insert into timetable (department, section, day, period, time_slot, subject, faculty_name, room_number)
select 'CSE', sec, day, period, time_slot, subject, faculty_name, room
from (values ('A'), ('B')) as s(sec)
cross join (values ('Monday'), ('Tuesday'), ('Wednesday'), ('Thursday'), ('Friday')) as d(day)
cross join (values
  (1, '9:00 - 10:00', 'Data Structures', 'Prof. Anitha Kumar', 'CS-101'),
  (2, '10:00 - 11:00', 'Operating Systems', 'Dr. Lakshmi Menon', 'CS-102'),
  (3, '11:15 - 12:15', 'DBMS', 'Prof. Suresh Babu', 'CS-103'),
  (4, '1:00 - 2:00', 'Computer Networks', 'Prof. Vinod Kumar', 'CS-104')
) as pd(period, time_slot, subject, faculty_name, room);

-- ---------- SAMPLE EVENTS / NEWS / HOLIDAY ----------

insert into events (title, description, type, department, venue, event_date, event_time, posted_by)
select 'Tech Fest 2026', 'Annual technical festival with coding contests, robotics, and paper presentations.',
  'event', 'CSE', 'Main Auditorium', current_date + 20, '10:00 AM', id
from profiles where role = 'hod';

insert into events (title, description, type, department, posted_by)
select 'Mid-Semester Exams from Aug 20', 'Timetable will be shared by respective incharges shortly.',
  'news', 'CSE', id
from profiles where role = 'hod';

insert into events (title, description, type, department, event_date, posted_by)
select 'Independence Day Holiday', 'College will remain closed on account of Independence Day.',
  'holiday', 'ALL', '2026-08-15', id
from profiles where role = 'hod';

-- ---------- SAMPLE ATTENDANCE (past 7 days) ----------

insert into attendance (student_id, date, status, marked_by)
select p.id, d.date,
  case when (extract(day from d.date)::int + right(p.roll_no,1)::int) % 5 = 0 then 'absent' else 'present' end,
  'incharge'
from profiles p
cross join (select (current_date - i) as date from generate_series(1,6) as i) d
where p.role = 'student'
on conflict (student_id, date, subject_id) do nothing;

-- ---------- SAMPLE LEAVE REQUEST ----------

insert into leave_requests (student_id, reason_type, reason_text, from_date, to_date, status)
select id, 'Medical', 'Fever and viral infection, doctor advised 2 days rest.', current_date-2, current_date-1, 'Approved'
from profiles where roll_no = 'CSEA002';

insert into leave_requests (student_id, reason_type, reason_text, from_date, to_date, status)
select id, 'Personal', 'Family function out of town.', current_date+3, current_date+4, 'Pending'
from profiles where roll_no = 'CSEB001';

-- ---------- SAMPLE NOTIFICATIONS ----------

insert into notifications (title, message, type, department, section)
select 'Attendance Updated', 'Your attendance for this week has been updated by your incharge.', 'attendance', 'CSE', 'A';

insert into notifications (title, message, type, department)
select 'Tech Fest 2026', 'Registrations are now open for Tech Fest 2026.', 'event', 'CSE';
