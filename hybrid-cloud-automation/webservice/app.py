from __future__ import annotations

import os
import socket
import time
from datetime import datetime, timezone
from typing import Any

from flask import Flask, jsonify

app = Flask(__name__)
START_TIME = time.monotonic()


def service_metadata() -> dict[str, Any]:
    return {
        "service": "hybrid-web-service",
        "environment": os.getenv("ENVIRONMENT", "unknown"),
        "datacenter": os.getenv("DATACENTER", "unknown"),
        "instance_id": socket.gethostname(),
        "version": os.getenv("SERVICE_VERSION", "1.0.0"),
    }


@app.get("/")
def home():
    return jsonify(
        {
            "message": "Hybrid Cloud Web Service",
            **service_metadata(),
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
    )


@app.get("/health")
def health():
    return jsonify(
        {
            "status": "healthy",
            **service_metadata(),
            "uptime_seconds": round(time.monotonic() - START_TIME, 2),
            "checks": {
                "application": "available",
                "http_server": "available",
            },
        }
    )


@app.get("/info")
def info():
    return jsonify(
        {
            **service_metadata(),
            "container_port": int(os.getenv("PORT", "5000")),
            "database_configured": bool(os.getenv("DATABASE_URL")),
            "cache_configured": bool(os.getenv("CACHE_URL")),
        }
    )


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.getenv("PORT", "5000")),
        debug=False,
    )
