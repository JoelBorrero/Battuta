-- ==============================================================================
-- Battuta — Demo Mode Cloud Synchronization & Multi-Device Realtime Schema
-- ==============================================================================
-- This migration enables live two-way synchronization between multiple devices
-- running in Demo Mode while preserving absolute isolation from production data.
--
-- Approach:
-- 1. Uses an `is_demo BOOLEAN NOT NULL DEFAULT false` column on all shared tables
--    (teams, team_members, team_groups, calendar_events, recurring_schedules, songs, setlists).
-- 2. Grants `anon` and `authenticated` access to rows where `is_demo = true` so any
--    demo device can read, insert, and update demo state without requiring individual
--    user registrations.
-- 3. Pre-populates the 30 demo worship team members, Ensamble 1/2/3 groups, and
--    calendar schedules into a dedicated Demo Team workspace.
-- ==============================================================================

-- 1. Ensure `is_demo` column exists on existing tables
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.team_members ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.team_members ADD COLUMN IF NOT EXISTS group_ids TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE public.team_members ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.team_members ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.songs ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.setlists ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.scores ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;

-- 2. Create `team_groups` table if not exists
CREATE TABLE IF NOT EXISTS public.team_groups (
    id TEXT PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    color_value BIGINT NOT NULL DEFAULT 4293233212, -- 0xFFE5A93C (Stage Amber)
    is_demo BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. Create `recurring_schedules` table if not exists
CREATE TABLE IF NOT EXISTS public.recurring_schedules (
    id TEXT PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    day_of_week INTEGER NOT NULL DEFAULT 7, -- 1=Monday, 7=Sunday
    pattern TEXT NOT NULL DEFAULT 'weekly',
    lookahead_count INTEGER NOT NULL DEFAULT 4,
    is_active BOOLEAN NOT NULL DEFAULT true,
    disabled_after TIMESTAMPTZ,
    is_demo BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. Automated updated_at triggers
CREATE OR REPLACE TRIGGER trg_team_groups_updated_at
    BEFORE UPDATE ON public.team_groups
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER trg_recurring_schedules_updated_at
    BEFORE UPDATE ON public.recurring_schedules
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5. Enable Row Level Security (RLS) on newly created tables
ALTER TABLE public.team_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recurring_schedules ENABLE ROW LEVEL SECURITY;

-- 6. Indexes for high-speed demo filtering
CREATE INDEX IF NOT EXISTS idx_teams_is_demo ON public.teams(is_demo);
CREATE INDEX IF NOT EXISTS idx_team_members_is_demo ON public.team_members(is_demo);
CREATE INDEX IF NOT EXISTS idx_team_groups_is_demo ON public.team_groups(is_demo);
CREATE INDEX IF NOT EXISTS idx_calendar_events_is_demo ON public.calendar_events(is_demo);
CREATE INDEX IF NOT EXISTS idx_recurring_schedules_is_demo ON public.recurring_schedules(is_demo);
CREATE INDEX IF NOT EXISTS idx_songs_is_demo ON public.songs(is_demo);
CREATE INDEX IF NOT EXISTS idx_setlists_is_demo ON public.setlists(is_demo);

-- 7. Row Level Security Policies for Demo Data Synchronization
-- Demo records (is_demo = true) can be read, created, and updated by both anon and authenticated users
CREATE POLICY "Allow public read of demo teams"
    ON public.teams FOR SELECT
    TO anon, authenticated
    USING (is_demo = true);

CREATE POLICY "Allow public read and write of demo team members"
    ON public.team_members FOR ALL
    TO anon, authenticated
    USING (is_demo = true)
    WITH CHECK (is_demo = true);

CREATE POLICY "Allow public read and write of demo team groups"
    ON public.team_groups FOR ALL
    TO anon, authenticated
    USING (is_demo = true)
    WITH CHECK (is_demo = true);

CREATE POLICY "Allow public read and write of demo calendar events"
    ON public.calendar_events FOR ALL
    TO anon, authenticated
    USING (is_demo = true)
    WITH CHECK (is_demo = true);

CREATE POLICY "Allow public read and write of demo recurring schedules"
    ON public.recurring_schedules FOR ALL
    TO anon, authenticated
    USING (is_demo = true)
    WITH CHECK (is_demo = true);

CREATE POLICY "Allow public read and write of demo songs"
    ON public.songs FOR ALL
    TO anon, authenticated
    USING (is_demo = true)
    WITH CHECK (is_demo = true);

CREATE POLICY "Allow public read and write of demo setlists"
    ON public.setlists FOR ALL
    TO anon, authenticated
    USING (is_demo = true)
    WITH CHECK (is_demo = true);

-- 8. Seed Fixed Demo Workspace & Ensembles
INSERT INTO public.teams (id, name, is_demo)
VALUES ('00000000-0000-0000-0000-000000000001', 'Ensamble de Alabanza Battuta (Demo)', true)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, is_demo = true;

-- Seed Groups: Ensamble 1, Ensamble 2, Ensamble 3
INSERT INTO public.team_groups (id, team_id, name, description, color_value, is_demo)
VALUES
    ('group-alpha', '00000000-0000-0000-0000-000000000001', 'Ensamble 1', 'Primer ensamble de alabanza y adoración', 4293233212, true),
    ('group-beta', '00000000-0000-0000-0000-000000000001', 'Ensamble 2', 'Segundo ensamble de alabanza y adoración', 4283142370, true),
    ('group-gamma', '00000000-0000-0000-0000-000000000001', 'Ensamble 3', 'Tercer ensamble de alabanza y adoración', 4283499458, true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    color_value = EXCLUDED.color_value,
    is_demo = true;

-- 9. Enable Realtime Replication on Demo Tables for live multi-device broadcasting
ALTER PUBLICATION supabase_realtime ADD TABLE public.team_members;
ALTER PUBLICATION supabase_realtime ADD TABLE public.team_groups;
ALTER PUBLICATION supabase_realtime ADD TABLE public.calendar_events;
ALTER PUBLICATION supabase_realtime ADD TABLE public.recurring_schedules;

-- 10. Seed the 30 Demo Team Members
INSERT INTO public.team_members (id, team_id, name, roles, status, is_admin, group_ids, notes, email, is_demo)
VALUES
    ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001', 'Joel', '{keys,synth}', 'available', true, '{group-gamma}', 'Piano, Synthesizer & Worship Director', 'joel@battuta.music', true),
    ('00000000-0000-0000-0001-000000000002', '00000000-0000-0000-0000-000000000001', 'Raúl', '{acousticGuitar}', 'available', false, '{group-alpha}', 'Acoustic guitar rhythm & fingerpicking', 'raul@battuta.music', true),
    ('00000000-0000-0000-0001-000000000003', '00000000-0000-0000-0000-000000000001', 'Pipe', '{bass}', 'available', false, '{group-gamma}', 'Electric bass groove & fundamentals', 'pipe@battuta.music', true),
    ('00000000-0000-0000-0001-000000000004', '00000000-0000-0000-0000-000000000001', 'Jose', '{drums}', 'available', false, '{group-alpha,group-beta,group-gamma}', 'Drums & rhythm section lock', 'jose@battuta.music', true),
    ('00000000-0000-0000-0001-000000000005', '00000000-0000-0000-0000-000000000001', 'Amparito', '{leadVocal,backingVocal}', 'available', false, '{group-beta}', 'Lead voice & vocal harmony direction', 'amparito@battuta.music', true),
    ('00000000-0000-0000-0001-000000000006', '00000000-0000-0000-0000-000000000001', 'Andrés', '{backingVocal}', 'available', false, '{group-alpha}', 'Tenor vocal harmonies', 'andres@battuta.music', true),
    ('00000000-0000-0000-0001-000000000007', '00000000-0000-0000-0000-000000000001', 'Anita García', '{leadVocal,backingVocal}', 'available', false, '{group-beta}', 'Soprano lead & vocal support', 'anita.garcia@battuta.music', true),
    ('00000000-0000-0000-0001-000000000008', '00000000-0000-0000-0000-000000000001', 'Daniel', '{bass,drums,sound}', 'available', true, '{group-gamma}', 'Multi-instrumentalist: Bass, Drums & Front of House Sound', 'daniel@battuta.music', true),
    ('00000000-0000-0000-0001-000000000009', '00000000-0000-0000-0000-000000000001', 'Daniela', '{backingVocal}', 'available', false, '{group-gamma}', 'Soprano backing vocals', 'daniela@battuta.music', true),
    ('00000000-0000-0000-0001-000000000010', '00000000-0000-0000-0000-000000000001', 'Diego', '{drums,synth,keys}', 'available', false, '{group-alpha,group-beta,group-gamma}', 'Drums, Synth pads & auxiliary keys', 'diego@battuta.music', true),
    ('00000000-0000-0000-0001-000000000011', '00000000-0000-0000-0000-000000000001', 'Epsa', '{leadVocal,backingVocal}', 'available', false, '{group-alpha}', 'Lead voice & vocal harmonies', 'epsa@battuta.music', true),
    ('00000000-0000-0000-0001-000000000012', '00000000-0000-0000-0000-000000000001', 'Humberto', '{keys,backingVocal}', 'available', false, '{group-beta}', 'Piano, keyboards & vocal support', 'humberto@battuta.music', true),
    ('00000000-0000-0000-0001-000000000013', '00000000-0000-0000-0000-000000000001', 'Jeimy', '{backingVocal}', 'available', false, '{group-gamma}', 'Chorus vocals', 'jeimy@battuta.music', true),
    ('00000000-0000-0000-0001-000000000014', '00000000-0000-0000-0000-000000000001', 'Juanse', '{leadVocal,backingVocal}', 'available', false, '{group-alpha}', 'Tenor lead & vocal direction', 'juanse@battuta.music', true),
    ('00000000-0000-0000-0001-000000000015', '00000000-0000-0000-0000-000000000001', 'July', '{leadVocal,backingVocal}', 'available', false, '{group-gamma}', 'Soprano lead & chorus harmonies', 'july@battuta.music', true),
    ('00000000-0000-0000-0001-000000000016', '00000000-0000-0000-0000-000000000001', 'Laura', '{leadVocal,backingVocal}', 'available', false, '{group-beta}', 'Lead voice & vocal harmonies', 'laura@battuta.music', true),
    ('00000000-0000-0000-0001-000000000017', '00000000-0000-0000-0000-000000000001', 'Mile', '{leadVocal,backingVocal}', 'available', false, '{group-alpha}', 'Alto lead & backing voice', 'mile@battuta.music', true),
    ('00000000-0000-0000-0001-000000000018', '00000000-0000-0000-0000-000000000001', 'Mona', '{leadVocal,backingVocal}', 'available', true, '{group-gamma}', 'Vocal lead & chorus', 'mona@battuta.music', true),
    ('00000000-0000-0000-0001-000000000019', '00000000-0000-0000-0000-000000000001', 'Monica', '{backingVocal}', 'available', false, '{group-beta}', 'Chorus vocals', 'monica@battuta.music', true),
    ('00000000-0000-0000-0001-000000000020', '00000000-0000-0000-0000-000000000001', 'Nico', '{electricGuitar}', 'available', false, '{group-alpha,group-beta,group-gamma}', 'Lead electric guitar & ambient textures', 'nico@battuta.music', true),
    ('00000000-0000-0000-0001-000000000021', '00000000-0000-0000-0000-000000000001', 'P. Henry', '{leadVocal,backingVocal}', 'available', false, '{group-alpha,group-beta,group-gamma}', 'Lead vocals & pastoral guidance', 'henry@battuta.music', true),
    ('00000000-0000-0000-0001-000000000022', '00000000-0000-0000-0000-000000000001', 'Ricardo', '{acousticGuitar,leadVocal,backingVocal,keys}', 'available', true, '{group-alpha,group-beta,group-gamma}', 'Acoustic guitar, Lead voice, Piano', 'ricardo@battuta.music', true),
    ('00000000-0000-0000-0001-000000000023', '00000000-0000-0000-0000-000000000001', 'Samu García', '{keys}', 'available', false, '{group-alpha}', 'Piano & keyboard arrangements', 'samu.garcia@battuta.music', true),
    ('00000000-0000-0000-0001-000000000024', '00000000-0000-0000-0000-000000000001', 'Samu Saldaña', '{drums}', 'available', false, '{group-alpha}', 'Drums & percussion', 'samu.saldana@battuta.music', true),
    ('00000000-0000-0000-0001-000000000025', '00000000-0000-0000-0000-000000000001', 'Sandra', '{leadVocal,backingVocal}', 'available', false, '{group-alpha}', 'Alto lead & chorus', 'sandra@battuta.music', true),
    ('00000000-0000-0000-0001-000000000026', '00000000-0000-0000-0000-000000000001', 'Sara', '{leadVocal,backingVocal}', 'available', false, '{group-beta}', 'Soprano lead & chorus', 'sara@battuta.music', true),
    ('00000000-0000-0000-0001-000000000027', '00000000-0000-0000-0000-000000000001', 'Saris', '{backingVocal}', 'available', false, '{group-gamma}', 'Soprano chorus harmonies', 'saris@battuta.music', true),
    ('00000000-0000-0000-0001-000000000028', '00000000-0000-0000-0000-000000000001', 'Vicky', '{backingVocal}', 'available', false, '{group-alpha}', 'Alto chorus', 'vicky@battuta.music', true),
    ('00000000-0000-0000-0001-000000000029', '00000000-0000-0000-0000-000000000001', 'Zulma', '{backingVocal}', 'available', false, '{group-beta}', 'Alto chorus harmonies', 'zulma@battuta.music', true),
    ('00000000-0000-0000-0001-000000000030', '00000000-0000-0000-0000-000000000001', 'Margarita', '{sound}', 'available', false, '{group-alpha,group-beta,group-gamma}', 'Ingeniera de Sonido / Front of House Audio', 'margarita@battuta.music', true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    roles = EXCLUDED.roles,
    is_admin = EXCLUDED.is_admin,
    group_ids = EXCLUDED.group_ids,
    notes = EXCLUDED.notes,
    email = EXCLUDED.email,
    is_demo = true;
