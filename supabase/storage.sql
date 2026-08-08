-- ============================================================
-- Vidya Campus — MODULE 2: Storage Buckets
-- Run AFTER schema.sql. Go to SQL Editor → New query → paste → Run.
-- ============================================================

-- ---------- CREATE BUCKETS ----------
-- (public = true means anyone with the URL can view the file — fine for
-- profile photos and event posters. Files are still only uploadable by
-- authorized users, enforced by the policies below.)

insert into storage.buckets (id, name, public)
values ('profile-photos', 'profile-photos', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('medical-certificates', 'medical-certificates', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('event-posters', 'event-posters', true)
on conflict (id) do nothing;

-- ---------- PROFILE PHOTOS ----------
-- Path convention: {user_id}/{filename}. Anyone can view (public bucket);
-- only the owner can upload/update/delete their own folder.

create policy "anyone can view profile photos" on storage.objects for select
  using (bucket_id = 'profile-photos');

create policy "user uploads own profile photo" on storage.objects for insert
  with check (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "user updates own profile photo" on storage.objects for update
  using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "user deletes own profile photo" on storage.objects for delete
  using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------- MEDICAL CERTIFICATES ----------
-- Private bucket. Path convention: {student_id}/{filename}.
-- Student can upload/view their own; incharge/hod of their department can view.

create policy "student uploads own certificate" on storage.objects for insert
  with check (bucket_id = 'medical-certificates' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "student views own certificate" on storage.objects for select
  using (bucket_id = 'medical-certificates' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "incharge views section certificates" on storage.objects for select
  using (
    bucket_id = 'medical-certificates'
    and public.current_role() = 'incharge'
    and exists (
      select 1 from profiles p
      where p.id::text = (storage.foldername(name))[1]
        and p.department = public.current_department()
        and p.section = public.current_section()
    )
  );

create policy "hod views department certificates" on storage.objects for select
  using (
    bucket_id = 'medical-certificates'
    and public.current_role() = 'hod'
    and exists (
      select 1 from profiles p
      where p.id::text = (storage.foldername(name))[1]
        and p.department = public.current_department()
    )
  );

-- ---------- EVENT POSTERS ----------
-- Public bucket. Only HOD can upload (posts events); anyone can view.

create policy "anyone can view event posters" on storage.objects for select
  using (bucket_id = 'event-posters');

create policy "hod uploads event posters" on storage.objects for insert
  with check (bucket_id = 'event-posters' and public.current_role() = 'hod');

create policy "hod manages own event posters" on storage.objects for update
  using (bucket_id = 'event-posters' and public.current_role() = 'hod');

create policy "hod deletes own event posters" on storage.objects for delete
  using (bucket_id = 'event-posters' and public.current_role() = 'hod');
