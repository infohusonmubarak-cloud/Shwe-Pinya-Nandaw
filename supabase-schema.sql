-- =====================================================================
-- Shwe Pinya Nandaw Private High School — Supabase schema
-- =====================================================================
-- HOW TO USE:
-- 1. Create a free project at https://supabase.com
-- 2. Open the SQL Editor (left sidebar) → New query
-- 3. Paste this whole file → Run
-- 4. Go to Authentication → Users → Add user, create a login for whoever
--    will review applications/donations/messages (this is your "admin login")
-- 5. Go to Project Settings → API → copy your Project URL and the
--    "anon" / "publishable" public key → paste into SUPABASE_CONFIG in
--    each HTML file (see supabase-config.js)
--
-- WHY THE GRANT STATEMENTS: Supabase changed its default in May 2026 —
-- new tables are no longer automatically reachable through the API.
-- Row Level Security (RLS) controls *which rows* a role can see;
-- GRANT controls whether a role can touch the table *at all*. Both are
-- required together, which is why every table below has both.
-- =====================================================================

create extension if not exists "pgcrypto"; -- for gen_random_uuid()

-- =====================================================================
-- 1. ADMISSIONS — applications submitted via form.html
-- =====================================================================
create table if not exists public.admissions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  gender text,
  dob date,
  nationality text,
  email text not null,
  phone text not null,
  father_name text,
  mother_name text,
  address text,
  previous_school text,
  previous_gpa text,
  class_applied text not null,
  group_stream text,
  photo_path text,          -- path inside the 'admission-uploads' storage bucket
  certificate_path text,    -- path inside the 'admission-uploads' storage bucket
  status text not null default 'pending' check (status in ('pending','reviewed','accepted','rejected')),
  submitted_at timestamptz not null default now()
);

alter table public.admissions enable row level security;

-- Applicants (anonymous public visitors) may only INSERT their own
-- application — they can never read, edit, or delete any row, including
-- their own, once submitted. Only school staff (authenticated) can review.
create policy "public can submit admissions" on public.admissions
  for insert to anon with check (true);

create policy "staff can view admissions" on public.admissions
  for select to authenticated using (true);

create policy "staff can update admissions" on public.admissions
  for update to authenticated using (true);

create policy "staff can delete admissions" on public.admissions
  for delete to authenticated using (true);

grant insert on public.admissions to anon;
grant select, insert, update, delete on public.admissions to authenticated;


-- =====================================================================
-- 2. CONTACT MESSAGES — submitted via contact.html
-- =====================================================================
create table if not exists public.contact_messages (
  id uuid primary key default gen_random_uuid(),
  first_name text not null,
  last_name text not null,
  email text not null,
  phone text,
  subject text,
  message text not null,
  status text not null default 'unread' check (status in ('unread','read')),
  submitted_at timestamptz not null default now()
);

alter table public.contact_messages enable row level security;

create policy "public can send messages" on public.contact_messages
  for insert to anon with check (true);

create policy "staff can view messages" on public.contact_messages
  for select to authenticated using (true);

create policy "staff can update messages" on public.contact_messages
  for update to authenticated using (true);

create policy "staff can delete messages" on public.contact_messages
  for delete to authenticated using (true);

grant insert on public.contact_messages to anon;
grant select, insert, update, delete on public.contact_messages to authenticated;


-- =====================================================================
-- 3. DONATIONS — submitted via donate.html
-- =====================================================================
create table if not exists public.donations (
  id uuid primary key default gen_random_uuid(),
  donor_name text not null,
  donor_phone text not null,
  donor_email text,
  donor_nid text,
  amount numeric,
  purpose text,
  donor_message text,
  payment_method text not null,
  transaction_ref text not null,
  verified boolean not null default false,
  submitted_at timestamptz not null default now()
);

alter table public.donations enable row level security;

create policy "public can submit donations" on public.donations
  for insert to anon with check (true);

create policy "staff can view donations" on public.donations
  for select to authenticated using (true);

create policy "staff can update donations" on public.donations
  for update to authenticated using (true);

create policy "staff can delete donations" on public.donations
  for delete to authenticated using (true);

grant insert on public.donations to anon;
grant select, insert, update, delete on public.donations to authenticated;


