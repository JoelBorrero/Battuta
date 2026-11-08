-- ==============================================================================
-- Battuta — Demo Mode Cloud Synchronization & Multi-Device Realtime Schema
-- ==============================================================================
-- This migration enables live two-way synchronization between multiple devices
-- running in Demo Mode while preserving absolute isolation from production data.
--
-- Self-Contained & Fully Idempotent:
-- 1. Creates extensions and `handle_updated_at()` trigger function if not present.
-- 2. Creates base tables (teams, team_members, team_groups, recurring_schedules,
--    calendar_events, songs, setlists, scores) with `CREATE TABLE IF NOT EXISTS`.
-- 3. Adds `is_demo` and missing columns with `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`.
-- 4. Replaces triggers, enables RLS, and sets up idempotent RLS policies.
-- 5. Safely registers tables in Supabase Realtime publication.
-- 6. Pre-populates the Demo Workspace, Ensembles 1-3, and the 30 Demo Musicians.
-- ==============================================================================

-- 1. Prerequisites
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Automated updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Base Tables (created IF NOT EXISTS to guarantee independence from prior migrations)

-- Teams
CREATE TABLE IF NOT EXISTS public.teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    is_demo BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Team Members
CREATE TABLE IF NOT EXISTS public.team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    roles TEXT[] NOT NULL DEFAULT '{}',
    min_pitch TEXT,
    max_pitch TEXT,
    status TEXT NOT NULL DEFAULT 'available',
    is_admin BOOLEAN NOT NULL DEFAULT false,
    group_ids TEXT[] NOT NULL DEFAULT '{}',
    notes TEXT,
    email TEXT,
    is_demo BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Team Groups (Ensembles)
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

-- Recurring Schedules
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

-- Calendar Events
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id TEXT PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    date_time TIMESTAMPTZ NOT NULL,
    location TEXT,
    notes TEXT,
    assignments_json TEXT NOT NULL DEFAULT '[]',
    is_demo BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Songs
