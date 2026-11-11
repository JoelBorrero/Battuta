# Battuta Supabase backend

Schema, Row Level Security (RLS), RPCs and tests for real accounts, organizations and bands.
Battuta stays offline-first: Drift (SQLite) is the source of truth for the UI, and signing in is only
needed for organizations and shared data (cached locally). Without an account the app runs on local data.

The schema is one baseline migration, `migrations/20261110000000_baseline.sql` (never edited), plus small
follow-up migrations: `20261110000100_personal_setlists_and_overrides.sql` (personal setlists, key and tempo
overrides on setlist entries, and the `edited_at` conflict stamps). The backend is a test environment, so the baseline was rebuilt from scratch
rather than patched.

---

## 1. Model

user -> organization -> bands. A user can administer several organizations and be a plain member of
others. Inside an organization a musician can play in several bands.

| Table | Purpose |
| --- | --- |
| `profiles` | One per account, created by trigger on sign-up. `username` (unique, case-insensitive, 3-30 chars of `[a-z0-9_.]`, stored lowercase), `display_name`, `avatar_url`, `deactivated_at`. No email. No foreign key to `auth.users`: a profile outlives its auth user. |
| `organizations` | `name`, `created_by`, `archived_at`. |
| `organization_members` | `(organization_id, user_id)` unique, `role` (`admin` or `member`), per-organization musician profile (`instruments`, `min_pitch`, `max_pitch`, `notes`), `deactivated_at`. |
| `organization_archive_requests`, `organization_archive_approvals` | Open archive request and the admins who approved it. |
| `bands` / `band_members` | Bands of an organization; a member can be in several. Composite foreign keys make it impossible to link a band and a member of different organizations. |
| `invite_links` | Join token (64 hex chars) + optional `band_id`, `expires_at`, `max_uses`, `use_count`, `revoked_at`. |
| `invitations` | Invite by username: `pending`, `accepted`, `declined`, `cancelled`. One pending invitation per user and organization. |
| `songs` | The work: `title`, `artist`, `created_by`, `merged_into_id` (redirect after a merge). No chord content. |
| `song_versions` | Arrangements of a song: `owner_id`, `label`, `forked_from_version_id`, `visibility` (`private`, `organizations`, `public`) and the content (key, tempo, sections, lyrics, ...). |
| `version_shares` | Organizations a version with visibility `organizations` is shared with. |
| `scores` (+ `sections`, `measures`, `note_events`, `chord_symbols`) | Notation of a version. |
| `organization_repertoire` | The versions an organization plays (picked by admins among versions visible to it). |
| `song_merge_requests` | Merge of two separately created copies of the same work. |
| `setlists`, `setlist_items` | A setlist belongs to **either** an organization (`organization_id`) **or** a user (`owner_id`, a personal setlist): exactly one is set. Items reference a version and keep a title snapshot plus `key_override`, `tempo_override` and `notes`. Organization items reference repertoire versions; personal items reference any version the owner can see. |
| `calendar_events`, `recurring_schedules` | Belong to an organization, optional `band_id`. Both have an `event_type` (`sundayService`, `rehearsal`, `midweek`, `youthService`, `specialEvent`). A schedule adds `time_of_day` and `location`; an event adds an optional `setlist_id` (a setlist of the same organization, unlinked when the setlist is deleted) and `series_id` + `occurrence_date` when it is a materialized occurrence of a schedule (unique per series and day; kept, with `series_id` null, when the schedule is deleted). |
| `event_assignments` | Who plays what at an event, with `response` (`pending`, `accepted`, `declined`), `responded_at`, `decline_reason`. |
| `member_absences` | Days a member is away (`starts_on`, `ends_on`, `note`). |
| `notifications` | `recipient_id`, `organization_id?`, `type`, `payload`, `read_at`. Created only by triggers and RPCs. |
| `workspace_quotas`, `workspace_usage` | Gemini credit and storage metering per organization. A quota row is only an override of the free default (`organization_quota(org)`). |

Removed from the old schema: `teams`, `team_members`, `team_groups`, every `is_demo` column, demo seed
data, the anonymous demo policies and the free-text `availability` column. Song, setlist and event ids
that used to be client-generated text: `songs`, `song_versions` and `scores` are now `uuid`;
`setlists`, `calendar_events` and `recurring_schedules` keep text ids.

## 2. Permissions

Defense in depth: table/column `GRANT`s, then RLS. `anon` can only read public song content.

