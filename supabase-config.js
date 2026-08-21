// =====================================================================
// Shwe Pinya Nandaw — Supabase configuration
// =====================================================================
// SETUP: after creating your Supabase project and running supabase-schema.sql,
// go to Project Settings → API and copy:
//   - "Project URL"                → paste into SUPABASE_URL below
//   - "anon" / "publishable" key   → paste into SUPABASE_ANON_KEY below
// (Never paste the "service_role" / "secret" key here — that one must
// never appear in a browser-facing file. The anon/publishable key is
// the only one that's safe to put in public HTML/JS.)
//
// This is the ONLY file that needs your real values — every page
// (contact, donate, form, result, admin) loads this one config.
// =====================================================================

const SUPABASE_URL = 'https://pgocytcgxcbzqvntnitb.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_0FLoOrtR5FlVkAIKmtoo8g_3DUUXDH3';

// `supabase` is the global published by the supabase-js CDN <script>. If that
// request is blocked or the CDN is unreachable, the global is missing — treat
// that the same as "not configured" so pages fall back to notConnectedMessage()
// instead of throwing a ReferenceError and taking the rest of the page's JS
// down with it.
const supabaseLibLoaded = typeof supabase !== 'undefined'
  && typeof supabase.createClient === 'function';

const supabaseReady = supabaseLibLoaded
  && SUPABASE_URL.indexOf('YOUR_SUPABASE') === -1
  && SUPABASE_ANON_KEY.indexOf('YOUR_SUPABASE') === -1;

// Guard against calling createClient with placeholder values (throws otherwise)
const db = supabaseReady
  ? supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
  : null;

function notConnectedMessage() {
  if (!supabaseLibLoaded) {
    return "Couldn't reach the database library — please check your connection and reload.";
  }
  return "This isn't connected to the database yet — see supabase-config.js for setup steps.";
}