CREATE TABLE IF NOT EXISTS public.songs (
    id TEXT PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    key TEXT NOT NULL,
    tempo INTEGER NOT NULL DEFAULT 120,
    time_signature_beats INTEGER NOT NULL DEFAULT 4,
    time_signature_beat_value INTEGER NOT NULL DEFAULT 4,
    sections_json TEXT NOT NULL DEFAULT '[]',
    tags_json TEXT NOT NULL DEFAULT '[]',
    cover_image_path TEXT,
    notes TEXT,
    is_demo BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Setlists
CREATE TABLE IF NOT EXISTS public.setlists (
    id TEXT PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    event_date TIMESTAMPTZ,
    items_json TEXT NOT NULL DEFAULT '[]',
    tags_json TEXT NOT NULL DEFAULT '[]',
    is_demo BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Scores
CREATE TABLE IF NOT EXISTS public.scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    song_id TEXT,
    title TEXT NOT NULL,
    composer TEXT,
    artist TEXT,
    time_signature JSONB NOT NULL DEFAULT '{"numerator": 4, "denominator": 4}'::jsonb,
    key_signature TEXT NOT NULL DEFAULT 'C',
    tempo INTEGER NOT NULL DEFAULT 120,
    sections JSONB NOT NULL DEFAULT '[]'::jsonb,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    deleted_at TIMESTAMPTZ,
    is_demo BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. Ensure all columns exist on tables (if tables were created previously without them)
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.team_members ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.team_members ADD COLUMN IF NOT EXISTS group_ids TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE public.team_members ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.team_members ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.team_groups ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.recurring_schedules ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.songs ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.setlists ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.scores ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;

-- 4. Triggers for automated updated_at timestamps
DROP TRIGGER IF EXISTS trg_teams_updated_at ON public.teams;
CREATE TRIGGER trg_teams_updated_at BEFORE UPDATE ON public.teams FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_team_members_updated_at ON public.team_members;
CREATE TRIGGER trg_team_members_updated_at BEFORE UPDATE ON public.team_members FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_team_groups_updated_at ON public.team_groups;
CREATE TRIGGER trg_team_groups_updated_at BEFORE UPDATE ON public.team_groups FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_recurring_schedules_updated_at ON public.recurring_schedules;
CREATE TRIGGER trg_recurring_schedules_updated_at BEFORE UPDATE ON public.recurring_schedules FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_calendar_events_updated_at ON public.calendar_events;
CREATE TRIGGER trg_calendar_events_updated_at BEFORE UPDATE ON public.calendar_events FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_songs_updated_at ON public.songs;
CREATE TRIGGER trg_songs_updated_at BEFORE UPDATE ON public.songs FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_setlists_updated_at ON public.setlists;
CREATE TRIGGER trg_setlists_updated_at BEFORE UPDATE ON public.setlists FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_scores_updated_at ON public.scores;
CREATE TRIGGER trg_scores_updated_at BEFORE UPDATE ON public.scores FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recurring_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.songs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.setlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scores ENABLE ROW LEVEL SECURITY;

-- 6. High-Performance Partial/Targeted Indexes
CREATE INDEX IF NOT EXISTS idx_teams_is_demo ON public.teams(is_demo);
CREATE INDEX IF NOT EXISTS idx_team_members_is_demo ON public.team_members(is_demo);
CREATE INDEX IF NOT EXISTS idx_team_groups_is_demo ON public.team_groups(is_demo);
CREATE INDEX IF NOT EXISTS idx_recurring_schedules_is_demo ON public.recurring_schedules(is_demo);
CREATE INDEX IF NOT EXISTS idx_calendar_events_is_demo ON public.calendar_events(is_demo);
CREATE INDEX IF NOT EXISTS idx_songs_is_demo ON public.songs(is_demo);
CREATE INDEX IF NOT EXISTS idx_setlists_is_demo ON public.setlists(is_demo);
CREATE INDEX IF NOT EXISTS idx_scores_is_demo ON public.scores(is_demo);

-- 7. Idempotent Row Level Security Policies for Demo Data Synchronization
-- (Allows anon and authenticated clients to read and write records where is_demo = true)

DROP POLICY IF EXISTS "Allow public read of demo teams" ON public.teams;
CREATE POLICY "Allow public read of demo teams"
    ON public.teams FOR SELECT
    TO anon, authenticated
    USING (is_demo = true);

DROP POLICY IF EXISTS "Allow public read and write of demo team members" ON public.team_members;
CREATE POLICY "Allow public read and write of demo team members"
    ON public.team_members FOR ALL
    TO anon, authenticated
    USING (is_demo = true)
    WITH CHECK (is_demo = true);

DROP POLICY IF EXISTS "Allow public read and write of demo team groups" ON public.team_groups;
CREATE POLICY "Allow public read and write of demo team groups"
    ON public.team_groups FOR ALL
    TO anon, authenticated
    USING (is_demo = true)
    WITH CHECK (is_demo = true);

DROP POLICY IF EXISTS "Allow public read and write of demo calendar events" ON public.calendar_events;
CREATE POLICY "Allow public read and write of demo calendar events"
    ON public.calendar_events FOR ALL
    TO anon, authenticated
    USING (is_demo = true)
    WITH CHECK (is_demo = true);

DROP POLICY IF EXISTS "Allow public read and write of demo recurring schedules" ON public.recurring_schedules;
CREATE POLICY "Allow public read and write of demo recurring schedules"
    ON public.recurring_schedules FOR ALL
    TO anon, authenticated
    USING (is_demo = true)
    WITH CHECK (is_demo = true);

DROP POLICY IF EXISTS "Allow public read and write of demo songs" ON public.songs;
CREATE POLICY "Allow public read and write of demo songs"
    ON public.songs FOR ALL
    TO anon, authenticated
    USING (is_demo = true)
    WITH CHECK (is_demo = true);

DROP POLICY IF EXISTS "Allow public read and write of demo setlists" ON public.setlists;
CREATE POLICY "Allow public read and write of demo setlists"
    ON public.setlists FOR ALL
    TO anon, authenticated
    USING (is_demo = true)
    WITH CHECK (is_demo = true);

DROP POLICY IF EXISTS "Allow public read and write of demo scores" ON public.scores;
CREATE POLICY "Allow public read and write of demo scores"
    ON public.scores FOR ALL
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

-- 9. Enable Realtime Replication on Demo Tables for live multi-device broadcasting (idempotent check)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'team_members'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.team_members;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'team_groups'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.team_groups;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'calendar_events'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.calendar_events;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'recurring_schedules'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.recurring_schedules;
    END IF;
END $$;

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
    ('00000000-0000-0000-0001-000000000016', '00000000-0000-0000-0000-000000000001', 'Laura', '{leadVocal,backingVocal}', 'available', false, '{group-beta}', 'Alto vocal harmonies & lead voice', 'laura@battuta.music', true),
    ('00000000-0000-0000-0001-000000000017', '00000000-0000-0000-0000-000000000001', 'Mile', '{leadVocal,backingVocal}', 'available', false, '{group-alpha}', 'Alto chorus & worship support', 'mile@battuta.music', true),
    ('00000000-0000-0000-0001-000000000018', '00000000-0000-0000-0000-000000000001', 'Mona', '{leadVocal,backingVocal}', 'available', true, '{group-gamma}', 'Vocal director, Lead voice & Administrator', 'mona@battuta.music', true),
    ('00000000-0000-0000-0001-000000000019', '00000000-0000-0000-0000-000000000001', 'Monica', '{backingVocal}', 'available', false, '{group-beta}', 'Soprano chorus harmonies', 'monica@battuta.music', true),
    ('00000000-0000-0000-0001-000000000020', '00000000-0000-0000-0000-000000000001', 'Nico', '{electricGuitar}', 'available', false, '{group-alpha,group-beta,group-gamma}', 'Electric guitar leads, solos, and atmospheric ambient delays', 'nico@battuta.music', true),
    ('00000000-0000-0000-0001-000000000021', '00000000-0000-0000-0000-000000000001', 'P. Henry', '{leadVocal,backingVocal}', 'available', false, '{group-alpha,group-beta,group-gamma}', 'Pastoral leadership, acoustic guitar & vocals', 'henry@battuta.music', true),
    ('00000000-0000-0000-0001-000000000022', '00000000-0000-0000-0000-000000000001', 'P. Ricardo', '{leadVocal,backingVocal,acousticGuitar,keys}', 'available', true, '{group-alpha,group-beta,group-gamma}', 'Pastoral leadership, acoustic guitar, piano & vocals', 'ricardo@battuta.music', true),
    ('00000000-0000-0000-0001-000000000023', '00000000-0000-0000-0000-000000000001', 'Samu García', '{keys}', 'available', false, '{group-alpha}', 'Classical and contemporary keyboard harmonies', 'samu.garcia@battuta.music', true),
    ('00000000-0000-0000-0001-000000000024', '00000000-0000-0000-0000-000000000001', 'Samu Saldaña', '{drums}', 'available', false, '{group-alpha}', 'Dynamic rhythm section & drum arrangements', 'samu.saldana@battuta.music', true),
    ('00000000-0000-0000-0001-000000000025', '00000000-0000-0000-0000-000000000001', 'Sandra', '{leadVocal,backingVocal}', 'available', false, '{group-alpha}', 'Alto lead vocalist & chorus', 'sandra@battuta.music', true),
    ('00000000-0000-0000-0001-000000000026', '00000000-0000-0000-0000-000000000001', 'Sara', '{leadVocal,backingVocal}', 'available', false, '{group-beta}', 'Soprano lead & vocal harmonies', 'sara@battuta.music', true),
    ('00000000-0000-0000-0001-000000000027', '00000000-0000-0000-0000-000000000001', 'Saris', '{backingVocal}', 'available', false, '{group-gamma}', 'Soprano vocal harmony and backing vocals', 'saris@battuta.music', true),
    ('00000000-0000-0000-0001-000000000028', '00000000-0000-0000-0000-000000000001', 'Vicky', '{backingVocal}', 'available', false, '{group-alpha}', 'Alto chorus & worship support', 'vicky@battuta.music', true),
    ('00000000-0000-0000-0001-000000000029', '00000000-0000-0000-0000-000000000001', 'Zulma', '{backingVocal}', 'available', false, '{group-beta}', 'Alto chorus vocals', 'zulma@battuta.music', true),
    ('00000000-0000-0000-0001-000000000030', '00000000-0000-0000-0000-000000000001', 'Margarita', '{sound}', 'available', false, '{group-alpha,group-beta,group-gamma}', 'Front of House Sound & Audio Engineering', 'margarita@battuta.music', true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    roles = EXCLUDED.roles,
    status = EXCLUDED.status,
    is_admin = EXCLUDED.is_admin,
    group_ids = EXCLUDED.group_ids,
    notes = EXCLUDED.notes,
    email = EXCLUDED.email,
    is_demo = true;
