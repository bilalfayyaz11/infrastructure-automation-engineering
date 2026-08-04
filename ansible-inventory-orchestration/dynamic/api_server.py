#!/usr/bin/env python3

import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


INSTANCES = [
    {
        "name": "web-prod-01",
        "private_ip": "10.30.1.11",
        "tags": {
            "Role": "web",
            "Environment": "production",
            "Team": "platform"
        }
    },
    {
        "name": "web-prod-02",
        "private_ip": "10.30.1.12",
        "tags": {
            "Role": "web",
            "Environment": "production",
            "Team": "platform"
        }
    },
    {
        "name": "db-prod-01",
        "private_ip": "10.30.2.11",
        "tags": {
            "Role": "database",
            "Environment": "production",
            "Team": "data"
        }
    },
    {
        "name": "db-prod-02",
        "private_ip": "10.30.2.12",
        "tags": {
            "Role": "database",
            "Environment": "production",
            "Team": "data"
        }
    },
    {
        "name": "worker-dev-01",
        "private_ip": "10.40.1.11",
        "tags": {
            "Role": "worker",
            "Environment": "development",
            "Team": "platform"
        }
    },
    {
        "name": "worker-dev-02",
        "private_ip": "10.40.1.12",
        "tags": {
            "Role": "worker",
            "Environment": "development",
            "Team": "platform"
        }
    }
]


class InventoryAPIHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/instances":
            self.send_error(404, "Endpoint not found")
            return

        body = json.dumps(INSTANCES, indent=2).encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        print(
            f"{self.client_address[0]} - "
            f"[{self.log_date_time_string()}] "
            f"{format % args}"
        )


def main():
    server = ThreadingHTTPServer(
        ("127.0.0.1", 8080),
        InventoryAPIHandler
    )

    print("Inventory API listening on http://127.0.0.1:8080")
    server.serve_forever()


if __name__ == "__main__":
    main()
