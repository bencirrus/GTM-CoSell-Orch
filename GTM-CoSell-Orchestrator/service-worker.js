
const CACHE_NAME = "gtm-hub-cache-v4";

const OFFLINE_URLS = [
  "./",
  "./index.html",
  "./manifest.json",
  "./style.css",
  "./src/app.js",
  "./src/data/sampleData.json",
  "./src/components/CampaignPlanner.js",
  "./src/components/CoSellChecklist.js",
  "./src/components/IncentivesTracker.js"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(OFFLINE_URLS))
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;

      return fetch(event.request).catch(() => caches.match("./index.html"));
    })
  );
});
