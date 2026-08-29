# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A static, dependency-free website for Shwe Pinya Nandaw Private High School, backed by
[Supabase](https://supabase.com) (Postgres + Auth + Storage) for form submissions, published
results, and certificate lookup. There is no build step, no bundler, no `node_modules`, and no
package.json. Every page is a self-contained HTML file with its CSS and JavaScript inline. The
only shared file is `supabase-config.js`.

## Running locally

Open `index.html` directly from disk and the Supabase calls will fail — the `file://` origin is
rejected by CORS. Serve the folder over HTTP instead:

```bash
python3 -m http.server 8000
# then visit http://127.0.0.1:8000/
```

There is nothing to install, compile, lint, or test — no test suite exists in this repo. Verify
changes by loading the affected page(s) in a browser over HTTP as above.

## Pages and their Supabase table

| File | Purpose | Supabase table |
|---|---|---|
| `index.html` | Single-page app: Home, About, Academics, Admissions, News, Gallery | — |
| `contact.html` | Contact form | `contact_messages` (insert) |
| `donate.html` | Donation instructions + pledge form | `donations` (insert) |
| `form.html` | Admission application, incl. photo/certificate upload | `admissions` (insert) + Storage |
| `result.html` | Public exam-result lookup by roll / class / year | `results` (select, published only) |
| `certificate.html` | Public certificate verification | `certificates` (select, published only) |
| `admin.html` | Staff dashboard — review everything, publish results & certificates | all five (authenticated) |

`index.html` holds all six of its sections in the DOM at once, each as a `<div class="page"
id="page-NAME">`. `showPage(name)` toggles the `active` class between them (unknown names fall
back to `page-home`) and mirrors the current section into the URL hash via
`history.replaceState`, so `index.html#admissions` works without pushing a history entry per
click. The other six pages are ordinary separate documents, linked normally — not part of the
SPA.

## Configuration

All configuration lives in `supabase-config.js` — the only file that needs editing, and every
page loads it (via `<script src="supabase-config.js">` after the supabase-js CDN script):

```js
const SUPABASE_URL      = 'https://<project-ref>.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_...';
```

Both values come from Supabase → Project Settings → API. There are no build-time env vars and no
server-side secrets — this is a purely static site, so anything it holds is visible to any
visitor. **Never put the `service_role` / secret key here or anywhere else in this repo** — only
the anon/publishable key belongs in browser code. Row Level Security (RLS) is the only thing
protecting the data; the publishable key grants exactly what the RLS policies grant.

If the config still holds placeholder values, or the supabase-js CDN can't be reached,
`supabaseReady` is `false`, `db` stays `null`, and every page degrades to a message from
`notConnectedMessage()` rather than throwing.

## Database (`supabase-schema.sql`, `supabase-fix-storage-limits.sql`)

Run in the Supabase SQL Editor. `supabase-schema.sql` creates all five tables, enables RLS on
each, creates the policies, and provisions the private `admission-uploads` storage bucket (5 MB
cap, JPEG/PNG/WebP/PDF only). Note the file's own comment: Supabase changed its default so new
tables aren't reachable through the API without an explicit `grant` — RLS controls *which rows* a
role sees, `grant` controls whether the role can touch the table *at all*, and every table needs
both.

`supabase-fix-storage-limits.sql` is only needed if `admission-uploads` already existed before
`supabase-schema.sql` was first run — `insert ... on conflict` won't retroactively apply size/MIME
limits to an existing bucket, and the main script can't be safely re-run in that state since
Postgres has no `create policy if not exists`.

Access model:

| Table | Public (anon) | Staff (authenticated) |
|---|---|---|
| `admissions` | insert only | select / update / delete |
| `contact_messages` | insert only | select / update / delete |
| `donations` | insert only | select / update / delete |
| `results` | select where `published = true` | full access |
| `certificates` | select where `published = true` | full access |

Storage bucket `admission-uploads` is private: anonymous visitors may upload into it but never
list or read files (their own or anyone else's); only authenticated staff can read or delete.

Staff accounts are created in Supabase → Authentication → Users → Add user; `admin.html`
authenticates via `supabase.auth.signInWithPassword` — there is no hardcoded password anywhere in
this repo.

When changing the schema, edit `supabase-schema.sql` (and keep `supabase-fix-storage-limits.sql`
in sync if storage limits change) rather than only applying changes by hand in the dashboard, so
the file stays the source of truth for a fresh setup.

## Conventions to follow when editing pages

- **`escapeHtml()`** — every value read back from the database and injected into `innerHTML` must
  go through `escapeHtml()` (defined locally in `admin.html` and `certificate.html`), in both text
  and attribute positions. Anyone holding the publishable key can insert arbitrary text into the
  three public-insert tables (`admissions`, `contact_messages`, `donations`), so treat every
  stored value as untrusted, especially in `admin.html` where it's rendered during a staff
  session.
- **Honeypot fields** — each public form (`contact.html`, `donate.html`, `form.html`) carries a
  hidden honeypot input (`hp_contact`, `hp_donate`, `hp_admission`, all `name="website"`,
  `tabindex="-1"`, `autocomplete="off"`); if it's filled on submit, discard silently rather than
  showing a validation error. Keep this pattern for any new public form.
- **Supabase readiness** — before calling `db`, check `supabaseReady` (or that `db` isn't null)
  and fall back to `notConnectedMessage()`, matching the existing pages, instead of letting a null
  client throw and take down the rest of the page's JS.
- **File uploads** — `form.html`'s client-side 5 MB check is a UX nicety only; the real limit is
  enforced server-side by the storage bucket's `file_size_limit`/`allowed_mime_types` in
  `supabase-schema.sql`. Don't rely on client-side validation alone for anything security-relevant.
- Keep new pages self-contained (inline CSS/JS) and load `supabase-config.js` the same way the
  existing pages do, rather than introducing a bundler or a new shared script file.

## Deployment

No build command, no output directory — the site deploys as-is.

- **Vercel**: import the repo, framework preset "Other". `vercel.json` sets security headers
  (`X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`) on every
  response and marks `*.sql` files `noindex`.
- **GitHub Pages**: supported via the empty `.nojekyll` file, which stops Pages from running the
  files through Jekyll — required, or the build fails.

After deploying, add the production origin to Supabase → Authentication → URL Configuration so
redirects and auth work from the live domain.