-- =====================================================================
-- 4. RESULTS — read by everyone via result.html, written only by staff
-- =====================================================================
create table if not exists public.results (
  id uuid primary key default gen_random_uuid(),
  student_name text not null,
  roll_number text not null,
  class_name text not null,       -- e.g. "Class 10 (SSC 2025)"
  exam_year text not null,
  group_stream text,
  gpa numeric,
  subjects jsonb not null default '[]',  -- [{"subject":"Bangla","grade":"A+","points":5.0,"status":"Excellent"}, ...]
  published boolean not null default true,
  created_at timestamptz not null default now(),
  unique (roll_number, class_name, exam_year)
);

alter table public.results enable row level security;

-- Anyone can look up a PUBLISHED result — this powers the public search tool.
-- Nothing else about a result (who searched, etc.) is stored.
create policy "public can view published results" on public.results
  for select to anon using (published = true);

create policy "staff can view all results" on public.results
  for select to authenticated using (true);

create policy "staff can insert results" on public.results
  for insert to authenticated with check (true);

create policy "staff can update results" on public.results
  for update to authenticated using (true);

create policy "staff can delete results" on public.results
  for delete to authenticated using (true);

grant select on public.results to anon;
grant select, insert, update, delete on public.results to authenticated;

-- Seed the one sample result so the site behaves the same as the old demo
insert into public.results (student_name, roll_number, class_name, exam_year, group_stream, gpa, subjects)
values (
  'Md. Arif Hossain', '2025-1042', 'Class 10 (SSC 2025)', '2025', 'Science', 5.0,
  '[
    {"subject":"Bangla","grade":"A+","points":5.0,"status":"Excellent"},
    {"subject":"English","grade":"A+","points":5.0,"status":"Excellent"},
    {"subject":"Mathematics","grade":"A+","points":5.0,"status":"Excellent"},
    {"subject":"Physics","grade":"A+","points":5.0,"status":"Excellent"},
    {"subject":"Chemistry","grade":"A+","points":5.0,"status":"Excellent"},
    {"subject":"Biology","grade":"A+","points":5.0,"status":"Excellent"},
    {"subject":"Higher Mathematics","grade":"A+","points":5.0,"status":"Excellent"},
    {"subject":"ICT","grade":"A+","points":5.0,"status":"Excellent"}
  ]'::jsonb
)
on conflict (roll_number, class_name, exam_year) do nothing;


-- =====================================================================
-- 5. CERTIFICATES — issued by staff, looked up by students via certificate.html
-- =====================================================================
create table if not exists public.certificates (
  id uuid primary key default gen_random_uuid(),
  student_name text not null,
  roll_number text not null,
  class_name text not null,
  certificate_type text not null default 'Character Certificate'
    check (certificate_type in ('Character Certificate','Transfer Certificate','Study Certificate','Provisional Certificate')),
  certificate_number text,
  academic_year text,
  issue_date date not null default current_date,
  remarks text,
  published boolean not null default true,
  created_at timestamptz not null default now(),
  unique (roll_number, class_name, certificate_type)
);

alter table public.certificates enable row level security;

-- Same public-read-if-published pattern as results: anyone can look up a
-- published certificate; only staff can issue, edit, or withdraw one.
create policy "public can view published certificates" on public.certificates
  for select to anon using (published = true);

create policy "staff can view all certificates" on public.certificates
  for select to authenticated using (true);

create policy "staff can insert certificates" on public.certificates
  for insert to authenticated with check (true);

create policy "staff can update certificates" on public.certificates
  for update to authenticated using (true);

create policy "staff can delete certificates" on public.certificates
  for delete to authenticated using (true);

grant select on public.certificates to anon;
grant select, insert, update, delete on public.certificates to authenticated;


-- =====================================================================
-- 6. STORAGE — admission photo & certificate uploads
-- =====================================================================
-- Private bucket: applicants can upload but never list/read files
-- (their own or anyone else's). Only authenticated staff can read them
-- back (via the dashboard's Storage browser, or a signed URL).
--
-- file_size_limit and allowed_mime_types are enforced by Storage itself,
-- server-side — the 5MB check in form.html's JS is a UX nicety only and
-- does nothing to stop someone calling the API directly, so the real
-- limit has to live here.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('admission-uploads', 'admission-uploads', false, 5242880,
  array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update set
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "public can upload admission files" on storage.objects
  for insert to anon
  with check (bucket_id = 'admission-uploads');

create policy "staff can view admission files" on storage.objects
  for select to authenticated
  using (bucket_id = 'admission-uploads');

create policy "staff can delete admission files" on storage.objects
  for delete to authenticated
  using (bucket_id = 'admission-uploads');
