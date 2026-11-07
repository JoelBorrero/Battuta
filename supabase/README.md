# Battuta Supabase Cloud Architecture & Sync Strategy

This directory contains the PostgreSQL schema and Row Level Security (RLS) policies for Battuta's cloud synchronization and band collaboration backend.

---

## 1. Architectural Philosophy: Offline-First Invariant (FR-1.2)

Battuta is designed primarily for live musical performance on stage (iPadOS and macOS) where WiFi can drop unexpectedly.
- **Local Drift (SQLite)** is the single source of truth for the UI layer.
- The UI never waits for or directly queries remote Supabase endpoints.
- All writes are committed locally to Drift instantly.
- When an internet connection is available, the `SupabaseCloudSyncService` executes two-way background synchronization:
  1. **Push**: Uploads local changes (Songs, Scores, Setlists) to Supabase tables.
  2. **Pull**: Fetches records modified since the `lastSyncedAt` timestamp.
  3. **Conflict Resolution**: Employs deterministic **Last-Write-Wins (LWW)** using ISO-8601 UTC timestamps (`updated_at`), preserving whichever change was authored most recently.

---

## 2. PostgreSQL Schema & RLS

The database migration is located in:
`supabase/migrations/20261107000000_battuta_schema.sql`

### Tables Included:
1. `teams`: Team/band workspace entity.
2. `team_members`: Band roster with roles (`pianist`, `electricGuitar`, etc.), vocal pitch ranges, availability status, and `is_admin` privileges.
3. `scores`: Root musical score tree (tempo, key, time signature, JSON sections, metadata).
4. `sections`: Sections of a score (Intro, Verse, Chorus, Bridge, etc.) with format and indications.
5. `measures`: Granular measure details, measure numbers, and time signatures.
6. `note_events`: Pitches, duration in ticks, and lyrics.
7. `chord_symbols`: Harmonic symbols with beat offset ticks.
8. `songs`: Repertoire song catalog (chords, sections, lyrics, tags).
9. `setlists`: Performance setlists with ordered items.
10. `calendar_events`: Scheduled rehearsal and service events with assigned musicians.

### Row Level Security (RLS):
- All tables enforce strict RLS.
- Helper functions `public.is_team_member(team_id)` and `public.is_team_admin(team_id)` ensure that users can only read and write scores, songs, setlists, and calendar entries belonging to teams they are members of.
- Direct user ownership (`owner_id = auth.uid()`) is also respected for private lead sheets.

---

## 3. How to Deploy to Supabase

1. Create a free or Pro project at [supabase.com](https://supabase.com).
2. Go to the **SQL Editor** in your Supabase Dashboard.
3. Paste the contents of `supabase/migrations/20261107000000_battuta_schema.sql` and click **Run**.
4. Go to **Project Settings > API**:
   - Copy the **Project URL**.
   - Copy the **`anon` `public` key**.
5. Configure in Battuta:
   - Either add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to your local `.env` file, or
   - In the Battuta app, navigate to **Settings > Cloud Synchronization (Supabase) > Supabase Connection** and paste the credentials directly.
