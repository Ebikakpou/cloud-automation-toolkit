"""
Zuri Market — app.py
--------------------------
This is the next upgrade of the app already in cloud-automation-toolkit.

Three classes ago it was a bare JSON endpoint. Two classes ago it proved
Kubernetes self-healing, scaling, and config injection. Last class it
became a storefront driven entirely by Helm values. This class the app
itself barely changes — what changes is WHERE it runs: instead of a
Kubernetes pod, Zuri Market now runs on a real EC2 instance,
provisioned by Terraform instead of a human clicking through the AWS
console.

What's new in this build, and why:

  - A handful of new fields read EC2's own Instance Metadata Service
    (IMDS) when the app is actually running on EC2: instance_id,
    instance_type, availability_zone. Off EC2 (your laptop, a plain
    Docker container) these all safely fall back to "not-on-ec2" — the
    app never hangs or crashes waiting for metadata that isn't there.

  - PROVISIONED_BY is the one field that ISN'T auto-detected — it's set
    explicitly by whatever created the instance. Terraform's user_data
    script sets it to "terraform"; if you launch an instance by hand
    through the AWS console and forget to set it, it stays "manual" by
    default. That's deliberate: the whole lesson this class is that
    hand-provisioned infrastructure is inconsistent in exactly this
    kind of small, easy-to-forget way, and code-provisioned
    infrastructure isn't.

  - The system status strip at the bottom of every page is deliberately
    unglamorous — it's there so the DevOps concepts stay visible on the
    site itself, not hidden behind the storefront.
"""

import logging
import os
import signal
import socket
import sys
import time
from urllib import response
import urllib.request
from datetime import datetime, timezone

from flask import Flask, jsonify, render_template, request, Response, send_from_directory
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest

logging.basicConfig(
    stream=sys.stdout,
    level=logging.INFO,
    format="%(asctime)s level=%(levelname)s msg=%(message)s",
)
log = logging.getLogger("cloudshift-store")

app = Flask(__name__)

REQUEST_COUNT = Counter(
"cloudshift_http_requests_total", "Total HTTP requests received", ["path", "status"]
)
REQUEST_LATENCY = Histogram(
"cloudshift_request_latency_seconds", "Request latency in seconds", ["path"]
)
UPTIME_GAUGE = Gauge(
"cloudshift_pod_uptime_seconds", "Seconds since this process started"
)

PROCESS_START = time.time()

# --- Values that flow in from the Helm chart -----------------------------
# Every one of these has a plain, sane default so the app still runs fine
# with `python app.py` and nothing set — that's the "before Helm" picture.
# Under Helm, every value below is set by values.yaml / values-dev.yaml /
# values-prod.yaml -> a ConfigMap -> envFrom -> here. Nothing is hardcoded.
APP_VERSION = os.environ.get("APP_VERSION", "v1-local")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "local")
RELEASE_NAME = os.environ.get("RELEASE_NAME", "not-a-helm-release")
REPLICA_COUNT = os.environ.get("REPLICA_COUNT", "1")
SALE_BANNER_ENABLED = os.environ.get("SALE_BANNER_ENABLED", "false").lower() == "true"
ACCENT_COLOR = os.environ.get("ACCENT_COLOR", "#5b6570")  # grey = "not configured"
REDIS_HOST = os.environ.get("REDIS_HOST", "not-configured")

DEMO_MODE = os.environ.get("DEMO_MODE", "false").lower() == "true"

POD_NAME = os.environ.get("POD_NAME", socket.gethostname())
POD_IP = os.environ.get("POD_IP", "unknown")

RUNNING_UNDER_GUNICORN = "gunicorn" in sys.argv[0]