- Organization data is visible only to active members.
- Writes to organization content (bands, band members, setlists and items, events, schedules,
  assignments, repertoire): organization admins only, and only while the organization is not archived.
- Personal setlists (and their items) are visible and writable only by their owner (an active account).
  A setlist can never change between personal and organization, or change owner: only `title`, `description`,
  `event_date`, `tags_json` and `band_id` are updatable.
- A member can update only their own musician fields through a column-level grant. Nobody, admins
  included, can change `role`, `organization_id` or `user_id` directly. Admins may edit members' musician
  fields; the member is notified (`member_profile_edited`, with the changed fields).
- `organization_members`, `organizations`, `invite_links`, `invitations`, `notifications` have no insert/delete
  access for clients: they change only through the RPCs below or triggers. This closes the old hole where
  any signed-in user could insert themselves into any team as admin.
- An active organization always keeps one active admin: the last admin cannot leave, be removed, be
  demoted or deactivated (`last_admin`). Archive the organization instead.
- Removing a member (or a member leaving) deletes their band memberships and future event assignments.
  Past assignments are kept with `member_id` null. Their song versions stay shared with the organization
  (and in its repertoire and setlists), exactly as after deactivation, until the owner unshares them.
  Events cannot be assigned to a deactivated member (`member_deactivated`).
- Profiles are visible to yourself, people sharing an organization (deactivated ones included, as history),
  the inviter of your pending invitations, admins' invitees, owners of versions you can see and the other
  side of a merge request. `search_profiles` is the only way to find other users (username/display name,
  never email, never deactivated accounts).

### Archiving organizations

`request_organization_archive(org)` (admin) opens a request and counts as the requester's approval. Every
*current* admin must `approve_organization_archive(org)`; admins added or removed meanwhile change who is
needed, and removing/demoting the last missing admin completes the request. Any admin can
`cancel_organization_archive(org)`. When everyone approved, `archived_at` is set. Nothing is deleted.
An archived organization is read-only for everyone (members keep read access to history), pending
invitations are cancelled, invite links revoked, joins and invitations fail with `organization_archived`, and
it disappears from `my_organizations()` unless `my_organizations(true)`. Members can still leave. A single admin
approves on their own, so a sole admin archives immediately. **Archiving cannot be undone from the app**:
there is no unarchive RPC, only the service role can clear `archived_at`, so clients should ask for an
explicit confirmation.

### Deactivated accounts

`deactivate_account()` sets `profiles.deactivated_at`, clears the avatar, keeps `username`/`display_name`,
marks every membership inactive (`organization_members.deactivated_at`), removes band memberships and future
assignments, and cancels pending invitations to the user. Past assignments and everything authored stay.
A last admin of an active organization with other active members is blocked (`last_admin`); a sole member
archives the organization. Deleting the `auth.users` row does the same (trigger) and never deletes profiles
or content (no cascade from `auth.users`). Deactivated users cannot call RPCs (`account_deactivated`), cannot
be invited or searched, cannot join, see no organization data and cannot edit their versions. Their
usernames stay reserved. Sign-in itself is not blocked at the auth layer (see doubts in the task report).

### Songs, versions, visibility, forks, merges

One song (the work) has many versions by different owners, like LaCuerda.

- `visibility` is per version: `private` (owner only), `organizations` (members of the orgs in
  `version_shares`; the owner can share only to organizations they actively belong to and that are not
  archived), `public` (anyone, including `anon`).
- A song is visible if you created it or can see one of its versions (or the surviving song after a
  merge): a private version never leaks its title.
- Only the version owner edits or deletes a version and its score tree. Admins cannot. The song title/artist
  is edited by the song's creator.
- `fork_song_version(version, label?)`: anyone who can see a version copies it (content and score tree)
  under the same song as a private version they own. The original owner is notified (`song_version_forked`).
- `request_song_merge(source, target)`: the requester must have created one of the songs; the creator of
  the other approves with `respond_to_song_merge(request, accept)`. On approval every version of the source
  moves under the target, the source gets `merged_into_id`, versions keep owner and visibility. The request stores `source_title` / `target_title` snapshots (also in
  the `song_merge_requested` notification) so the approver sees both titles without read access. Both creators
  the same, or the other creator deactivated: approved automatically. Both ids are resolved through earlier
  merges first (`resolve_song`); a merge that would end in the same song is `merge_cycle`.
