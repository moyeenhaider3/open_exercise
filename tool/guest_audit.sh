#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# tool/guest_audit.sh - Audit codebase to enforce AUTH-05 (guest-only, no server).
#
# Verifies that:
# (a) No call to ApiClientFactory.create() occurs outside lib/core/api/.
# (b) No Dio() constructor or dio import occurs outside lib/core/api/.
# (c) No import of core/api/generated/ occurs outside lib/core/api/.
# (d) app_router.dart contains no login, signin, pair, account, server, or admin routes.
# (e) No account/server UI strings or component names exist in lib/ Dart files.
# (f) pubspec.yaml contains no forbidden network/auth packages.
# (g) AndroidManifest.xml contains no INTERNET or USE_EXACT_ALARM permissions.
# (h) js_engine_service.dart disables XHR networking in the JS runtime.
# (i) Informational report of merged release manifest INTERNET presence (if built).
#
# Usage:
#   bash tool/guest_audit.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAILURES=0

fail() {
  echo "FAIL: $1"
  FAILURES=$((FAILURES + 1))
}

find_dart_files() {
  local dir="${1:-lib}"
  if [ -d "$dir" ]; then
    find "$dir" -type f -name "*.dart" ! -path "*/core/api/generated/*" ! -name "*.g.dart"
  fi
}

echo "=== Running GUEST AUDIT (AUTH-05) ==="

# (a) No call of the factory's create method anywhere outside lib/core/api/
A_PATTERN='\.create\(\s*baseUrl|ApiClientFactory\(\)\.create|apiClientFactory\.create|read<ApiClientFactory>\(\)\.create'
A_FILES=$(find_dart_files "lib" | grep -v "^lib/core/api/" || true)
if [ -n "$A_FILES" ]; then
  A_HITS=$(echo "$A_FILES" | xargs grep -nE "$A_PATTERN" 2>/dev/null || true)
  if [ -n "$A_HITS" ]; then
    fail "(a) ApiClientFactory.create() called outside lib/core/api/:"
    echo "$A_HITS"
  fi
fi

# (b) No Dio( constructor and no import 'package:dio/ outside lib/core/api/
B_PATTERN='Dio\(|import\s+['\''"]package:dio/'
B_FILES=$(find_dart_files "lib" | grep -v "^lib/core/api/" || true)
if [ -n "$B_FILES" ]; then
  B_HITS=$(echo "$B_FILES" | xargs grep -nE "$B_PATTERN" 2>/dev/null || true)
  if [ -n "$B_HITS" ]; then
    fail "(b) Dio constructor or import found outside lib/core/api/:"
    echo "$B_HITS"
  fi
fi

# (c) No import of core/api/generated/ outside lib/core/api/
C_PATTERN='import\s+['\''"].*core/api/generated/'
C_FILES=$(find_dart_files "lib" | grep -v "^lib/core/api/" || true)
if [ -n "$C_FILES" ]; then
  C_HITS=$(echo "$C_FILES" | xargs grep -nE "$C_PATTERN" 2>/dev/null || true)
  if [ -n "$C_HITS" ]; then
    fail "(c) Import of core/api/generated/ found outside lib/core/api/:"
    echo "$C_HITS"
  fi
fi

# (d) lib/core/router/app_router.dart has no path containing login, signin, sign-in, pair, account, server or admin
D_HITS=$(grep -niE "^\s*(static\s+const\s+String\s+\w+\s*=\s*['\"].*(login|signin|sign-in|pair|account|server|admin)|path:\s*AppRoutes\.(login|signin|pair|account|server|admin)|path:\s*['\"].*(login|signin|sign-in|pair|account|server|admin))" lib/core/router/app_router.dart 2>/dev/null || true)
if [ -n "$D_HITS" ]; then
  fail "(d) Auth/server/admin route found in app_router.dart:"
  echo "$D_HITS"
fi

# (e) No account/server UI strings or component names in lib/ Dart files
E_PATTERN="t\('Sign in|t\('Sign out|t\('Connect to my server|t\('Disconnect|t\('Pair the mobile app|t\('Create passkey profile|t\('Sign in with passkey|t\('Your server|t\('Push notifications|t\('Send test notification|SyncBanner|LoginScreen|PairSheet|ConnectSheet"
E_HITS=$(find_dart_files "lib" | xargs grep -nE "$E_PATTERN" 2>/dev/null || true)
if [ -n "$E_HITS" ]; then
  fail "(e) Account/server UI strings or components found in lib/:"
  echo "$E_HITS"
fi

# (f) pubspec.yaml has no flutter_passkey_service, http:, web_socket_channel, firebase_, supabase, google_sign_in
F_PATTERN='^\s*(flutter_passkey_service|http|web_socket_channel|firebase_\w+|supabase|google_sign_in):'
F_HITS=$(grep -nE "$F_PATTERN" pubspec.yaml 2>/dev/null || true)
if [ -n "$F_HITS" ]; then
  fail "(f) Forbidden auth/network package found in pubspec.yaml:"
  echo "$F_HITS"
fi

# (g) android/app/src/main/AndroidManifest.xml declares no INTERNET and no USE_EXACT_ALARM
G_HITS=$(grep -nE "android\.permission\.(INTERNET|USE_EXACT_ALARM)" android/app/src/main/AndroidManifest.xml 2>/dev/null || true)
if [ -n "$G_HITS" ]; then
  fail "(g) Forbidden permission found in android/app/src/main/AndroidManifest.xml:"
  echo "$G_HITS"
fi

# (h) lib/core/js/js_engine_service.dart contains getJavascriptRuntime(xhr: false)
if ! grep -q "getJavascriptRuntime(xhr: false)" lib/core/js/js_engine_service.dart; then
  fail "(h) js_engine_service.dart does not contain getJavascriptRuntime(xhr: false)"
fi

# (i) Informational only: check merged release manifest if present
RELEASE_MANIFESTS=$(find build/app/intermediates -path '*release*' -name "AndroidManifest.xml" 2>/dev/null || true)
if [ -n "$RELEASE_MANIFESTS" ]; then
  echo "Info (i): Checking merged release manifest(s) for INTERNET permission:"
  while read -r rmanifest; do
    if grep -n "android.permission.INTERNET" "$rmanifest" 2>/dev/null; then
      echo "  Note: INTERNET found in $rmanifest (merged by plugin or platform)"
    else
      echo "  Note: No INTERNET found in $rmanifest"
    fi
  done <<< "$RELEASE_MANIFESTS"
else
  echo "Info (i): No merged release manifest found (release APK not yet built)."
fi

if [ "$FAILURES" -gt 0 ]; then
  echo "GUEST AUDIT: FAIL ($FAILURES)"
  exit 1
else
  echo "GUEST AUDIT: PASS"
  exit 0
fi
