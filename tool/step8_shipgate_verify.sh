#!/usr/bin/env bash
# Step-8 ship-gate verification harness. Runs all four checks and prints a
# single structured summary the verification worker can report verbatim.
set -u
cd "$(dirname "$0")/.." || exit 1

echo "===STEP8_SHIPGATE_START==="

echo "---CODEGEN---"
dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -2

echo "---ANALYZE_ERRORS_WARNINGS (excl tool/)---"
flutter analyze 2>&1 | grep -E "^\s+(error|warning)" | grep -vE "tool/|tooling/" || echo "(none)"
echo "---ANALYZE_TOTAL---"
flutter analyze 2>&1 | tail -1

echo "---BANNED_SYMBOL_GREPS---"
grep -rE 'PlaybackQueue|playQueue|skipToNext|class AudioResumed|class SwitchReciter' lib && echo "C3_FOUND" || echo "C3_NONE"
grep -rE 'RecitationMode|class SetMode|_applyMode' lib/feature/quran && echo "C14_FOUND" || echo "C14_NONE"

echo "---FULL_TEST_SUITE---"
flutter test 2>&1 | tail -1
echo "---FAILURE_BREAKDOWN---"
flutter test 2>&1 | grep -E "\[E\]$" | sed -E 's|.*test/|test/|; s|\.dart:.*|\.dart|' | sort | uniq -c | sort -rn || echo "(no failures)"

echo "===STEP8_SHIPGATE_END==="
