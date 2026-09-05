"""
test_app.py — real tests for CloudShift Store's app.py.
"""

import app as app_module

client = app_module.app.test_client()


def _set(monkeypatch, **attrs):
    for name, value in attrs.items():
        monkeypatch.setattr(app_module, name, value)


def test_storefront_renders(monkeypatch):
    resp = client.get("/")
    assert resp.status_code == 200
    assert b"CloudShift Store" in resp.data


def test_storefront_lists_all_products(monkeypatch):
    resp = client.get("/")
    for product in app_module.PRODUCTS:
        assert product["name"].encode() in resp.data


def test_sale_banner_hidden_by_default(monkeypatch):
    _set(monkeypatch, SALE_BANNER_ENABLED=False)
    resp = client.get("/")
    assert b"Sale banner is ON" not in resp.data


def test_sale_banner_shown_when_enabled(monkeypatch):
    _set(monkeypatch, SALE_BANNER_ENABLED=True)
    resp = client.get("/")
    assert b"Sale banner is ON" in resp.data


def test_healthz_returns_ok(monkeypatch):
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"


def test_readyz_returns_ready(monkeypatch):
    resp = client.get("/readyz")
    assert resp.status_code == 200


def test_api_status_matches_original_contract(monkeypatch):
    resp = client.get("/api/status")
    assert resp.get_json() == {"status": "ok", "service": "cloudshift-app"}


def test_crash_disabled_by_default(monkeypatch):
    _set(monkeypatch, DEMO_MODE=False)
    resp = client.get("/crash")
    assert resp.status_code == 403


def test_config_reports_helm_source_when_release_set(monkeypatch):
    _set(monkeypatch, RELEASE_NAME="cloudshift-store-dev")
    resp = client.get("/config")
    assert resp.get_json()["source"] == "Helm-rendered ConfigMap"


def test_config_reports_hardcoded_when_no_release(monkeypatch):
    _set(monkeypatch, RELEASE_NAME="not-a-helm-release")
    resp = client.get("/config")
    assert "hardcoded" in resp.get_json()["source"]


def test_infra_defaults_to_manual_off_ec2(monkeypatch):
    _set(monkeypatch, PROVISIONED_BY="manual", INSTANCE_ID="not-on-ec2")
    resp = client.get("/infra")
    body = resp.get_json()
    assert body["provisioned_by"] == "manual"
    assert body["on_ec2"] is False


def test_infra_reports_terraform_when_set(monkeypatch):
    _set(monkeypatch, PROVISIONED_BY="terraform", INSTANCE_ID="i-0123456789abcdef0")
    resp = client.get("/infra")
    body = resp.get_json()
    assert body["provisioned_by"] == "terraform"
    assert body["on_ec2"] is True


def test_storefront_shows_manual_warning_by_default(monkeypatch):
    _set(monkeypatch, PROVISIONED_BY="manual")
    resp = client.get("/")
    assert b"can&#39;t prove how it" in resp.data or b"can't prove how it" in resp.data


def test_storefront_shows_terraform_confirmation_when_set(monkeypatch):
    _set(monkeypatch, PROVISIONED_BY="terraform")
    resp = client.get("/")
    assert b"terraform apply" in resp.data