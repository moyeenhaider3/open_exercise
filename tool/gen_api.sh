#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Reproducible OpenAPI -> Dart/Dio client generation for FND-02.
#
# Decision (see .planning/phases/01-foundation-models/01-CODEGEN-SPIKE.md):
#   option-retrofit — openapi_retrofit_generator 2.0.4, plain spec, no preprocessing.
#   No JVM is required (and none is installed on this machine); openapi_generator
#   (dart-dio, requires a JVM) was not chosen.
#
# Usage:
#   tool/gen_api.sh            # regenerate lib/core/api/generated/ from the vendored spec
#   tool/gen_api.sh --sync     # first re-copy third_party/opengym/openapi.yaml from
#                               # ../openGym/api/openapi.yaml, then regenerate
#
# Output is committed to the repo (lib/core/api/generated/**) so CI and later phases
# never need this generator or a JVM to build the app.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

VENDORED_SPEC="third_party/opengym/openapi.yaml"
SOURCE_SPEC="../openGym/api/openapi.yaml"
OUTPUT_DIR="lib/core/api/generated"

if [[ "${1:-}" == "--sync" ]]; then
  if [[ ! -f "$SOURCE_SPEC" ]]; then
    echo "gen_api.sh --sync: source spec not found at $SOURCE_SPEC (expects a sibling ../openGym checkout)" >&2
    exit 1
  fi
  echo "Syncing $VENDORED_SPEC from $SOURCE_SPEC ..."
  cp "$SOURCE_SPEC" "$VENDORED_SPEC"
fi

if [[ ! -f "$VENDORED_SPEC" ]]; then
  echo "gen_api.sh: vendored spec not found at $VENDORED_SPEC. Run with --sync first." >&2
  exit 1
fi

echo "Generating Dio clients from $VENDORED_SPEC into $OUTPUT_DIR ..."

# Step 1: openapi_retrofit_generator reads openapi_generator.yaml (schema_path,
# output_directory, json_serializer) and emits rest clients + data classes.
dart run openapi_retrofit_generator

# Step 2: build_runner runs retrofit_generator + json_serializable to produce the
# .g.dart part files referenced by the generated clients/models.
dart run build_runner build --delete-conflicting-outputs

echo "Formatting generated output ..."
dart format "$OUTPUT_DIR"

echo "Done. Generated Dio clients are in $OUTPUT_DIR."
