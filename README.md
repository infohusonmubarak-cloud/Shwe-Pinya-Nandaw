# Shwe Pinya Nandaw Private High School — Website

A static, dependency-free website for Shwe Pinya Nandaw Private High School,
backed by [Supabase](https://supabase.com) for form submissions, published
results, and certificate lookup.

There is no build step, no bundler, and no `node_modules`. Every page is a
self-contained HTML file with its CSS and JavaScript inline. The only shared
file is `supabase-config.js`.

---

## Pages

| File | Purpose | Supabase table |
|---|---|---|
| `index.html` | Single-page app: Home, About, Academics, Admissions, News, Gallery | — |
| `contact.html` | Contact form | `contact_messages` (insert) |
| `donate.html` | Donation instructions + pledge form | `donations` (insert) |
| `form.html` | Admission application, incl. photo/certificate upload | `admissions` (insert) + Storage |
| `result.html` | Public exam-result lookup by roll / class / year | `results` (select, published only) |
| `certificate.html` | Public certificate verification | `certificates` (select, published only) |
| `admin.html` | Staff dashboard — review everything, publish results & certificates | all five (authenticated) |

### How the SPA routing works

`index.html` holds all six of its sections in the DOM at once, each as a
`<div class="page" id="page-NAME">`. `showPage(name)` removes the `active`
class from every `.page` and adds it to the requested one; an unknown name
falls back to `page-home`. It then mirrors the current section into the URL
hash via `history.replaceState`, so the address bar reads `#academics`
without pushing a history entry per click. On `DOMContentLoaded` the page
reads `location.hash` back and restores that section, which is what makes
links like `index.html#admissions` work from the standalone pages.

The other six pages are ordinary separate documents — they are not part of
the SPA and are linked normally.

---

## Running locally

Open `index.html` directly from disk and the Supabase calls will fail: the
`file://` origin is rejected by CORS. Serve the folder over HTTP instead —
any static server works:

```bash
python3 -m http.server 8000
# then visit http://127.0.0.1:8000/
```

That is the whole local setup. There is nothing to install and nothing to
compile.

---

## Configuration

All configuration lives in **`supabase-config.js`** — it is the only file
that needs editing, and every page loads it.

```js
const SUPABASE_URL      = 'https://<project-ref>.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_...';
```

Both values come from **Supabase → Project Settings → API**.

There are no build-time environment variables and no server-side secrets.
This is a purely static site, so anything it holds is visible to any
visitor. That is fine for the two values above — the anon / publishable key
is *designed* to ship in browser code — but it means:

> **Row Level Security is the only thing protecting the data.** The
> publishable key grants exactly what the RLS policies grant and nothing
> more. Never put the `service_role` / secret key in this file or anywhere
> else in this repo.

If the config still holds placeholders, or if the supabase-js CDN can't be
reached, `supabaseReady` is `false`, `db` stays `null`, and every page
degrades to a readable message from `notConnectedMessage()` rather than
throwing.

---

## Database setup

Run the SQL in the Supabase dashboard (**SQL Editor → New query**):

1. **`supabase-schema.sql`** — creates the five tables, enables RLS on each,
   creates the policies, and provisions the private `admission-uploads`
   storage bucket (5 MB cap, JPEG/PNG/WebP/PDF only).
2. **`supabase-fix-storage-limits.sql`** — only needed if the
   `admission-uploads` bucket already existed before the schema was first
   run, since `insert … on conflict` won't otherwise re-apply the size and
   MIME limits.

### Access model

| Table | Public (anon) | Staff (authenticated) |
|---|---|---|
| `admissions` | insert only | select / update / delete |
| `contact_messages` | insert only | select / update / delete |
| `donations` | insert only | select / update / delete |
| `results` | select where `published = true` | full access |
| `certificates` | select where `published = true` | full access |

Storage: `admission-uploads` is a **private** bucket. Anonymous visitors may
upload into it; only authenticated staff can read or delete.

### Staff accounts

`admin.html` authenticates with `supabase.auth.signInWithPassword` — there is
no hardcoded password anywhere in this repo. Create staff logins in
**Supabase → Authentication → Users → Add user**.

---

## Deployment

The site deploys as-is: no build command, no output directory.

**Vercel** — import the repository and accept the defaults (framework
preset: Other). `vercel.json` sets security headers on every response
(`X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`,
`Permissions-Policy`) and marks `supabase-schema.sql` `noindex`.

**GitHub Pages** — supported via the empty `.nojekyll` file, which stops
Pages from running the files through Jekyll. Without it the build fails.

After deploying, add the production origin to **Supabase → Authentication →
URL Configuration** so redirects and auth work from the live domain.

---

## Spam and abuse handling

- Each public form carries a hidden honeypot field (`hp_contact`,
  `hp_donate`, `hp_admission`); a submission that fills one is discarded.
- `form.html` checks file size client-side, and the storage bucket enforces
  the same 5 MB limit and MIME allowlist server-side.
- All values read back from the database are escaped with `escapeHtml()`
  before being rendered, in both text and attribute positions. Anyone
  holding the publishable key can insert arbitrary text into the three
  public-insert tables, so **treat every stored value as untrusted** — the
  staff dashboard renders it while a staff session is active.

---

## Before going live

- [ ] Replace the placeholder bKash / Nagad / bank details in `donate.html`
      and remove the "donations paused" notice block above them.
- [ ] Confirm RLS is enabled on all five tables and the policies match the
      table above.
- [ ] Confirm `admission-uploads` is private.
- [ ] Create at least one staff user.
