# AeroV4 tier/backend server (Python 3, stdlib only)
# Deploy anywhere: python whitelist_server.py  (default port 8080)
# The client:
#   POST <your-url>/whitelist  {action:"check", robloxUserId}        -> {tier}
#   GET  <your-url>/whitelist  (action in query)                     -> same as POST
#   POST <your-url>/getsecret  {robloxUserId}                        -> {token}
#   GET  <your-url>/modules/<name>?uid=<id>  (Bearer <token>)        -> module .lua source
# Then set getgenv()._aeroTierUrl = "https://<your-url>/whitelist" in the executor,
# or replace YOUR-BACKEND-HOST in main.lua.

import hashlib
import json
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

TIER = 1  # tier returned for every user (1 = paid base, 4 = admin, 99 = owner)

# Token secret for /getsecret. CHANGE THIS to a long random string.
TOKEN_SECRET = "change-me-put-a-long-random-string-here"

# Where module sources live. Points at the modules/ folder of this repo.
MODULE_RAW = "https://raw.githubusercontent.com/LOVEVAPE/oreav4/main/modules"

ALLOWED_TIERS = {99, 4, 3, 2, 1, 0}


def token_for(uid: str) -> str:
    return hashlib.sha256((TOKEN_SECRET + uid).encode("utf-8")).hexdigest()


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


def handle_getsecret(uid: str):
    if not uid:
        return 400, {"success": False, "error": "missing robloxUserId"}
    return 200, {"token": token_for(uid)}


def handle_module(name: str, uid: str, auth: str):
    if not name:
        return 400, "missing module name"
    if not uid:
        return 400, "missing uid"
    expected = "Bearer " + token_for(uid)
    if (auth or "") != expected:
        return 401, "unauthorized"
    url = MODULE_RAW + "/" + urllib.parse.quote(name) + ".lua"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "AeroV4-backend"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.status, resp.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return 404, "-- module not found --"
        return 502, "-- upstream error --"
    except Exception:
        return 502, "-- upstream error --"


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
        if not isinstance(body, dict):
            body = {}
        self._route(body.get("action"), body, None)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/getsecret":
            qs = urllib.parse.parse_qs(parsed.query)
            uid = (qs.get("robloxUserId") or [""])[0]
            status, payload = handle_getsecret(uid)
            self._respond(status, payload)
            return
        if parsed.path.startswith("/modules/"):
            name = parsed.path[len("/modules/"):]
            qs = urllib.parse.parse_qs(parsed.query)
            uid = (qs.get("uid") or [""])[0]
            status, payload = handle_module(name, uid, self.headers.get("Authorization"))
            self._respond(status, payload, "text/plain; charset=utf-8")
            return
        qs = urllib.parse.parse_qs(parsed.query)
        action = (qs.get("action") or [""])[0]
        if action == "check":
            payload = json.dumps({"tier": TIER}).encode("utf-8")
            self._respond_bytes(200, payload)
            return
        self._respond(200, {"success": False, "error": "unknown endpoint"})

    def _route(self, action, body, unused):
        if action == "getsecret":
            status, payload = handle_getsecret(body.get("robloxUserId"))
            self._respond(status, payload)
            return
        if action == "check":
            self._respond(200, {"tier": TIER})
            return
        payload = handle_request(body)
        self._respond(200, payload)

    def _respond(self, status, payload, ctype="application/json"):
        if isinstance(payload, dict) or isinstance(payload, list):
            data = json.dumps(payload).encode("utf-8")
        elif isinstance(payload, str):
            data = payload.encode("utf-8")
        else:
            data = json.dumps(payload).encode("utf-8")
        self._respond_bytes(status, data, ctype)

    def _respond_bytes(self, status, data, ctype="application/json"):
        self.send_response(status)
        self._cors()
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")

    def log_message(self, fmt, *args):
        print("[%s] %s" % (self.address_string(), fmt % args))


if __name__ == "__main__":
    import urllib.error

    PORT = 8080
    print("AeroV4 backend listening on :%d (tier=%d)" % (PORT, TIER))
    print("module upstream: %s" % MODULE_RAW)
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()