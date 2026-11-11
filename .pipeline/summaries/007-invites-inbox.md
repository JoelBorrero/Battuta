---
status: done
commit: "feat(organizations): add invite links, QR, username invites and inbox"
base_sha: b27fd3b
rounds: 2 of 3
---
# 007: Invites (link, QR, username) and the notifications inbox

**Goal:** admins invite people by a shareable link, a QR code or a username. Invited people join from the
link or accept an in-app invitation. Everyone has a notifications inbox with an unread badge.

> Run unattended under the user's delegation. Docker came back during this task. The integration suite
> (44 tests, including the 005 and 006 ones) passes against the real stack.

## What changed
- **Dependencies:** `qr_flutter`, `share_plus` and `app_links`. The Android manifest accepts `battuta://join`
  only, with no new permissions. iOS already had the scheme, and there is no macOS platform.
- **Invite sheet (admins only, replaces "Invite · Coming soon"):**
  - **Link & QR tab:** create a link with an expiry, optional max uses and an optional band. It shows the
    link `battuta://join/<token>`, a QR code, Copy and Share. Active links list their uses and expiry, and
    Revoke asks for confirmation.
  - **Username tab:** debounced search shows username and display name, never email, and marks "previously
    declined". Invite with an optional band; pending invitations can be cancelled. Server errors are localized.
- **Joining:**
  - Links are parsed strictly (scheme `battuta`, host `join`, token `[A-Za-z0-9_-]{16,128}`) and routed to
    `/join/:token`. Links that open the app are picked up by `app_links` and checked again in the router
    redirect.
  - A "Paste invite link or code" field appears on welcome, in the Team and Calendar empty states, and in the
    organization switcher.
  - Signed in: joins and switches to that organization. Already a member counts as success, and errors open a
    join result page.
  - Signed out: the token is kept in memory only, and a note on welcome can dismiss it. After sign-in the
    join asks for confirmation, naming the account; Cancel does not join.
  - Sign-out, account switch, "Continue offline" and signing out while the confirmation is open all drop the
    token, so it never reaches another account.
- **Invitations for me:** a banner on Team and cards at the top of the inbox, with Accept and Decline.
  Accepting switches organization, and answering marks the invitation's notification read.
- **Inbox:**
  - The inbox button with an unread badge is on every tab. It is an inbox icon, because Team already has a
    bell for cover alerts.
  - One localized sentence per `NotificationType` (en and es), with a generic line for unknown types.
  - Tap routing: Roster, the Calendar tab, the invitation card; merge notifications go to the repertoire and
    archive notifications to the Roster.
  - Mark all read; opens offline from the cache. The badge ignores invitations that are no longer pending.
- **Data layer (003):** `fetchInvitations` embeds the invitee's profile (admin-only through RLS), and
  `inviteUserByUsername` fills in the username locally.

## Decisions
- The join confirmation says "Join this organization?". The name needs a new RPC (backlog).
- Notification taps open the right tab, not the specific item.

## Deferred
See `.pipeline/backlog.md` (007 section).

## Verification
`flutter analyze`: 0 issues. `flutter test`: 868 passed. `supabase db reset`, then the integration suite:
44 passed.
