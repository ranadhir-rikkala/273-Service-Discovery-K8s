import json
import os
import signal
import sys
import time
import urllib.request
from collections import Counter
from datetime import datetime

URL = os.environ.get("INVENTORY_URL", "http://inventory:8080/inventory")
INTERVAL = float(os.environ.get("INTERVAL", "1"))
SUMMARY_EVERY = int(os.environ.get("SUMMARY_EVERY", "10"))


def now():
    return datetime.now().strftime("%H:%M:%S.%f")[:-3]


def main():
    print(f"{now()} [client] sending requests to {URL}", flush=True)
    window = Counter()
    sent = 0
    while True:
        sent += 1
        try:
            with urllib.request.urlopen(URL, timeout=2) as resp:
                body = json.loads(resp.read())
            window[body["pod"]] += 1
            print(f"{now()} [client] #{sent} {resp.status} served by {body['pod']} ({body['pod_ip']})", flush=True)
        except Exception as e:
            window["ERROR"] += 1
            print(f"{now()} [client] #{sent} FAILED: {e}", flush=True)
        if sent % SUMMARY_EVERY == 0:
            print(f"{now()} [client] last {SUMMARY_EVERY} requests: {dict(window)}", flush=True)
            window.clear()
        time.sleep(INTERVAL)


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, lambda signum, frame: sys.exit(0))
    main()
