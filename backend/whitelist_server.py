# AeroV4 tier/backend server (Python 3, stdlib only)
# Deploy anywhere: python whitelist_server.py  (default port 8080)
# The client POSTs JSON to:  <your-url>/whitelist
# Then set getgenv()._aeroTierUrl = "https://<your-url>/whitelist" in the executor,
# or replace YOUR-BACKEND-HOST in main.lua.

import json
from http.server import BaseHTTPRequestHandler, HTTPServer

TIER = 1  # tier returned for every user (1 = paid base, 4 = admin, 99 = owner)

ALLOWED_TIERS = {99, 4, 3, 2, 1, 0}

def handle_request(body: dict):
    action = body.get("action")
    if action == "check":
        return {"tier": TIER}
    if action == "getMessage":
        return {"success": False}
    if action == "removeMessage":
        return {"success": True}
    if action == "reportInjection":
        return {"success": True}
    if action == "getInjectionStatus":
        return {"users": []}
    if action == "cheaters":
        return {"activeCheaters": []}
    return {"success": False, "error": "unknown action"}


class Handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    def do_POST(self):
        length = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(length) if length else b"{}"
        try:
            body = json.loads(raw.decode("utf-8"))
        except Exception:
            body = {}
        res = handle_request(body if isinstance(body, dict) else {})
        payload = json.dumps(res).encode("utf-8")
        self.send_response(200)
        self._cors()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def log_message(self, fmt, *args):
        print("[%s] %s" % (self.address_string(), fmt % args))


if __name__ == "__main__":
    PORT = 8080
    print("AeroV4 backend listening on :%d (tier=%d)" % (PORT, TIER))
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()