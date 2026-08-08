// Vidya Campus SMS — Service Worker
// Caches the app shell (HTML/CSS/JS/icons) so the app still opens offline.
// Supabase API calls are NEVER cached — they always go straight to the network,
// since attendance/marks/events/notifications data must always be fresh.

const CACHE_NAME = 'vidya-campus-shell-v1';

const APP_SHELL = [
  'login.html',
  'register.html',
  'index.html',
  'offline.html',
  'student/index.html',
  'incharge/index.html',
  'hod/index.html',
  'css/style.css',
  'js/app.js',
  'js/config.js',
  'manifest.json',
  'assets/icons/icon-192.png',
  'assets/icons/icon-512.png',
  'assets/icons/icon-maskable-512.png',
  'assets/icons/apple-touch-icon.png',
  'assets/icons/favicon-32.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);

  // Never cache Supabase API calls or realtime websocket — always live
  if (url.hostname.endsWith('.supabase.co')) return;

  event.respondWith(
    caches.match(request).then((cached) => {
      const networkFetch = fetch(request)
        .then((response) => {
          if (response && response.status === 200) {
            const clone = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
          }
          return response;
        })
        .catch(() => {
          if (cached) return cached;
          if (request.mode === 'navigate') return caches.match('offline.html');
          return undefined;
        });
      return cached || networkFetch;
    })
  );
});