- A version inserted under a merged-away song is attached to the surviving song (trigger).
- Org repertoire: admins pick a **version** among versions visible to the organization (shared to it or
  public). Setlist items reference repertoire versions. When a version stops being visible to an organization
  (unshared, or made private/public, which also deletes its `version_shares` rows) it leaves that repertoire and setlist items
  keep their title snapshot with `version_id` null.

### Availability

`member_absences` are managed by the member and readable by the member and the organization's admins.
`members_available_on(org, date)` lists active members without an absence that day (any member may call it).
`event_assignments.response` can only be set by the assigned member (`not_assignee` otherwise); only
admins (re)assign (`not_admin` otherwise) and reassigning resets the response to `pending`.

### Notifications

Rows are created by triggers/RPCs only; recipients read their own and set `read_at` (or call
`mark_notifications_read(ids?)`). Types: `invitation`, `role_changed`, `removed`, `member_profile_edited`,
`event_assigned`, `event_unassigned`, `assignment_declined` (to admins), `archive_requested` /
`archive_cancelled` (to the other admins), `archive_completed` (to all members), `song_version_forked`,
`song_merge_requested`, `song_merge_accepted`, `song_merge_declined`. Deactivated users are never notified.
Clean-up caused by removal, deactivation or deleting an event does not produce unassignment notifications.

## 3. RPCs

All are `SECURITY DEFINER` with a pinned `search_path`. Errors use the SQL error code and a machine
readable message, e.g. `invite_expired`.

| RPC | Who | Notes |
| --- | --- | --- |
| `create_organization(name)` | signed in | Creator becomes admin. No quota row (free default). |
| `my_organizations(include_archived = false)` | signed in | Organizations the caller actively belongs to. |
| `organization_quota(org)` | member | Stored override or the free default. |
| `request_organization_archive(org)` / `approve_organization_archive(org)` / `cancel_organization_archive(org)` | admin | See archiving. |
| `deactivate_account()` | signed in | See deactivated accounts. |
| `create_invite_link(org, band?, expires_in = 7 days, max_uses?)` | admin | Returns the row including `token`. |
| `revoke_invite_link(id)` | admin | Idempotent. |
| `join_with_invite_link(token)` | signed in | Creates a `member` row. Already a member (also a concurrent double submit): succeeds, no duplicate, no use consumed, band still added. |
| `invite_user_by_username(org, username, band?)` | admin | Username is trimmed and case-insensitive. Notifies the user. |
| `respond_to_invitation(id, accept)` | the invitee | Accept creates the membership (and band membership). |
| `cancel_invitation(id)` | admin | Pending only. |
| `set_member_role(member_id, role)` | admin | `admin` or `member`. |
| `remove_member(member_id)` | admin | |
| `leave_organization(org)` | member | |
| `members_available_on(org, date)` | member | |
| `fork_song_version(version, label?)` | signed in | |
| `request_song_merge(source, target)` / `respond_to_song_merge(request, accept)` | song creators | |
| `search_profiles(query)` | signed in | 3+ characters, max 20 rows, excludes the caller and deactivated accounts. |
| `is_username_available(username)` | anyone | Sign-up pre-check; the unique index is the real guard. |
| `mark_notifications_read(ids?)` | signed in | Returns how many were marked. |
| `record_gemini_scan_usage(org, tokens, credits)` | member | Atomic usage counter. |

Error codes:

| SQLSTATE | Messages |
| --- | --- |
| `28000` | `not_authenticated` |
| `42501` | `not_admin`, `not_member`, `not_assignee`, `not_song_creator` (and `permission denied` / RLS violations for direct table access) |
| `22023` | `invalid_name`, `invalid_username`, `invalid_role`, `invalid_expiry`, `invalid_max_uses`, `invalid_amount` |
| `P0002` | `invite_not_found`, `user_not_found`, `invitation_not_found`, `member_not_found`, `version_not_found`, `song_not_found`, `merge_request_not_found` |
| `P0001` | `invite_revoked`, `invite_expired`, `invite_used_up`, `already_member`, `already_invited`, `cannot_invite_self`, `invitation_not_pending`, `last_admin`, `band_not_in_organization`, `organization_archived`, `archive_already_requested`, `archive_not_requested`, `account_deactivated`, `member_deactivated`, `merge_same_song`, `merge_cycle`, `merge_already_requested`, `merge_not_pending` |
| `23505` | `username_taken` |

`join_with_invite_link` checks, in order: not found, organization archived, revoked, expired, used up.

### Sign-up

The username comes from user metadata: `signUp(..., data: {'username': 'jane', 'display_name': 'Jane'})`.
A missing or malformed username makes sign-up fail (`invalid_username`), and a taken one fails with
`username_taken`. Call `is_username_available` first for a friendly check.

