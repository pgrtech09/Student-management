# Vidya Campus — Student Management System (Full ERP)

A complete college ERP built with **only** HTML5, CSS3, vanilla JavaScript (ES6),
and a PWA shell on the frontend — and **Supabase** (Postgres + Auth + Storage +
Realtime + Row Level Security) as the entire backend. No Node.js, no frameworks,
no paid services. Hosted on **GitHub Pages**.

## What's included, module by module

1. **Database** (`supabase/schema.sql`) — 14 tables, RLS policies, helper functions
2. **Storage** (`supabase/storage.sql`) — buckets for profile photos, medical
   certificates, and event posters, each with proper access policies
3. **Seed data** (`supabase/seed.sql`) — departments, sections, faculty, subjects,
   demo students/incharges/HOD, sample attendance/marks/timetable/events
4. **Login** (`login.html`) — sign in with Roll Number / Employee ID / Email,
   show/hide password, remember me, forgot password
5. **Registration** (`register.html`) — student self-registration; password is
   auto-set to DOB (DDMMYYYY)
6. **Student Dashboard** (`student/index.html`) — attendance (overall, subject-wise,
   monthly trend chart, prediction to reach 75%), marks (internals/assignment/lab/
   semester breakdown, SGPA/CGPA/backlogs/result history), timetable, leave
   requests with certificate upload, events with registration, profile edit +
   photo upload + change password, "I'm here in college" GPS check-in
