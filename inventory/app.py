import json
import os
import signal
import socket
import sys
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

POD_NAME = os.environ.get("POD_NAME", socket.gethostname())
POD_IP = os.environ.get("POD_IP", "unknown")
UNREADY_FLAG = "/tmp/unready"
PORT = int(os.environ.get("PORT", "8080"))

STOCK = {
    "laptop": 12,
    "keyboard": 40,
    "monitor": 7,
    "headphones": 25,
}


def log(msg):
    print(f"{datetime.now().strftime('%H:%M:%S.%f')[:-3]} [{POD_NAME}] {msg}", flush=True)


class Handler(BaseHTTPRequestHandler):
    def send_json(self, code, body):
        data = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/healthz":
            self.send_json(200, {"status": "alive"})
        elif self.path == "/ready":
            if os.path.exists(UNREADY_FLAG):
                self.send_json(503, {"status": "not ready", "pod": POD_NAME})
            else:
                self.send_json(200, {"status": "ready", "pod": POD_NAME})
        elif self.path == "/inventory":
            log(f"served /inventory to {self.client_address[0]}")
            self.send_json(200, {"pod": POD_NAME, "pod_ip": POD_IP, "stock": STOCK})
        elif self.path.startswith("/inventory/"):
            item = self.path.split("/", 2)[2]
            log(f"served /inventory/{item} to {self.client_address[0]}")
            if item in STOCK:
                self.send_json(200, {"pod": POD_NAME, "item": item, "quantity": STOCK[item]})
            else:
                self.send_json(404, {"pod": POD_NAME, "error": f"unknown item {item}"})
        else:
            self.send_json(404, {"error": "not found"})

    def log_message(self, fmt, *args):
        pass


def shutdown(signum, frame):
    log("received SIGTERM, shutting down")
    sys.exit(0)


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, shutdown)
    log(f"inventory service starting on port {PORT} (pod ip {POD_IP})")
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
