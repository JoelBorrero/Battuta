---
status: done
commit: "feat(repertoire): add organization repertoire, org setlists and organization settings"
base_sha: c9f9663
rounds: 2 of 3
---
# 008: Organization repertoire, org setlists and admin tools

**Goal:** admins curate their organization's repertoire and setlists and manage the organization (rename,
archive). Members see the repertoire and setlists read-only. Nobody can edit a version they don't own.

> Run unattended under the user's delegation. The integration suite ran against the local stack.

## What changed
- **Scope switcher (Repertoire page):** "My library" shows my own versions plus local-mode songs. Each
  organization I belong to gets its own repertoire view, built from a cached copy of `organization_repertoire`
  with a title/artist/key/label/owner snapshot, so it works offline. Owners show as "Owned by …", with
  "(deactivated)" where it applies.
- **Curation (admins only):** `OrganizationRepertoireRepository` (remote and cache).
  - "Add to repertoire" opens an online picker. The server returns only versions visible to the organization
    (public, or shared with it), page by page, with my own first.
  - "Remove from repertoire" asks for confirmation.
  - A successful add starts a sync. Entries not yet on the device show "Syncing…" (or "Available after the next
    sync" offline), and tapping one syncs before it opens.
- **Read-only versions:**
  - `songEditRedirect` sends non-owners from the editor and notation routes to the viewer, which shows an
    "Owned by" banner and hides edit, delete, notation and inline chord edits.
  - The transpose sheet offers "Save Transposed Key" only to owners.
  - A failed save rolls the list back and shows a localized message instead of breaking the page.
- **Editing your own songs depends on ownership, not role:** the repertoire page and song editor moved off
  `isCurrentUserAdminProvider`, so admins, members and people with no org can all edit their own songs. The
  admin check stays for organization actions (invites, roster, the Gemini key).
- **Org setlists:**
  - The setlist list follows the scope. Admins create, edit and delete; members read and can transpose locally.
  - Org setlist pickers offer that organization's repertoire. Personal setlist pickers offer only My library.
  - `canAdministerOrganization` is wired in `database_providers.dart` from the current memberships, so role
    changes apply at once.
- **Organization settings** (`/organizations/:organizationId/settings`): reached from the Repertoire app bar,
  the switcher, and archive notifications.
  - Shows name, my role, rename, quota, and Leave (the last-admin error is explained).
  - **Archive:** request, admins' approval status, approve and cancel. It warns that archiving cannot be
    undone from the app and asks you to type the organization's name. An archived organization leaves the
    switcher.
- **Cloud sync:** a sync that pulled rows reloads the repertoire and setlists. A trigger while a sync is
  running joins it instead of reporting "already active".
- **Strings** in en and es; layout tests cover 320–1440 px.

## Decisions
- No schema change in this task.
- The repertoire refreshes on demand rather than in realtime (realtime needs a migration; see the backlog).

## Deferred
See `.pipeline/backlog.md` (008 section).

## Verification
`flutter analyze`: 0 issues. `flutter test`: 962 passed. `supabase db reset`, then the integration suite:
47 passed.
