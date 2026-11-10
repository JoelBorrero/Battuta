---
status: done
commit: "feat(supabase): rebuild schema for users, organizations, bands and songs"
base_sha: 3036836
rounds: 3 of 3
---
# 002: Clean Supabase schema for users, organizations, bands, songs and invites

**Goal:** one secure, fully tested database model for real users, replacing the three old migrations
(teams, demo mode, quotas). First slice of the "real users and organizations" epic; SQL only.

## What changed
- **One baseline migration** `supabase/migrations/20261110000000_baseline.sql`, Supabase CLI project
  (`supabase/config.toml`), pgTAP suite in `supabase/tests/` (7 files, 621 tests), rewritten `supabase/README.md`.
  `teams`, `team_members`, `team_groups`, every `is_demo` column, demo seed and anonymous demo policies are gone.
- **Users:** `profiles` (unique case-insensitive `username`, created on sign-up; sign-up without a username is
  rejected). `is_username_available` for the sign-up screen. Profiles never reference `auth.users`, so
  deleting a sign-in account never deletes content.
- **Organizations and bands:** `organizations` → `organization_members` (`admin` | `member`, musician fields
  per organization) → `bands` / `band_members`. Composite keys make cross-organization links impossible.
- **Joining only by invitation:** `invite_links` (random ~244-bit token, expiry, optional max uses, optional
  band) used through `join_with_invite_link`; `invitations` by username with accept/decline.
  `search_profiles` matches username/display name only, never email.
- **Permissions:** all membership, invite, archive and merge changes go through `SECURITY DEFINER` RPCs with
  pinned `search_path` and machine-readable error codes. Nobody can change `role`, `organization_id` or
  `user_id` by editing tables. An organization always keeps an admin. Admins manage bands, repertoire,
  setlists, events and assignments; members edit only their own musician fields, absences and replies.
- **Archiving an organization:** requested by an admin, completed only when every current admin approves
  (the set updates if admins change), cancellable. Archived organizations are read-only, keep their history,
  reject invites and joins, and are hidden from `my_organizations` by default. No undo from the app.
- **Deactivated accounts (Slack-style):** `deactivate_account()` keeps a tombstone profile (name shown as
  deactivated), scrubs personal data, makes memberships inactive and keeps all authored content and past
  assignments. Deactivated users cannot act, be invited, join, be assigned, or appear in search. The last
  admin of an organization with other members must promote someone or archive first.
- **Songs like LaCuerda:** `songs` (the work: title, artist) with many `song_versions` (arrangements) by
  different owners; scores belong to a version. Visibility per version: `private`, `organizations`
  (via `version_shares`), `public` (readable signed out). Only the owner edits a version, admins included.
  A song is visible only if one of its versions is, so private titles never leak.
  - **Fork:** copy any visible version (and its score) into your own private version; owner is notified.
  - **Merge:** two creators of the same song agree; versions move under one song, the old one redirects
    (`merged_into_id`, `resolve_song`), cycles rejected, title snapshots shown to the approver. Auto-approved
    when you created both songs or the other creator is deactivated.
  - **Repertoire:** admins pick which version the organization plays (`organization_repertoire`), only among
    versions visible to it. Setlists are `setlist_items` rows that keep a title snapshot if a version
    disappears. Making a version non-shared removes its shares; removing a member keeps their shares.
- **Availability:** `member_absences` date ranges plus per-assignment `response`
  (`pending` | `accepted` | `declined`); `members_available_on(org, date)` for reassigning.
- **Notifications:** `notifications` table written only by triggers/RPCs, readable only by the recipient,
  in realtime: admin edits to your musician fields (changed fields listed), invites, role changes, removal,
  assignment changes, declines (to admins), archive requests/outcome, forks, merge requests.
- **Quotas:** `workspace_quotas` is an override table; `organization_quota(org)` returns the free default.

## Decisions
- Backend is a test environment, so the schema was rebuilt instead of migrated.
- Admins are per organization; there are no band leaders.
- Ids: `songs`, `song_versions`, `scores` are `uuid`; `setlists`, `calendar_events`, `recurring_schedules`
  keep client text ids (namespace handling is for 003).
- A sole admin's own request archives the organization, even with other members.

## Deferred
- Free plan quota values are placeholders.
- Deactivated users can still obtain a session from GoTrue (RLS blocks everything); the app must sign them
  out (003/004). Their email stays in `auth.users`.
- Signed-out viewers cannot see the author of a public song (profiles have no anon access).
- `auth.users` deletion was tested inside Postgres, not through the GoTrue admin API.
- Nits: stale notifications after removal/demotion; deactivated users read their own old notifications;
  re-inviting declined users; merge-request spam; organizations → public → organizations drops repertoire rows.
- Until 003, the app's existing cloud sync and demo sync fail against the new schema (local data unaffected).

## Verification
`supabase db reset` twice: clean. `supabase test db`: 621 passed. `flutter analyze`: 0 issues.
`flutter test`: 487 passed.
