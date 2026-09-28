#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <device-id>"
  echo "Example: $0 emulator-5554"
  echo "Example: $0 6FF0B979-9BC3-4DAF-8274-C3F24BD0F7AD"
  exit 1
fi

DEVICE_ID="$1"
LOG_DIR="build/parity-logs"
LOG_FILE="${LOG_DIR}/parity-${DEVICE_ID}.log"

mkdir -p "${LOG_DIR}"

echo "==> Running openGym JS parity harness on device: ${DEVICE_ID}"
echo "==> Log file: ${LOG_FILE}"

# Run Flutter app entrypoint on device and stream logs
set +e
flutter run -d "${DEVICE_ID}" -t tool/parity/parity_main.dart --debug 2>&1 | tee "${LOG_FILE}"
FLUTTER_EXIT="${PIPESTATUS[0]}"
set -e

# Extract the final PARITY RESULT line
RESULT_LINE=$(grep -E "(flutter: )?PARITY RESULT:" "${LOG_FILE}" | tail -n 1 || true)

if [ -z "${RESULT_LINE}" ]; then
  echo ""
  echo "ERROR: No PARITY RESULT line found in ${LOG_FILE} (flutter exit code: ${FLUTTER_EXIT})"
  exit 1
fi

echo ""
echo "============================================================"
echo "${RESULT_LINE}"
echo "============================================================"

# Print any failed cases if found
FAIL_COUNT=$(grep -c -E "(flutter: )?PARITY FAIL" "${LOG_FILE}" || true)
if [ "${FAIL_COUNT}" -gt 0 ]; then
  echo ""
  echo "==> Detected ${FAIL_COUNT} PARITY FAIL item(s):"
  grep -E "(flutter: )?PARITY FAIL" "${LOG_FILE}"
  echo ""
fi

# Check for PASS
if echo "${RESULT_LINE}" | grep -q "PARITY RESULT: PASS"; then
  echo "==> Parity harness completed successfully on ${DEVICE_ID}."
  exit 0
else
  echo "==> Parity harness FAILED on ${DEVICE_ID}."
  exit 1
fi
