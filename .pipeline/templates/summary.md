---
status: done
commit: <short sha>
base_sha: <short sha>
rounds: <n> of 3
---
# <NNN>: <task title>

**Goal:** <one sentence>

<!-- Final state only. Never describe rounds or what review changed; describe the end result. -->

## What changed
- **<behavior>.** <example input → output>

## Already correct, now covered by tests
- <suspected defect that did not reproduce>

## Decisions
- <scope / design choice and why>

## Deferred
- <known gap left on purpose, and why>

## Verification
`flutter analyze`: <n> issues. `flutter test`: <n> passed.
