---
status: done
commit: "feat(auth): add welcome flow, organization context and real roster"
base_sha: 029489f
rounds: 2 of 3
---
# 005: Sign-in, organization context and the Roster on real data

**Goal:** put the app on real accounts: welcome flow, account settings, organization and band switcher, demo
mode removed, and the Team page's Roster on real members, bands and roles.

> Run unattended under the user's delegation. Integration tests were written but **not run** (Docker down):
> see the top of `.pipeline/backlog.md`.

## What changed
- **Welcome flow:**
  - First launch shows `WelcomePage` with Sign in, Create account (username with live availability) and
    Continue offline. Continue offline is remembered.
  - `AppEntry` (`firstLaunch | offline | signedIn`) drives a pure `resolveAppRedirect` in GoRouter.
  - A deactivated account lands on welcome with a message, and can still reach sign-in and create-account.
    The notice clears on any sign-in.
  - A restored session opens the app with no welcome flash.
- **Account settings:** an Account section replaces the old Cloud Account row and `SupabaseAuthDialog`, with
  profile, sign out, deactivate (typed username confirmation) and sign in.
- **Data layer start:** `accountLifecycleProvider` starts the 003 coordinator and the 004 song sync on sign-in
  and session restore, deduplicated per account. Sign-out clears everything (003 rules).
- **Organization context:**
  - `activeOrganizationProvider` is persisted per account and falls back to the first active org.
    `activeBandIdProvider` sets an optional band filter.
  - A switcher in the Team app bar lists your organizations with role badges, plus bands and
    Create organization. Archived organizations are hidden. With no organization, the Team page shows an
    empty state.
- **Who you are:**
  - `currentMemberProvider` is your membership in the active organization.
  - `isCurrentUserAdminProvider` is true in local mode or with no active organization; otherwise it is your
    role.
  - The "act as member" switcher (`currentMemberIdProvider`) is deleted.
- **Roster on real data:** `teamMembersProvider` and `teamGroupsProvider` adapt the 003 entities, filtered by
  the active band.
  - Admins edit instruments, pitch range, notes, bands and role, remove members, and manage bands.
  - Members edit only themselves and can leave.
  - Errors are localized and nothing is optimistic. A partly saved member says so, and a retry re-reads the
    roster first.
  - "You" badge and admin shield. Destructive actions use `colorScheme.error`.
- **Invites placeholder:** "Add member" is gone; admins see a disabled "Invite · Coming soon" (007 enables it).
- **Demo mode removed:** the provider, `DemoCloudSyncService`, the Settings toggle, the sample
  members/groups/events, the `isDemo` parameters, and their tests and strings. Bundled `seed-*` songs stay
  (local only).
- **Strings:** en and es. Layout tests cover 320–1440 px.

## Decisions
- The Roster's summary stats, the "Scheduled" filter, the per-card status badge and "Schedule for service"
  were removed: they only worked with demo data. Availability is now absences (006).
- The Calendar tab was left local in 005; 006 replaces it with real data.
- `cloud_sync_offline_test` has a 3-minute timeout. The offline retries in supabase 2.16.5 cannot be turned
  off through `from()` (see the backlog).

## Deferred
See `.pipeline/backlog.md` (005 section and the "Verify first" section).

## Verification
`flutter analyze`: 0 issues. `flutter test`: 735 passed (3 integration files skipped). The integration test
`test/integration/roster_test.dart` is written but not run.