7. **Incharge Dashboard** (`incharge/index.html`) — student list with search,
   attendance entry (bulk + per-student), leave approve/reject with remarks,
   marks upload, reports (below-75%, top students, backlogs, today's attendance)
   with CSV/PDF export, class notices
8. **HOD Dashboard** (`hod/index.html`) — department overview with chart, manage
   students (view/delete), manage faculty, manage timetable, manage subjects,
   publish notices/news/holidays/events (with poster upload), department-wide
   reports with CSV/PDF export
9. **Realtime Notifications** — a live bell icon on every dashboard, powered by
   Supabase Realtime — attendance updates, marks updates, leave status changes,
   and HOD announcements all push instantly, no page refresh needed
10. **PWA** (`manifest.json`, `service-worker.js`, `assets/icons/`) — installable
    on any device, works offline for the app shell, install button on login page

## Project structure

```
/
├── index.html              # Session redirect (→ login or dashboard)
├── login.html               # Sign in
├── register.html             # Student self-registration
├── offline.html                # Shown when offline & page not cached
├── manifest.json                # PWA manifest
├── service-worker.js              # Offline app-shell caching
├── css/
│   └── style.css                    # Design system (light + dark mode)
├── js/
│   ├── config.js                      # Supabase URL + anon key
│   └── app.js                          # Auth, theme, realtime, charts, exports
├── student/
│   └── index.html                        # Student dashboard (all modules as tabs)
├── incharge/
│   └── index.html                          # Incharge dashboard
├── hod/
│   └── index.html                            # HOD dashboard
├── assets/icons/                                # PWA icons
└── supabase/
    ├── schema.sql                                  # Tables + RLS — run 1st
    ├── storage.sql                                    # Buckets — run 2nd
    └── seed.sql                                         # Demo data — run 4th (after creating users)
```

> **Why one HTML file per role instead of many small pages?** The spec asked for
> a `student/`, `incharge/`, `hod/` folder structure, which this follows — but
> each role's many modules (attendance, marks, leave, etc.) are built as
> tab-switching sections within that one page rather than dozens of separate
> files. This keeps shared state (like the notification bell and loaded data)
> in one place and avoids re-fetching everything on every click, while still
> matching the requested folder layout.

---

## SUPABASE SETUP — do this first, in exact order

### 1. Run the schema
Supabase Dashboard → **SQL Editor → New query** → paste all of
`supabase/schema.sql` → **Run**.

### 2. Run the storage setup
SQL Editor → New query → paste all of `supabase/storage.sql` → **Run**.
This creates 3 buckets (`profile-photos`, `medical-certificates`, `event-posters`)
with access policies.

### 3. Turn off "Confirm email"
**Authentication → Providers → Email** → turn **off** "Confirm email".
Required for student self-registration and password reset to work smoothly —
without it, a new account can't be used until an email link is clicked.

### 4. Create the demo accounts
**Authentication → Users → Add User** — create these 11 (tick **Auto Confirm
User** on each):

| Email | Password |
|---|---|
| hod@college.edu | password123 |
| incharge.a@college.edu | password123 |
| incharge.b@college.edu | password123 |
| aarav0@college.edu | password123 |
| diya1@college.edu | password123 |
| karthik2@college.edu | password123 |
| sneha3@college.edu | password123 |
| rohan4@college.edu | password123 |
| priya5@college.edu | password123 |
| vikram6@college.edu | password123 |
| ananya7@college.edu | password123 |

### 5. Load the seed data
SQL Editor → New query → paste all of `supabase/seed.sql` → **Run**.
(Must run *after* step 4 — it looks up each user by email.)

### 6. Config is already set
`js/config.js` already has your Project URL + anon key. The anon key is safe
in frontend code by design — Row Level Security protects the data, not key
secrecy.

### How to log in with the demo accounts
The login page asks for **Roll Number / Employee ID / Email** — you can use
any of the three. For the demo accounts:

| Role | Type this to log in | Password |
|---|---|---|
| HOD | `EMP001` (or the email) | password123 |
| Incharge Section A | `EMP002` | password123 |
| Incharge Section B | `EMP003` | password123 |
| Student (Aarav) | `CSEA001` | password123 |
| Student (Diya) | `CSEA002` | password123 |
| Student (Karthik — has a backlog) | `CSEA003` | password123 |

---

## GITHUB SETUP

### 1. Create the repository
On GitHub, create a new repository (e.g. `Student-management`) — public or private.

### 2. Upload every file, preserving folders
Using GitHub's web uploader (**Add file → Upload files**) or `git push`, upload
the entire contents of this project **keeping the folder structure intact**:
`student/`, `incharge/`, `hod/`, `css/`, `js/`, `assets/icons/`, `supabase/` must
stay as folders, not get flattened.

Using git from the command line:
```bash
git init
git add .
git commit -m "Complete Student Management System — all modules"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/Student-management.git
git push -u origin main
```

### 3. Enable GitHub Pages
**Settings → Pages → Source: Deploy from branch → `main` → `/ (root)` → Save**.
Your app goes live at `https://YOUR_USERNAME.github.io/Student-management/`.

GitHub Pages serves over HTTPS automatically, which is required for the service
worker / PWA install to work — no extra setup needed.

### 4. Test it
1. Open the live URL — you should land on `login.html`
2. Log in as HOD (`EMP001` / `password123`) and check the department overview
3. Log in as Incharge (`EMP002` / `password123`) and mark today's attendance
4. Log in as Student (`CSEA001` / `password123`) and confirm you see that
   attendance update, then try the "I'm here in college" check-in
5. On your phone, open the site and tap **Install App** (or your browser's
   install icon) to add it to your home screen

---

## SECURITY MODEL (Row Level Security)

Every table has RLS enabled — the database itself enforces who can see and
write what, not just the app's JavaScript:

- A **student** can only ever read/write their own `attendance`, `marks`,
  `leave_requests`, and `location_checkins` rows.
- An **incharge**'s queries are restricted to students in their own
  `department` + `section` — enforced via the `current_department()` /
  `current_section()` helper functions, not by trusting the frontend.
- An **HOD**'s queries span their whole `department`.
- Only an **HOD** can insert into `events` (except incharges, who may post
  `type = 'announcement'` only, scoped to their own department).
- **Storage buckets** mirror the same rules — a student can only upload/read
  their own medical certificate; incharges/HODs can read certificates only
  for students in their own section/department.

Even if the frontend JavaScript were tampered with, the database refuses any
read or write outside these boundaries.

---

## WHAT'S SIMPLIFIED (be aware before relying on this in production)

Given the constraint of *zero backend code and zero paid libraries*, a few
things are intentionally simple rather than enterprise-grade:

- **"Export PDF"** opens the browser's native print dialog with a clean report
  layout (print → Save as PDF) rather than generating a true PDF file, since
  no PDF library is allowed.
- **Charts** are hand-drawn on `<canvas>` (bar chart for department stats,
  line chart for attendance trend) rather than using a charting library.
- **Realtime notifications** use Supabase Realtime (websockets) directly —
  genuinely live, not polling.
- **Faculty accounts**: adding a faculty member in HOD's "Manage Faculty" adds
  a *record* for reports/timetable display. To give that person an actual
  Incharge **login**, you still need to create their account in Supabase
  Authentication first (Authentication → Users → Add User), then insert their
  `profiles` row via SQL Editor with `role = 'incharge'` and their
  `employee_id` — mirroring how the demo incharges were seeded.
- **DOB-as-password** (student registration) is convenient but not very secure
  long-term — the student profile page includes a "Change Password" option to
  set something stronger afterward.

## Updating the app after changes

Bump `CACHE_NAME` in `service-worker.js` (e.g. `vidya-campus-shell-v2`) every
time you edit any HTML/CSS/JS file and push a new version — otherwise
installed/offline clients keep serving the old cached files.
