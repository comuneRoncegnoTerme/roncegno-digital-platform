#!/usr/bin/env python3
import json
import os
import sys
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError

BASE_URL = os.environ.get("DIRECTUS_URL", "").rstrip("/")
TOKEN = os.environ.get("DIRECTUS_TOKEN", "")
TIMEOUT = int(os.environ.get("DIRECTUS_TIMEOUT", "30"))

if not BASE_URL or not TOKEN:
    print("DIRECTUS_URL e DIRECTUS_TOKEN sono obbligatori", file=sys.stderr)
    sys.exit(2)

def request(method, path, payload=None, query=None):
    url = BASE_URL + path
    if query:
        url += "?" + urlencode(query, doseq=True)
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    req = Request(url, data=body, method=method)
    req.add_header("Authorization", f"Bearer {TOKEN}")
    req.add_header("Accept", "application/json")
    if body is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urlopen(req, timeout=TIMEOUT) as r:
            raw = r.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except HTTPError as e:
        detail = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Directus {e.code} {method} {path}: {detail}") from e

def get_items(collection, filters, fields="*"):
    query = {"fields": fields, "limit": 1}
    for k, v in filters.items():
        query[f"filter[{k}][_eq]"] = v
    data = request("GET", f"/items/{collection}", query=query)
    return data.get("data", [])

def first_item(collection, filters, required=True, fields="*"):
    items = get_items(collection, filters, fields=fields)
    if items:
        return items[0]
    if required:
        raise RuntimeError(f"{collection}: record non trovato per {filters}")
    return None

def resolve_term(taxonomy_key, term_key):
    tax = first_item("taxonomies", {"key": taxonomy_key}, fields="id,key")
    term = first_item(
        "taxonomy_terms",
        {"taxonomy": tax["id"], "key": term_key},
        fields="id,key,label",
    )
    return term["id"]

def upsert_editorial_content(content):
    existing = first_item(
        "editorial_contents",
        {"identifier": content["identifier"]},
        required=False,
        fields="id,identifier",
    )

    payload = {
        "status": "draft",
        "identifier": content["identifier"],
        "slug": content.get("slug"),
        "title": content["title"],
        "summary": content.get("summary"),
        "briefing": content.get("briefing"),
        "urgency": content.get("urgency", "routine"),
        "editorial_priority": int(content.get("editorial_priority", 0)),
        "source_type": content.get("source_type", "manual"),
        "source_url": content.get("source_url"),
        "source_collection": content.get("source_collection"),
        "source_id": content.get("source_id"),
        "factual_notes": content.get("factual_notes"),
        "editorial_notes": content.get("editorial_notes"),
        "ai_generated": True,
        "ai_model": content.get("ai_model"),
        "ai_notes": content.get("ai_notes"),
    }

    if content.get("content_type_key"):
        payload["content_type"] = resolve_term("content_types", content["content_type_key"])
    if content.get("primary_category_key"):
        payload["primary_category"] = resolve_term("editorial_categories", content["primary_category_key"])

    payload = {k: v for k, v in payload.items() if v is not None}

    if existing:
        result = request("PATCH", f"/items/editorial_contents/{existing['id']}", payload)
        return result["data"]

    result = request("POST", "/items/editorial_contents", payload)
    return result["data"]

def upsert_channel_decision(content_id, decision):
    channel = first_item("channels", {"key": decision["channel_key"]}, fields="id,key,name")

    existing = first_item(
        "editorial_channel_decisions",
        {"content": content_id, "channel": channel["id"]},
        required=False,
        fields="id",
    )

    payload = {
        "content": content_id,
        "channel": channel["id"],
        "decision": decision["decision"],
        "recommended_format": decision.get("recommended_format"),
        "rationale": decision.get("rationale"),
        "confidence": decision.get("confidence"),
        "ai_generated": True,
        "ai_model": decision.get("ai_model"),
    }
    payload = {k: v for k, v in payload.items() if v is not None}

    if existing:
        result = request("PATCH", f"/items/editorial_channel_decisions/{existing['id']}", payload)
        return result["data"], channel

    result = request("POST", "/items/editorial_channel_decisions", payload)
    return result["data"], channel

def upsert_distribution(content_id, channel, decision_record, draft):
    existing = first_item(
        "distributions",
        {
            "channel": channel["id"],
            "content_collection": "editorial_contents",
            "content_id": content_id,
        },
        required=False,
        fields="id",
    )

    payload = {
        "channel": channel["id"],
        "content_collection": "editorial_contents",
        "content_id": content_id,
        "enabled": True,
        "status": "pending",
        "editorial_state": "draft",
        "format": draft.get("format"),
        "headline": draft.get("headline"),
        "body": draft.get("body"),
        "call_to_action": draft.get("call_to_action"),
        "alt_text": draft.get("alt_text"),
        "visual_direction": draft.get("visual_direction"),
        "route_reason": decision_record.get("rationale"),
        "ai_generated": True,
        "ai_model": draft.get("ai_model"),
        "source_decision": decision_record["id"],
        "configuration": draft.get("configuration", {}),
    }
    payload = {k: v for k, v in payload.items() if v is not None}

    if existing:
        result = request("PATCH", f"/items/distributions/{existing['id']}", payload)
        return result["data"]

    result = request("POST", "/items/distributions", payload)
    return result["data"]

def validate_contract(data):
    if not isinstance(data, dict):
        raise ValueError("Payload root deve essere un oggetto JSON")
    if "content" not in data or "decisions" not in data:
        raise ValueError("Campi obbligatori: content, decisions")
    c = data["content"]
    for key in ("identifier", "title"):
        if not c.get(key):
            raise ValueError(f"content.{key} è obbligatorio")
    seen = set()
    for i, d in enumerate(data["decisions"]):
        for key in ("channel_key", "decision"):
            if not d.get(key):
                raise ValueError(f"decisions[{i}].{key} è obbligatorio")
        if d["channel_key"] in seen:
            raise ValueError(f"Decisione duplicata per canale {d['channel_key']}")
        seen.add(d["channel_key"])
        if d["decision"] not in ("publish", "hold", "skip"):
            raise ValueError(f"Decisione non valida: {d['decision']}")
        if d["decision"] == "publish" and "draft" not in d:
            raise ValueError(f"decisions[{i}].draft obbligatorio quando decision=publish")

def main():
    raw = sys.stdin.read()
    if not raw.strip():
        raise ValueError("Fornire il payload JSON su stdin")

    data = json.loads(raw)
    validate_contract(data)

    content = upsert_editorial_content(data["content"])
    output = {
        "content": {"id": content["id"], "identifier": content["identifier"]},
        "decisions": [],
        "distributions": [],
    }

    for decision in data["decisions"]:
        decision_record, channel = upsert_channel_decision(content["id"], decision)
        output["decisions"].append({
            "id": decision_record["id"],
            "channel": channel["key"],
            "decision": decision_record["decision"],
        })

        if decision["decision"] == "publish":
            distribution = upsert_distribution(
                content["id"],
                channel,
                decision_record,
                decision["draft"],
            )
            output["distributions"].append({
                "id": distribution["id"],
                "channel": channel["key"],
                "editorial_state": distribution["editorial_state"],
            })

    print(json.dumps(output, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Errore: {e}", file=sys.stderr)
        sys.exit(1)