def _fetch_imds(path: str, token: str, timeout: float = 0.25) -> str:
    req = urllib.request.Request(
        f"http://169.254.169.254/latest/meta-data/{path}",
        headers={"X-aws-ec2-metadata-token": token},
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read().decode().strip()


def fetch_ec2_metadata() -> dict:
    """Reads EC2's own Instance Metadata Service (IMDSv2). Only ever
    called once, at startup — not on every request, since a pod/laptop
    that isn't on EC2 would otherwise pay a timeout on every page load.
    Every field falls back to "not-on-ec2" the moment anything here
    fails, which is the normal, expected case off EC2."""
    fallback = {
        "instance_id": "not-on-ec2",
        "instance_type": "not-on-ec2",
        "availability_zone": "not-on-ec2",
    }
    try:
        token_req = urllib.request.Request(
            "http://169.254.169.254/latest/api/token",
            method="PUT",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "21600"},
        )
        with urllib.request.urlopen(token_req, timeout=0.25) as resp:
            token = resp.read().decode().strip()
        return {
            "instance_id": _fetch_imds("instance-id", token),
            "instance_type": _fetch_imds("instance-type", token),
            "availability_zone": _fetch_imds("placement/availability-zone", token),
        }
    except Exception:
        return fallback


_EC2 = fetch_ec2_metadata()
INSTANCE_ID = _EC2["instance_id"]
INSTANCE_TYPE = _EC2["instance_type"]
AVAILABILITY_ZONE = _EC2["availability_zone"]

# Set explicitly by Terraform's user_data script — never auto-detected.
# The whole point: infrastructure a human clicked into existence has no
# equivalent field, and no way to prove after the fact how it was made.
PROVISIONED_BY = os.environ.get("PROVISIONED_BY", "manual")


def pod_uptime_seconds() -> int:
    return int(time.time() - PROCESS_START)


@app.after_request
def _log_request(response):
    latency = time.time() - getattr(request, "_start_time", time.time())
    REQUEST_LATENCY.labels(path=request.path).observe(latency)
    REQUEST_COUNT.labels(path=request.path, status=response.status_code).inc()
    log.info("request path=%s status=%s pod=%s", request.path, response.status_code, POD_NAME)
    return response


# --- In-memory product catalog --------------------------------------------
# Deliberately not a database — the lesson today is packaging and
# templating, not persistence. Six products is enough to look like a
# real storefront without adding infrastructure the lecture didn't teach.
PRODUCTS = [
    {"id": 1, "name": "CloudShift Tee",        "price": 24.00, "emoji": "\U0001F455"},
    {"id": 2, "name": "CloudShift Hoodie",      "price": 54.00, "emoji": "\U0001F9E5"},
    {"id": 3, "name": "CloudShift Mug",         "price": 14.00, "emoji": "\u2615"},
    {"id": 4, "name": "CloudShift Sticker Pack","price": 6.00,  "emoji": "\U0001F4E6"},
    {"id": 5, "name": "CloudShift Cap",         "price": 19.00, "emoji": "\U0001F9E2"},
    {"id": 6, "name": "CloudShift Water Bottle","price": 16.00, "emoji": "\U0001F9F4"},
]



# --- React storefront and its demo product catalog ------------------------
ECOMMERCE_PRODUCTS = [
    {
        "id": 1, "name": "Merino crew neck", "category": "apparel",
        "price": 89, "stock": 12, "badge": None,
        "description": "Lightweight 100% merino wool. Naturally temperature-regulating and itch-free.",
        "image": "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=500&q=80",
    },
    {
        "id": 2, "name": "Ceramic pour-over", "category": "home",
        "price": 42, "stock": 8, "badge": "bestseller",
        "description": "Hand-thrown ceramic dripper. Brews a clean, nuanced cup every time.",
        "image": "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=500&q=80",
    },
    {
        "id": 3, "name": "Trail running pack", "category": "gear",
        "price": 115, "stock": 5, "badge": None,
        "description": "10L hydration pack with chest straps and trekking pole holders.",
        "image": "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500&q=80",
    },
    {
        "id": 4, "name": "Wireless earbuds", "category": "tech",
        "price": 129, "stock": 20, "badge": "new",
        "description": "Active noise cancellation, 28-hour battery life, IPX4 water resistance.",
        "image": "https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=500&q=80",
    },
    {
        "id": 5, "name": "Linen throw blanket", "category": "home",
        "price": 64, "stock": 15, "badge": None,
        "description": "Stonewashed European linen. Gets softer with every wash.",
        "image": "https://images.unsplash.com/photo-1600369671854-5a77c585b49e?w=500&q=80",
    },
    {
        "id": 6, "name": "Bamboo water bottle", "category": "gear",
        "price": 34, "stock": 30, "badge": None,
        "description": "Double-walled stainless steel with a bamboo lid. Keeps cold 24hr, hot 12hr.",
        "image": "https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=500&q=80",
    },
    {
        "id": 7, "name": "Canvas sneakers", "category": "apparel",
        "price": 95, "stock": 9, "badge": "new",
        "description": "Unbleached organic canvas upper, natural rubber sole. Vegan-friendly.",
        "image": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=500&q=80",
    },
    {
        "id": 8, "name": "Desk organiser set", "category": "tech",
        "price": 55, "stock": 18, "badge": None,
        "description": "Modular cork and steel tray system. Fits monitors up to 32 inches.",
        "image": "https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=500&q=80",
    },
]


