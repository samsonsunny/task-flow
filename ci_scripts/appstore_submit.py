#!/usr/bin/env python3

import argparse
import atexit
import base64
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

API_BASE = "https://api.appstoreconnect.apple.com/v1"
GENERIC_WHATS_NEW = "- Bug fixes and performance improvements."


class SubmissionError(Exception):
    pass


def encode_segment(value):
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def require_env(name):
    value = os.environ.get(name)
    if not value:
        raise SubmissionError("missing required environment variable: " + name)
    return value


def write_private_key():
    encoded = require_env("ASC_API_KEY_BASE64")
    try:
        key = base64.b64decode("".join(encoded.split()), validate=True)
    except (ValueError, TypeError):
        raise SubmissionError("ASC_API_KEY_BASE64 is not valid base64")
    if b"PRIVATE KEY" not in key:
        raise SubmissionError("ASC_API_KEY_BASE64 does not contain a .p8 private key")
    handle, path = tempfile.mkstemp(prefix="AuthKey_", suffix=".p8")
    os.fchmod(handle, 0o600)
    with os.fdopen(handle, "wb") as stream:
        stream.write(key)

    def cleanup():
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass

    atexit.register(cleanup)
    return path


def make_token(key_id, issuer_id, key_path):
    issued = int(time.time())
    header = encode_segment(json.dumps({"alg": "ES256", "kid": key_id}, separators=(",", ":")).encode())
    payload = encode_segment(json.dumps({"iss": issuer_id, "iat": issued, "exp": issued + 1200, "aud": "appstoreconnect-v1"}, separators=(",", ":")).encode())
    signing_input = (header + "." + payload).encode()
    result = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key_path], input=signing_input, capture_output=True)
    if result.returncode != 0:
        raise SubmissionError("failed to sign App Store Connect token: " + result.stderr.decode("utf-8", "replace"))
    return header + "." + payload + "." + encode_segment(result.stdout)


class Client:
    def __init__(self, token):
        self.token = token

    def request(self, method, path, params=None, body=None):
        url = API_BASE + "/" + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", "Bearer " + self.token)
        if data is not None:
            req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req, timeout=90) as response:
                raw = response.read()
                return json.loads(raw) if raw else None
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", "replace")
            raise SubmissionError("{} {} failed ({}): {}".format(method, path, exc.code, detail))

    def get(self, path, params=None):
        return self.request("GET", path, params=params)

    def post(self, path, body):
        return self.request("POST", path, body=body)

    def patch(self, path, body):
        return self.request("PATCH", path, body=body)


def find_app(client, bundle_id):
    response = client.get("apps", params={"filter[bundleId]": bundle_id})
    apps = response.get("data", [])
    if not apps:
        raise SubmissionError("no app found for bundle id " + bundle_id)
    return apps[0]["id"]


def find_version(client, app_id, version_string):
    path = "apps/" + app_id + "/appStoreVersions"
    response = client.get(path, params={"limit": 200})
    versions = [item for item in response.get("data", [])
                if item["attributes"].get("platform") == "IOS" and item["attributes"].get("versionString") == version_string]
    if not versions:
        raise SubmissionError("no iOS App Store version " + version_string + "; upload the build to App Store Connect first")
    return versions[0]["id"]


def find_build(client, app_id, version_string, build_number):
    response = client.get("builds", params={"filter[app]": app_id, "filter[version]": version_string, "sort": "-uploadedDate", "limit": 50})
    builds = [item for item in response.get("data", []) if item["attributes"].get("processingState") == "VALID"]
    if build_number:
        matched = [item for item in builds if item["attributes"].get("buildNumber") == build_number]
        if matched:
            builds = matched
    if not builds:
        raise SubmissionError("no processed build found for version " + version_string + " build " + str(build_number))
    return builds[0]["id"]


def attach_build(client, version_id, build_id):
    client.patch("appStoreVersions/" + version_id + "/relationships/build", {"data": {"type": "builds", "id": build_id}})


def in_review_submission(client, app_id):
    response = client.get("reviewSubmissions", params={"filter[app]": app_id, "sort": "-createdDate", "limit": 20})
    states = {"WAITING_FOR_REVIEW", "IN_REVIEW"}
    for item in response.get("data", []):
        if item["attributes"].get("state") in states:
            return item["id"]
    return None


def submit_for_review(client, app_id, version_id):
    submission = client.post("reviewSubmissions", {
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}
        }
    })["data"]["id"]
    client.post("reviewSubmissionItems", {
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission}},
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
            }
        }
    })
    result = client.patch("reviewSubmissions/" + submission, {
        "data": {"type": "reviewSubmissions", "id": submission, "attributes": {"submitted": True}}
    })
    return result["data"]["id"]


def read_release_notes(path):
    try:
        with open(path, encoding="utf-8") as stream:
            text = stream.read().strip()
    except FileNotFoundError:
        raise SubmissionError("release notes not found: " + path)
    if not text:
        raise SubmissionError("release notes are empty: " + path)
    if len(text) > 4000:
        raise SubmissionError("release notes exceed 4000 characters: " + path)
    return text


def find_localization(client, version_id, locale):
    path = "appStoreVersions/" + version_id + "/appStoreVersionLocalizations"
    response = client.get(path, params={"limit": 200})
    for item in response.get("data", []):
        if item["attributes"].get("locale") == locale:
            return item["id"]
    raise SubmissionError("no " + locale + " localization for version")


def update_whats_new(client, version_id, locale, text):
    localization_id = find_localization(client, version_id, locale)
    client.patch("appStoreVersionLocalizations/" + localization_id, {
        "data": {
            "type": "appStoreVersionLocalizations",
            "id": localization_id,
            "attributes": {"whatsNew": text},
        }
    })


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle-id", default="com.samson.wednesday")
    parser.add_argument("--version", required=True)
    parser.add_argument("--build-number")
    parser.add_argument("--locale", default="en-US")
    parser.add_argument("--release-notes", help="path to What's New text; defaults to a generic message")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    whats_new = read_release_notes(args.release_notes) if args.release_notes else GENERIC_WHATS_NEW

    if args.dry_run:
        print("bundle id: " + args.bundle_id)
        print("version: " + args.version)
        print("build number: " + str(args.build_number))
        print("what's new:\n" + whats_new)
        print("dry run: no App Store Connect calls made")
        return 0

    key_path = write_private_key()
    client = Client(make_token(require_env("ASC_KEY_ID"), require_env("ASC_ISSUER_ID"), key_path))
    app_id = find_app(client, args.bundle_id)
    version_id = find_version(client, app_id, args.version)
    build_id = find_build(client, app_id, args.version, args.build_number)

    existing = in_review_submission(client, app_id)
    if existing:
        print("submission " + existing + " is already in review; nothing to do")
        return 0

    update_whats_new(client, version_id, args.locale, whats_new)
    attach_build(client, version_id, build_id)
    submission = submit_for_review(client, app_id, version_id)
    print("submitted build " + build_id + " of " + args.version + " for review: " + submission)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SubmissionError as error:
        print("error: " + str(error), file=sys.stderr)
        sys.exit(1)
