#!/usr/bin/env bash
set -euo pipefail

# 1. Guard Protected Files
PROTECTED_DIFF=$(git status --porcelain | awk '{print $2}' | grep -E '^(\.env|pubspec\.yaml|pubspec\.lock|ios/|macos/Runner/DebugProfile\.entitlements)' || true)
if [ -n "$PROTECTED_DIFF" ]; then
  echo "❌ GATE FAILED: Agent modified protected files without permission:"
  echo "$PROTECTED_DIFF"
  exit 1
fi

# 2. Format Code Quietly
dart format lib/ test/ >/dev/null 2>&1

# 3. Static Analysis (Must be 0 issues)
echo "🔍 Running flutter analyze..."
ANALYZE_OUT=$(flutter analyze --no-pub 2>&1) || {
  echo "❌ GATE FAILED: flutter analyze reported issues:"
  echo "$ANALYZE_OUT" | grep -E "(error|warning|info) •" | head -n 20
  exit 1
}
echo "✅ flutter analyze: 0 issues."

# 4. Run Test Suite (Compact output for LLM context hygiene)
echo "🧪 Running flutter test..."
TEST_OUT=$(flutter test --no-pub --reporter=compact 2>&1) || {
  echo "❌ GATE FAILED: Tests failed. Relevant stack trace:"
  echo "$TEST_OUT" | tail -n 35
  exit 1
}

# Verify test count did not regress below 275
PASS_COUNT=$(echo "$TEST_OUT" | grep -Eo '\+[0-9]+' | tail -n 1 | tr -d '+' || echo "0")
if [ "$PASS_COUNT" -lt 275 ]; then
  echo "❌ GATE FAILED: Test count ($PASS_COUNT) dropped below MVP baseline (275)!"
  exit 1
fi

echo "✅ GATE PASSED: $PASS_COUNT tests passing, 0 analyzer issues."