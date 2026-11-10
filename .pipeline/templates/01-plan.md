---
status: draft | approved
base_sha: <git rev-parse HEAD>
round: 1
---
# <Task title>

## Goal
<1-3 sentences>

## Non-goals
- 

## Acceptance criteria (testable)
- [ ] 

## Files in scope
- `lib/...` — what changes
- `test/...` — what tests

## Steps (domain → state → presentation → tests)
1. 

## Edge cases to handle
- Month/year rollovers, empty states, narrow/wide layouts (no RenderFlex overflow), offline

## Verify
- `flutter test test/features/<feature>/`
- `flutter analyze` → 0 issues
- `flutter test` → 100% pass
