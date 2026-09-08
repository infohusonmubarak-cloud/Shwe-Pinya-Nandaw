-- =====================================================================
-- FIX: apply upload limits to an EXISTING admission-uploads bucket
-- =====================================================================
-- WHY THIS FILE EXISTS
-- An earlier version of supabase-schema.sql created the storage bucket
-- with "on conflict (id) do nothing" and no limits. If that version ran
-- first, the bucket already existed by the time the hardened version
-- was applied, so file_size_limit and allowed_mime_types were never set.
--
-- Symptom: a 6MB file and a text/plain file both upload successfully,
-- even though form.html's JavaScript caps uploads at 5MB. That JS check
-- is only a convenience for real users — anyone calling the Storage API
-- directly bypasses it entirely, so the bucket itself must enforce this.
--
-- Re-running the full supabase-schema.sql does NOT fix this: Postgres
-- has no "create policy if not exists", so the script fails partway on
-- the policies that already exist.
--
-- HOW TO USE
-- Supabase dashboard -> SQL Editor -> New query -> paste this -> Run.
-- Safe to run more than once.
-- =====================================================================

update storage.buckets
set
  file_size_limit = 5242880,  -- 5MB, matching the check in form.html
  allowed_mime_types = array['image/jpeg','image/png','image/webp','application/pdf'],
  public = false              -- re-assert: this bucket must never be public
where id = 'admission-uploads';

-- Confirm it applied. Expected: one row, 5242880, the four MIME types,
-- public = false. If you get zero rows, the bucket does not exist yet —
-- run section 6 of supabase-schema.sql instead.
select id, public, file_size_limit, allowed_mime_types
from storage.buckets
where id = 'admission-uploads';


-- =====================================================================
-- CLEANUP: remove verification probe files
-- =====================================================================
-- Testing the (missing) limits required actually attempting uploads, so
-- two junk files were written to the bucket. Names start with
-- 'limit-probe-' and 'mime-probe-'. One is ~6MB.
--
-- These CANNOT be deleted from SQL. An earlier version of this file tried
-- "delete from storage.objects ... where bucket_id = 'admission-uploads'"
-- and Supabase rejected it:
--
--   ERROR: 42501: ... storage.protect_delete()
--
-- Supabase guards storage.objects with a trigger so rows cannot be removed
-- out from under the storage backend, which would leave the actual file
-- orphaned in S3 with no row pointing at it. Deletion has to go through
-- the Storage API, which removes both.
--
-- That failure was worse than a no-op: the SQL Editor runs a query tab as
-- ONE transaction, so the error rolled back the update above it too, and
-- the bucket kept its old (missing) limits while appearing to have been
-- fixed. Do not add a delete statement back here.
--
-- To remove the probe files: Supabase dashboard -> Storage ->
-- admission-uploads -> tick the 'limit-probe-*' and 'mime-probe-*' files
-- -> Delete. (The dashboard goes through the Storage API, so this works.)

-- Read-only: lists what is currently in the bucket, so you can see the
-- probe files before deleting them and confirm they are gone afterwards.
select name, created_at
from storage.objects
where bucket_id = 'admission-uploads'
order by created_at desc
limit 20;
