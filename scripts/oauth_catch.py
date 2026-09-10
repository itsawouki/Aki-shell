#!/usr/bin/env python3
"""
One-shot local OAuth redirect catcher.

Usage: oauth_catch.py <port> <out_file>
"""
import sys
import http.server
import urllib.parse
import threading

PORT = int(sys.argv[1])
OUT_FILE = sys.argv[2]

CLOSE_PAGE = b"""<!DOCTYPE html>
<html><head><title>myshell</title>
<style>
  body { background:#0b0b0e; color:#fff; font-family: sans-serif;
         display:flex; align-items:center; justify-content:center;
         height:100vh; margin:0; }
  div { text-align:center; }
  h1 { font-size:20px; font-weight:600; }
  p { color:#999; font-size:14px; }
</style></head>
<body><div>
  <h1>Google Calendar connected</h1>
  <p>You can close this tab and return to your desktop.</p>
</div></body></html>"""

ERROR_PAGE = b"""<!DOCTYPE html>
<html><head><title>myshell</title></head>
<body style="background:#0b0b0e;color:#fff;font-family:sans-serif;
             display:flex;align-items:center;justify-content:center;
             height:100vh;margin:0;">
  <div style="text-align:center">
    <h1>Something went wrong</h1>
    <p style="color:#999">No authorization code was received. You can close this tab.</p>
  </div>
</body></html>"""


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # Keep stdout clean

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)

        # Ignore browser favicon requests without closing the server
        if parsed.path == "/favicon.ico":
            self.send_response(204)
            self.end_headers()
            return

        params = urllib.parse.parse_qs(parsed.query)
        code = params.get("code", [None])[0]
        error = params.get("error", [None])[0]

        if code:
            with open(OUT_FILE, "w") as f:
                f.write(code)
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(CLOSE_PAGE)

            # Shutdown after successfully capturing the OAuth code
            threading.Thread(target=self.server.shutdown, daemon=True).start()

        elif error:
            with open(OUT_FILE, "w") as f:
                f.write("")
            self.send_response(400)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(ERROR_PAGE)

            # Shutdown on explicit user cancellation/denial
            threading.Thread(target=self.server.shutdown, daemon=True).start()

        else:
            # Keep server alive if hit without parameters (e.g. initial connection checks)
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(b"Waiting for Google OAuth authentication...")


if __name__ == "__main__":
    server = http.server.HTTPServer(("127.0.0.1", PORT), Handler)
    server.serve_forever()
