---
status: done
commit: "feat(team): run the calendar on real events, assignments and absences"
base_sha: 8794f73
rounds: 1 of 3
---
# 006: Calendar on real data: events, recurring schedules, assignments, replies and absences

**Goal:** the Team page's Calendar tab shows and edits the active organization's real events and recurring
schedules. Admins assign and reassign; members accept or decline and manage their absences. It works offline
from the cache.

> Run unattended under the user's delegation. The migration, its pgTAP file and the integration test were
> written and desk-checked but **not run** (Docker down): see the top of `.pipeline/backlog.md`.

## What changed
- **Schema** (`supabase/migrations/20261111000000_calendar_details.sql`, baseline untouched):
  - `calendar_events`: `event_type`, `setlist_id` (same organization, unlinks on delete), `series_id`
    (→ `recurring_schedules`, unlinks on delete) and `occurrence_date`. The unique
    `(series_id, occurrence_date)` lets an occurrence be created only once.
  - `recurring_schedules`: `time_of_day`, `location` and `event_type`, plus `unique (id, organization_id)` as
    the target of the series foreign key.
  - Writes stay admin-only. pgTAP in `09_calendar_details.test.sql`, and the README is updated.
- **Data:** the 003 entities, remote data source and cache carry the new columns. A client-side
  `BackendErrorCode.conflict` maps unique violations (23505).
- **Occurrences:** recurring schedules project upcoming dates on the device. An occurrence becomes a real
  event the first time an admin edits or assigns it. If another admin created it first, the app reloads and
  reapplies the edit.
- **Daylight-saving fix:** `EventRecurrenceCalculator` now uses calendar-day arithmetic instead of 24-hour
  steps, which landed on the wrong day around DST changes.
- **Calendar UI:** moved out of `team_page.dart` into widgets and providers under `lib/features/team/`. The
  old in-memory calendar is gone; local mode shows "Sign in to plan services with your organization".
- **Admins:**
  - Create, edit and delete events. Create, edit, pause, stop and delete recurring schedules.
  - Assign, unassign and reassign members per instrument. The picker marks absent members and members already
    booked that day, and filters by "Available" (`membersAvailableOn`) or "Plays <instrument>".
  - Link an organization setlist to an event.
  - Alerts for declined assignments and for assigned members who are away, each with one-tap "Find cover".
    Dismissals are kept per account; the alert bell switches to the Calendar tab.
- **Members:** "My services" to accept, or decline with an optional reason. "My absences" to add, edit and
  delete date ranges. Reassigning resets the reply to pending on the server.
- **Band filter:** a selected band shows its own events plus events with no band.
- **Strings** in en and es; layout tests cover 320–1440 px.

## Decisions
- **Cadences for new schedules:** only the deterministic ones (weekly Sunday or Thursday; 1st, 2nd, 3rd or
  last Sunday). Bi-weekly and monthly need an anchor date the schema does not have. Existing rows with those
  patterns still project.
- **Projected occurrences:** they cannot be deleted one by one, only edited, assigned, or stopped through
  their schedule.

## Deferred
See `.pipeline/backlog.md` (006 section and "Verify first").

## Verification
`flutter analyze`: 0 issues. `flutter test`: 777 passed (integration files skipped). The adversary also ran
the team and organizations suites with `TZ=America/New_York`. SQL desk-checked against Postgres 17.
