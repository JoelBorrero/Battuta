---
status: done
commit: "feat(profile): add a profile view opened from a top-bar avatar"
base_sha: 7ec6241
rounds: 1 of 3 (+ main-session fix)
---
# 011: Profile view, opened from an avatar in the top bar

**Goal:** one place for "me": account details, my organizations, sign out and deactivate. The Leave
(Team) and Deactivate (Settings) buttons that took too much room move here.

## What changed
- **Entry:** `ProfileAvatarButton` (initials, accent ring, ≥ 44) in the app bar of Repertoire, Live, Team and
  Settings. Signed out it shows a person icon and opens sign-in. `/profile` is a pushed top-level route; the
  redirect sends signed-out access to sign-in.
- **Profile page** (`lib/features/profile/`): header (initials, name, @username, email); "Edit profile" sheet
  for display name and username (lower-cased, live availability check where your own username counts as
  available); "My organizations" with role badge and your instruments, tap to make it active, and a ⋯ menu:
  edit my instruments, organization settings (admins), leave (non-admins; disabled with a hint for admins);
  empty state with "Join with a link"; Sign out at the bottom; Deactivate in the app bar ⋯ menu with the
  existing type-your-username confirmation.
- **Data:** `AuthRepository.updateMyProfile` updates your own `profiles` row (a bare 23505 maps to
  `usernameTaken`; an update that changes no row fails with `permissionDenied`) and refreshes
  `myProfileProvider`, which moved to `auth_provider.dart`. Instruments use `updateMusicianProfile` on your own
  membership. Leave uses `ProfileActions.leave(organizationId)`; `RosterActions.leaveOrganization` was removed.
- **Removed:** the roster's Leave button and its card-menu Leave item; Sign out and Deactivate from Settings,
  whose Account section is now one row that opens Profile.
- **Repertoire app bar:** below 480 px the import and scan icons move into the ⋯ menu so the avatar fits.
- Strings in en and es; unit, widget, redirect and responsive tests (now including 320 px); integration
  `test/integration/profile_test.dart` (username taken/free, own instruments only).

## Decisions
- Entry from a top-bar avatar; name, username and instruments are editable (user's choices).
- Instruments are edited per organization, because they belong to the membership.
- Admins cannot leave from the app; they hand over admin rights in organization settings first.
- Sign out from Profile goes to Repertoire first, so no stale Profile stays on the stack.

## Deferred
See `.pipeline/backlog.md` (011 section).

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1149 passed. Integration `profile_test.dart`: 5/5 against the local
stack (implementer, adversary and main session after the zero-row fix).
