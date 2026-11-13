---
status: done
commit: (this commit)
base_sha: 73380d1
rounds: 1 of 3
---
# 021: Audit of screens built on main

**Goal:** Compare the screens built on main since the designs (onboarding, inbox, discover, profile,
organization pages, recurring schedules) with the "Battuta Screens" mockups, without changing code.

## Result
Rendered at 390 pt in light and dark (temporary harness, not committed) and reviewed against the code.
- Minor differences: Inbox, Discover, Profile.
- Needs redesign: Welcome, Sign in, Create account, Join, Organization profile, Organization settings,
  Recurring schedules, Repeating service form.

Every mismatch, with file and effort, is in `backlog.md` under "From 021". Larger items need data that does
not exist yet: an invite-preview API (Join), username sign-in and server choice on Sign in, quota usage and
renewal (Organization settings), and flexible repeat rules (Repeating service).

## Decisions
- No fixes here, as planned. The redesign series 013–020 ends with this audit; the redesign rules and mockup
  copies used by the series are removed.

## Verification
No code changed. `flutter analyze`: 0 issues. `flutter test`: 1332 passed, 9 skipped, 1 known date-dependent
failure.