@app.route("/")
def storefront():
    return send_from_directory(
        os.path.join(app.root_path, "frontend", "dist"),
        "index.html",
    )


@app.route("/assets/<path:filename>")
def storefront_assets(filename):
    return send_from_directory(
        os.path.join(app.root_path, "frontend", "dist", "assets"),
        filename,
    )


@app.route("/api/store")
def api_store():
    return jsonify(
        name=os.environ.get("STORE_NAME", "Zuri Market"),
        totalProducts=len(ECOMMERCE_PRODUCTS),
    )


@app.route("/api/products")
def api_products():
    category = request.args.get("category", "all").lower()
    products = ECOMMERCE_PRODUCTS

    if category != "all":
        products = [
            product for product in products
            if product["category"] == category
        ]

    return jsonify(products)


@app.route("/api/products/<int:product_id>")
def api_product_detail(product_id):
    product = next(
        (item for item in ECOMMERCE_PRODUCTS if item["id"] == product_id),
        None,
    )
    if product is None:
        return jsonify(error="Product not found"), 404
    return jsonify(product)


@app.route("/healthz")
def healthz():
    """Liveness probe — is the process still alive at all?"""
    return jsonify(status="ok", pod=POD_NAME, uptime_seconds=pod_uptime_seconds())


@app.route("/readyz")
def readyz():
    """Readiness probe — should this pod receive traffic right now?"""
    return jsonify(status="ready", pod=POD_NAME)


@app.route("/api/status")
def api_status():
    """Unchanged shape from the very first app.py — kept for backward
    compatibility with anything that already calls this route."""
    return jsonify(status="ok", service="cloudshift-app")


@app.route("/config")
def config():
    """Shows exactly which values came from the Helm-rendered ConfigMap
    vs. which are hardcoded fallback defaults — the same idea as the
    ConfigMap lecture, now driven by a chart instead of a raw manifest."""
    return jsonify(
        environment=ENVIRONMENT,
        release_name=RELEASE_NAME,
        app_version=APP_VERSION,
        replica_count=REPLICA_COUNT,
        sale_banner_enabled=SALE_BANNER_ENABLED,
        redis_host=REDIS_HOST,
        source="Helm-rendered ConfigMap" if RELEASE_NAME != "not-a-helm-release" else "hardcoded default (no Helm release installed)",
    )


@app.route("/infra")
def infra():
    """Shows what Terraform Fundamentals adds this class: proof of WHERE
    and HOW this instance was provisioned, not just how it's configured."""
    return jsonify(
        instance_id=INSTANCE_ID,
        instance_type=INSTANCE_TYPE,
        availability_zone=AVAILABILITY_ZONE,
        provisioned_by=PROVISIONED_BY,
        on_ec2=INSTANCE_ID != "not-on-ec2",
    )

@app.route("/crash")
def crash():
    """Disabled unless DEMO_MODE=true. See the Kubernetes Basics /
    Advanced Kubernetes lecture notes for the full explanation —
    this behaves identically to the version taught there."""
    if not DEMO_MODE:
        return jsonify(
            error="disabled: set DEMO_MODE=true to enable this demo endpoint"
        ), 403

    log.warning(
        "crash endpoint triggered on pod=%s — killing container",
        POD_NAME
    )

    if RUNNING_UNDER_GUNICORN:
        os.kill(os.getppid(), signal.SIGKILL)
    else:
        os._exit(1)

    return jsonify(status="crashing"), 200


@app.route("/metrics")
def metrics():
    UPTIME_GAUGE.set(pod_uptime_seconds())
    return Response(
        generate_latest(),
        mimetype=CONTENT_TYPE_LATEST
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)