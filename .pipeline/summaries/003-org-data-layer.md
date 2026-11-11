---
status: done
commit: "feat(organizations): add offline-first data layer for accounts, organizations and schedules"
base_sha: 8af0c73
rounds: 2 of 3
---
# 003: App data layer for accounts, organizations, people and schedules

**Goal:** typed, tested repositories for everything except songs (accounts, organizations, members, bands,
invites, notifications, archiving, events, recurring schedules, assignments, absences), readable offline and
refreshed from Supabase when signed in. Not wired into the UI yet (005).

## What changed
- **`lib/features/organizations/`** (domain + data): equatable entities with hand-written JSON, remote data
  sources that call the 002 RPCs and tables by their exact names, and cache-first repositories exposing
  `watch…` streams plus `refresh…` and write methods returning `fpdart` results. Riverpod providers exist but
  nothing starts them until 005.
- **Errors:** `BackendErrorCode` (`lib/core/errors/backend_error_code.dart`) covers every server error code
  plus `offline`, `notSignedIn` and `unknown`, carried as `errorCode` on the existing `Failure` classes. A
  unit test parses the error table in `supabase/README.md` so a new server code without a mapping fails CI.
- **Offline cache:** Drift schema v2 adds two generic tables (`CacheRecords`, `CacheRefreshes`) keyed by
  account id; songs, setlists and scores are untouched (migration test from a real v1 database). Offline,
  reads come from the cache and writes return `offline` without throwing. Organization actions are
  online-only; there is no write queue.
- **Account safety:**
  - Every cache write is dropped if the signed-in account changed since the operation started.
  - Streams follow the session: they switch accounts and are empty while signed out.
  - Sign-out or account switch clears the previous account's cache.
  - Rows written by realtime while a refresh runs are not overwritten by that older snapshot.
- **Realtime:** `OrganizationsSyncCoordinator` applies member, invitation, notification, event and
  assignment changes to the cache and resyncs after a reconnect without duplicates.
- **Accounts:**
  - Sign-up requires a username; the auth dialog checks availability while typing, with strings in en and es.
  - Added `isUsernameAvailable`, `fetchMyProfile` and `deactivateAccount`.
  - Duplicate usernames surface as `username_taken`, even though GoTrue reports a generic database error.
  - A deactivated account is signed out at sign-in, on session restore, and whenever any request or
    realtime error says `account_deactivated`. A stale error from a previous account never signs out the
    current one.
- **Ids:** new client-created rows use UUID v4.
- **Integration tests** (`test/integration/`, tag `supabase`) run against the local stack with real
  sign-ups (admin, member, outsider): create org, link join, username invite, roles, bands, events,
  assignment decline, absences, realtime notifications, archive by all admins, deactivation. Keys come from
  env vars or `supabase status`; nothing is hardcoded.

## Decisions
- Generic JSON cache tables instead of one Drift table per entity (fewer migrations while the model settles).
- `http` is a direct dependency, used to classify network errors as `offline`.
- `username_taken` is a `ServerFailure`.
- If the profile check fails offline, the session is kept (fail open), so a stage device without network
  still works.

## How to run
- Unit: `flutter test`
- Integration: `supabase db reset`, then `flutter test --tags supabase --run-skipped test/integration`

## Deferred
See `.pipeline/backlog.md` (003 section).

## Verification
`flutter analyze`: 0 issues. `flutter test`: 584 passed. Integration: 22 passed.
