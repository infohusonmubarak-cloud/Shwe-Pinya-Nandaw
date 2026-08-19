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

const SUPABASE_URL = 'YOUR_SUPABASE_PROJECT_URL';       // e.g. https://xyzcompany.supabase.co
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';      // the public anon/publishable key

const supabaseReady = SUPABASE_URL.indexOf('YOUR_SUPABASE') === -1
  && SUPABASE_ANON_KEY.indexOf('YOUR_SUPABASE') === -1;

// Guard against calling createClient with placeholder values (throws otherwise)
const db = supabaseReady
  ? supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
  : null;

function notConnectedMessage() {
  return "This isn't connected to the database yet — see supabase-config.js for setup steps.";
}
