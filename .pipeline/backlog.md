# Pipeline backlog

Deferred findings that must not be forgotten. When a task closes, add anything it deferred here; when an
item is fixed, delete it (the fixing task's summary records it).

## From 001: harden transposer
- Sharp/flat spelling on free-form keys: `b minor` +2 → `Db minor` instead of `C# minor`.
- Hand-built custom labels that only look root-prefixed (`Cat` with root `C` → `Dat`).
- Chords with two slashes (`C7sus4/Bb/D`).

## From 002: Supabase schema
Planned into a later slice:
- **003:** client text ids for `setlists`, `calendar_events`, `recurring_schedules` share one namespace
  across organizations; decide id generation.
- **003/004:** sign out deactivated users (GoTrue still issues sessions; RLS blocks everything). Their email
  stays in `auth.users`.
- **004:** archive has no undo; say so in the archive confirmation UI.
- **005:** declined users can be re-invited repeatedly; removed members can rejoin with a still-valid link.
- **005:** merge-request spam: anyone who can see a song can keep sending its creator merge requests
  (with their own private title).

Small fixes, no slice yet:
- Old notifications stay after you're removed from an organization or demoted.
- Deactivated users can still read their own old notifications.
- The internal `battuta.silent` setting can be changed by a client through raw SQL.
- An assignment can be inserted with `responded_at` / `decline_reason` already set.
- Fork notification: `forked_by` may not resolve to a visible profile for the owner.
- A version switched organizations → public → organizations loses its repertoire rows until re-added.

Product / ops:
- Free plan quota values are placeholders.
- Signed-out viewers cannot see the author of a public song (profiles have no anon access).
- `auth.users` deletion was tested inside Postgres, not through the GoTrue admin API.
