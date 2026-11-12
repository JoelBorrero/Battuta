---
status: done
commit: "feat(profile): add profile photos, organization logos and redesigned profile pages"
base_sha: a972add
rounds: 1 of 3 (+ main-session fixes)
---
# 012: Profile photos, organization logos and redesigned profile pages

**Goal:** people add their own profile photo, admins add an organization logo, and both profile pages follow
the approved design canvas "Battuta Profile Pages" (My profile, Change photo sheet, Organization profile).

## What changed
- **Server** (`supabase/migrations/20261112000000_profile_photos.sql`):
  - Public-read Storage buckets `avatars` and `organization-logos` (2 MB, jpeg/png/webp).
  - Storage policies: a user writes only under `avatars/<own id>/`, which a deactivated account cannot do.
    Only an admin of a non-archived organization writes under `organization-logos/<org id>/`, through
    `can_write_org_logo`.
  - Profile and organization columns: `profiles.avatar_url` is replaced by `avatar_path`. Organizations gain
    `logo_path` and `description` (≤ 280).
  - Rewritten functions: deactivation clears `avatar_path`, and `search_profiles` is updated.
  - pgTAP: `11_profile_photos.test.sql`, and `05` is adjusted.
- **Data:** entities carry `avatarPath`, `logoPath` and `description`. The database stores object paths, and
  the URL is built from the active Supabase client, so a row works on remote, local and a phone on the LAN IP.
  Repository methods: `setMyAvatar` / `removeMyAvatar`, `setOrganizationLogo` / `removeOrganizationLogo` and
  `updateOrganizationProfile`.
  - Each upload gets a new uuid path. The old object is deleted after the row swap (best effort), and the new
    object is removed if the swap fails, so the old image survives a failure.
  - New `imageTooLarge` error code and Storage error mapping.
- **Picker:** a new `ProfileImagePicker` (image_picker + image_cropper, circle or square guide, 512×512 JPEG
  at ~85). It falls back to the uncropped image only where no native cropper exists
  (`MissingPluginException`/`UnimplementedError`); other cropper errors reach the sheet.
- **UI:**
  - **Shared widgets:** `PersonAvatar` and `OrganizationLogo` are used in the top bar (with an end margin),
    the Settings account row, My profile, Organization profile, roster cards, the switcher and the My
    organizations cards.
  - **My profile** is rebuilt from the canvas (amber meter banner, ringed avatar with camera button, chips,
    stat tiles, organization cards, App settings and Sign out).
  - **Change photo sheet:** it cannot be dismissed while saving or removing.
  - **Organization profile:** a new page at `/organizations/:organizationId`, plus an edit sheet for admins
    (name and description).
- **Platforms and strings:** iOS camera and photo-library usage keys, Android `UCropActivity`, and 37 en/es
  strings.

## Decisions
- Paths, not URLs, in the database; public buckets with unguessable names; no offline image cache (initials
  and music-note tile fallbacks).
- Tapping an organization card opens its profile; switching organizations is in the card's ⋯ menu.
- Invite, Manage, See all and Next up on a non-active organization make it active first, because those sheets
  and tabs work on the active organization.
- Stats: Versions is the length of my library; Upcoming counts the active organization only; Next up shows
  `time · band` (setlist song counts are not in the calendar models).

## Deferred
See `.pipeline/backlog.md` (012 section).

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1235 passed. `supabase db reset` ×2, then `supabase test db`:
11 files, 761 tests, PASS. Integration suite after a reset: 70 passed (profile photos 10/10). The debug APK
builds and installs; the camera/crop/upload path was not yet exercised on a device.
