// AeroV4 tier/backend Cloudflare Worker
// Deploy at <worker>.workers.dev, then set in the executor:
//   getgenv()._aeroTierUrl = "https://<worker>.workers.dev/whitelist"
// (or replace YOUR-BACKEND-HOST in main.lua)
//
// Endpoints:
//   POST /whitelist  {action:"check", robloxUserId}  -> {tier}
//   POST /getsecret  {robloxUserId}                  -> {token}
//   GET  /modules/<name>?uid=<id>  (Bearer <token>)  -> module .lua source

const TIER = 1; // tier returned for every user

// CHANGE THIS to a long random string. Must match between deployments.
const TOKEN_SECRET = "change-me-put-a-long-random-string-here";

// Where module sources live: modules/ folder of this repo.
const MODULE_RAW = "https://raw.githubusercontent.com/LOVEVAPE/oreav4/main/modules";

const enc = new TextEncoder();

function hex(buf) {
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function sha256Hex(str) {
  const buf = await crypto.subtle.digest("SHA-256", enc.encode(str));
  return hex(buf);
}

function jsonReply(status, obj) {
  return cors(status, JSON.stringify(obj), "application/json");
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") return cors(200, "");
    const url = new URL(request.url);
    const path = url.pathname;

    if (request.method === "POST") {
      let body = {};
      try {
        body = await request.json();
      } catch (_) {}
      if (path.endsWith("/getsecret")) {
        const uid = String(body.robloxUserId || "");
        if (!uid) return jsonReply(400, { success: false, error: "missing robloxUserId" });
        return jsonReply(200, { token: await sha256Hex(TOKEN_SECRET + uid) });
      }
      const action = body.action;
      let data;
      if (action === "check") data = { tier: TIER };
      else if (action === "getMessage") data = { success: false };
      else if (action === "removeMessage") data = { success: true };
      else if (action === "reportInjection") data = { success: true };
      else if (action === "getInjectionStatus") data = { users: [] };
      else if (action === "cheaters") data = { activeCheaters: [] };
      else data = { success: false, error: "unknown action" };
      return jsonReply(200, data);
    }

    if (request.method === "GET") {
      if (path.startsWith("/modules/")) {
        const name = path.slice("/modules/".length);
        const uid = url.searchParams.get("uid") || "";
        if (!name) return jsonReply(400, { success: false, error: "missing module name" });
        if (!uid) return jsonReply(400, { success: false, error: "missing uid" });
        const expected = "Bearer " + (await sha256Hex(TOKEN_SECRET + uid));
        if (request.headers.get("Authorization") !== expected) {
          return jsonReply(401, { success: false, error: "unauthorized" });
        }
        const upstream = MODULE_RAW + "/" + encodeURIComponent(name) + ".lua";
        const up = await fetch(upstream, { cf: { cacheTtl: 0 } });
        if (!up.ok) return cors(up.status, "-- module not found --", "text/plain");
        return cors(200, await up.text(), "text/plain; charset=utf-8");
      }
    }

    return jsonReply(404, { success: false, error: "unknown endpoint" });
  },
};

function cors(status, body, type = "application/json") {
  return new Response(body, {
    status,
    headers: {
      "Content-Type": type,
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  });
}