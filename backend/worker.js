// AeroV4 tier/backend Cloudflare Worker
// Deploy at <worker>.workers.dev, then set main.lua:
// local _liveUrl = getgenv()._aeroTierUrl or 'https://<worker>.workers.dev/whitelist'

const TIER = 1; // tier returned for every user

export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") return cors(200, "{}");
    if (request.method !== "POST") return cors(405, "{}");

    let body = {};
    try {
      body = await request.json();
    } catch (_) {}

    const action = body.action;

    let data;
    if (action === "check") data = { tier: TIER };
    else if (action === "getMessage") data = { success: false };
    else if (action === "removeMessage") data = { success: true };
    else if (action === "reportInjection") data = { success: true };
    else if (action === "getInjectionStatus") data = { users: [] };
    else if (action === "cheaters") data = { activeCheaters: [] };
    else data = { success: false, error: "unknown action" };

    return cors(200, JSON.stringify(data), "application/json");
  },
};

function cors(status, body, type = "application/json") {
  return new Response(body, {
    status,
    headers: {
      "Content-Type": type,
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    },
  });
}