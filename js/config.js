// Vidya Campus SMS — Supabase connection config
const SUPABASE_URL = 'https://xdzrygsajqljjwdgxqag.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhkenJ5Z3NhanFsamp3ZGd4cWFnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxMzc3MTEsImV4cCI6MjEwMTcxMzcxMX0.6h8az5C1nU3xQ15EWOJX7UY0owmakdQPmHUv6LLRE_c';

// ---------- Campus GPS coordinates (for GPS-verified live presence) ----------
// REPLACE these with your actual campus coordinates before relying on
// verification — do not leave the placeholder values below in production.
//
// How to get your real coordinates (30 seconds):
//   1. Open Google Maps in a browser
//   2. Search for or navigate to your campus
//   3. Right-click the exact spot in the middle of campus → the coordinates
//      appear at the top of the menu, e.g. "18.4386, 79.1288"
//   4. First number = CAMPUS_LATITUDE, second number = CAMPUS_LONGITUDE
//
// CAMPUS_RADIUS_METERS is how far from that point a student's GPS reading
// is still accepted as "on campus" — 400–500m is reasonable for a college-sized
// campus to allow for normal GPS drift (typically 5–20m, occasionally more
// indoors or near tall buildings).
const CAMPUS_LATITUDE = 18.3499231;      // ⚠️ PLACEHOLDER — replace with your real campus latitude
const CAMPUS_LONGITUDE = 79.1604182;     // ⚠️ PLACEHOLDER — replace with your real campus longitude
const CAMPUS_RADIUS_METERS = 200;
