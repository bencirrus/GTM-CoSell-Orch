import { renderCampaigns } from "./components/CampaignPlanner.js";
import { renderCoSellChecklist } from "./components/CoSellChecklist.js";
import { renderIncentives } from "./components/IncentivesTracker.js";

async function loadData() {
  const res = await fetch("./src/data/sampleData.json");
  return res.json();
}

function registerServiceWorker() {
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker
      .register("./service-worker.js")
      .catch((err) => console.error("SW registration failed", err));
  }
}

async function init() {
  const app = document.getElementById("app");
  const data = await loadData();

  app.innerHTML = `
    <div class="max-w-5xl mx-auto py-6 px-4">
      <header class="mb-6">
        <h1 class="text-2xl font-bold mb-1">GTM & Co-Sell Orchestration Hub</h1>
        <p class="text-sm text-gray-600">
          Plan and track Microsoft-aligned GTM campaigns, co-sell readiness, and incentives.
        </p>
      </header>

      <main class="grid md:grid-cols-3 gap-6">
        <section class="md:col-span-2" id="campaigns-section"></section>
        <section class="space-y-6">
          <div id="cosell-section"></div>
          <div id="incentives-section"></div>
        </section>
      </main>

      <footer class="mt-8 text-xs text-gray-400">
        Built as a demo GTM & co-sell orchestration tool aligned to Microsoft partner motions.
        <br />
        <a href="https://github.com/bencirrus/GTM-CoSell-Orch" class="text-blue-600 underline">
          View on GitHub
        </a>
      </footer>
    </div>
  `;

  renderCampaigns(document.getElementById("campaigns-section"), data);
  renderCoSellChecklist(document.getElementById("cosell-section"), data);
  renderIncentives(document.getElementById("incentives-section"), data);

  registerServiceWorker();
}

init();