### Realtime

`organization_members`, `calendar_events`, `event_assignments`, `invitations` and `notifications` are in the
`supabase_realtime` publication (RLS applies to realtime too).

---

## 4. Local development and tests

Requires the Supabase CLI and Docker.

```bash
supabase start        # first run pulls images and can take several minutes
supabase db reset     # applies migrations/ to an empty local database (safe to repeat)
supabase test db      # runs the pgTAP tests in supabase/tests/
```

Tests (`supabase/tests/*.test.sql`) run as different users by switching role and JWT claims
(alice/admin, bob/member, carol/outsider, anonymous, deactivated users, ...) and roll back at the end.
Each file is self-contained and defines a small `tests` helper schema (`tests.as_user('bob')`,
`tests.as_anon()`, `tests.reset()`).

- `01_profiles_and_schema`: schema shape, RLS everywhere, sign-up trigger, username rules, search, anonymous access.
- `02_organizations_and_permissions`: membership, role changes, self-promotion attack, last admin, band
  membership, setlists/events/assignments permissions, quotas.
- `03_invites`: invite links and invitations, every RPC happy path and error code.
- `04_archive`: archive request/approve/cancel, read-only archived organizations.
- `05_deactivation`: deactivated accounts and `auth.users` deletion.
- `06_songs`: visibility (anon/outsider/member/admin), owner-only editing, repertoire, setlist tombstones, forks, merges.
- `07_availability_notifications`: absences, assignment responses, notifications.
- `08_personal_setlists`: personal vs organization setlists, privacy, overrides, tombstones, immutability of owner.
- `09_calendar_details`: event type, same-organization setlist and series links, unique occurrences, admin-only writes.

`supabase/.gitignore` keeps local-only files (`.branches`, `.temp`) out of git.

## 5. Deploying to a hosted project

```bash
supabase link --project-ref <ref>
supabase db push
```

Then copy the Project URL and the publishable (anon) key into the app (`SUPABASE_URL` and
`SUPABASE_ANON_KEY` in `.env`, or Settings > Cloud Synchronization).

## 6. How the app uses the song tables

The app keeps every song, score and setlist in Drift and syncs them with this schema (see
`lib/features/sync/`). Things that matter when changing the schema:

- A local song row is one `song_versions` row (`Song.id` = version id); `songs` is created on the first push.
- Clients cannot `INSERT ... RETURNING` a version (the select policy cannot see the row inside the statement
  that creates it): insert, then read `updated_at`.
- Clients cannot upsert a version either (no update grant on `id`, `song_id`, `owner_id`): the app inserts
  new versions and updates the editable columns of existing ones.
- Embedding a setlist's items needs the foreign key hint `setlist_items!setlist_items_setlist_fkey(*)`
  (there are two relationships: the composite one for organizations and the plain one).
- **Conflicts use `edited_at`, not `updated_at`.** `updated_at` is set by the server on every update (a push,
  a song merge moving versions, a share cleanup) and only tells a device that something changed.
  `song_versions`, `scores` and `setlists` also have `edited_at`: the time the user last edited the content,
  stamped by the editing device with millisecond precision. Only clients write it, no trigger or server
  function does (pgTAP checks that a merge leaves it alone). When a push finds the backend row changed since
  the device last synced, the later `edited_at` wins; a merge alone therefore never discards a pending edit.
  On the device the same value (`editedAtMs`) grows with every save, so a save made while a push is in
  flight keeps the row dirty.
- **Sharing is pushed separately.** Label, visibility and the `version_shares` diff go out when they changed
  locally (`sharingDirty`), independent of who won the content conflict. A share the backend refuses (for
  example an organization the owner does not belong to) is reported once and the local copy takes the
  backend's sharing, so it is not retried on every sync.
- **Fork lineage.** Clients may set `forked_from_version_id` on insert (a fork made offline), but the parent
  must be visible to the owner. `fork_song_version` remains the way to fork online (it also copies scores).
- **Known limitation: resurrection.** The backend keeps no tombstones for hard deletes. If a version was
  deleted on one device and another device still has a pending edit of it, the edit re-creates the version
  as the owner's version on its next push (non-destructive choice). Without a pending edit the deletion
  reaches the other device through the reconcile of visible ids.
- Changing a song's title or artist locally only reaches the backend when the user created the song (`songs`
  is shared by every version of it); on a song created by someone else the sync restores the shared title.
