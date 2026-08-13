#!/usr/bin/env python3
"""Idempotent Visit Roncegno content seeder for Directus.

Usage:
  DIRECTUS_URL=http://127.0.0.1:8055 DIRECTUS_TOKEN=... make seed-content
  DIRECTUS_URL=http://127.0.0.1:8055 DIRECTUS_TOKEN=... make seed-content-dry-run

The script discovers collection fields from Directus and only sends fields that
actually exist. Records are upserted by slug, so it is safe to run repeatedly.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "directus" / "seed"


class Directus:
    def __init__(self, base_url: str, token: str, dry_run: bool = False):
        self.base_url = base_url.rstrip("/")
        self.token = token
        self.dry_run = dry_run
        self._field_cache: dict[str, set[str]] = {}

    def request(self, method: str, path: str, payload: Any | None = None) -> Any:
        url = f"{self.base_url}{path}"
        body = None if payload is None else json.dumps(payload).encode("utf-8")
        headers = {"Accept": "application/json"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        if body is not None:
            headers["Content-Type"] = "application/json"

        req = Request(url, data=body, headers=headers, method=method)
        try:
            with urlopen(req, timeout=30) as response:
                raw = response.read().decode("utf-8")
                return json.loads(raw) if raw else {}
        except HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"Directus {method} {path} -> HTTP {exc.code}: {detail}") from exc

    def fields(self, collection: str) -> set[str]:
        if collection not in self._field_cache:
            response = self.request("GET", f"/fields/{collection}")
            self._field_cache[collection] = {
                item["field"] for item in response.get("data", []) if item.get("field")
            }
        return self._field_cache[collection]

    def collection_exists(self, collection: str) -> bool:
        try:
            self.fields(collection)
            return True
        except RuntimeError as exc:
            if "HTTP 403" in str(exc) or "HTTP 404" in str(exc):
                return False
            raise

    def find_by_slug(self, collection: str, slug: str) -> dict[str, Any] | None:
        query = urlencode({"filter[slug][_eq]": slug, "limit": 1})
        response = self.request("GET", f"/items/{collection}?{query}")
        data = response.get("data", [])
        return data[0] if data else None

    def filtered_payload(self, collection: str, record: dict[str, Any]) -> dict[str, Any]:
        fields = self.fields(collection)
        return {
            key: value
            for key, value in record.items()
            if key in fields and value is not None
        }

    def upsert(self, collection: str, record: dict[str, Any]) -> tuple[str, Any]:
        slug = record.get("slug")
        if not slug:
            raise ValueError(f"Missing slug in {collection}: {record}")

        payload = self.filtered_payload(collection, record)
        existing = self.find_by_slug(collection, slug)

        if self.dry_run:
            return ("update" if existing else "create", existing.get("id") if existing else None)

        if existing:
            self.request("PATCH", f"/items/{collection}/{existing['id']}", payload)
            return "update", existing["id"]

        created = self.request("POST", f"/items/{collection}", payload)
        item = created.get("data", {})
        return "create", item.get("id")


def load_records(filename: str) -> list[dict[str, Any]]:
    path = DATA_DIR / filename
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def seed_collection(client: Directus, collection: str, filename: str) -> None:
    if not client.collection_exists(collection):
        print(f"SKIP {collection}: collection unavailable")
        return

    records = load_records(filename)
    print(f"\n{collection}: {len(records)} records")
    for record in records:
        action, item_id = client.upsert(collection, record)
        suffix = f" id={item_id}" if item_id is not None else ""
        prefix = "DRY" if client.dry_run else action.upper()
        print(f"  {prefix:6} {record['slug']}{suffix}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    base_url = os.environ.get("DIRECTUS_URL", "http://127.0.0.1:8055")
    token = os.environ.get("DIRECTUS_TOKEN", "")

    if not token:
        print("DIRECTUS_TOKEN is required. Nothing was changed.", file=sys.stderr)
        return 2

    client = Directus(base_url, token, dry_run=args.dry_run)

    print(f"Directus: {base_url}")
    print("Mode:", "dry-run" if args.dry_run else "apply")

    seed_collection(client, "places", "places.json")
    seed_collection(client, "routes", "routes.json")
    seed_collection(client, "events", "events.json")

    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
