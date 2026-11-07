-- ==============================================================================
-- Battuta — PostgreSQL Database Schema & Row Level Security (RLS) for Supabase
-- ==============================================================================
-- This schema establishes cloud synchronization and collaborative band/worship
-- team management for Battuta while preserving local SQLite (Drift) offline invariants.
--
-- Supports:
-- 1. Multi-tenant Teams and Team Member roster permissions
-- 2. Granular Mathematical Score Tree (scores -> sections -> measures -> notes/chords)
-- 3. Lossless Repertoire Songs, Setlists, and Band Calendar Services
-- 4. Cascade deletions and Row Level Security (RLS) policies
-- ==============================================================================

-- Enable UUID extension if not already available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. Teams & Membership
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

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
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ------------------------------------------------------------------------------
-- 2. Mathematical Score Tree
-- ------------------------------------------------------------------------------
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    score_id UUID NOT NULL REFERENCES public.scores(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    format TEXT NOT NULL DEFAULT 'leadSheet',
    indications TEXT,
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.measures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    section_id UUID NOT NULL REFERENCES public.sections(id) ON DELETE CASCADE,
    measure_number INTEGER NOT NULL,
    time_signature TEXT NOT NULL DEFAULT '4/4',
    warning TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.note_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    measure_id UUID NOT NULL REFERENCES public.measures(id) ON DELETE CASCADE,
    pitch TEXT NOT NULL,
    duration_ticks INTEGER NOT NULL,
    lyric TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.chord_symbols (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    measure_id UUID NOT NULL REFERENCES public.measures(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    beat_offset_ticks INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ------------------------------------------------------------------------------
-- 3. Repertoire, Setlists & Band Calendar
-- ------------------------------------------------------------------------------
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.setlists (
    id TEXT PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    event_date TIMESTAMPTZ,
    items_json TEXT NOT NULL DEFAULT '[]',
    tags_json TEXT NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.calendar_events (
    id TEXT PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    date_time TIMESTAMPTZ NOT NULL,
    location TEXT,
    notes TEXT,
    assignments_json TEXT NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ------------------------------------------------------------------------------
-- 4. Automated Updated-At Trigger
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_teams_updated_at
    BEFORE UPDATE ON public.teams
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER trg_team_members_updated_at
    BEFORE UPDATE ON public.team_members
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER trg_scores_updated_at
    BEFORE UPDATE ON public.scores
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER trg_sections_updated_at
    BEFORE UPDATE ON public.sections
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER trg_measures_updated_at
    BEFORE UPDATE ON public.measures
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER trg_note_events_updated_at
    BEFORE UPDATE ON public.note_events
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER trg_chord_symbols_updated_at
    BEFORE UPDATE ON public.chord_symbols
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER trg_songs_updated_at
    BEFORE UPDATE ON public.songs
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER trg_setlists_updated_at
    BEFORE UPDATE ON public.setlists
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER trg_calendar_events_updated_at
    BEFORE UPDATE ON public.calendar_events
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- 5. Row Level Security (RLS) Helper Functions
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_team_member(check_team_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF check_team_id IS NULL THEN
        RETURN FALSE;
    END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.team_members
        WHERE team_id = check_team_id
          AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_team_admin(check_team_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF check_team_id IS NULL THEN
        RETURN FALSE;
    END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.team_members
        WHERE team_id = check_team_id
          AND user_id = auth.uid()
          AND is_admin = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------------------------
-- 6. Enable RLS and Create Policies
-- ------------------------------------------------------------------------------
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.measures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.note_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chord_symbols ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.songs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.setlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

-- Teams: accessible by member users
CREATE POLICY "Users can view teams they belong to"
    ON public.teams FOR SELECT
    TO authenticated
    USING (public.is_team_member(id));

CREATE POLICY "Authenticated users can create teams"
    ON public.teams FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Team admins can update their team"
    ON public.teams FOR UPDATE
    TO authenticated
    USING (public.is_team_admin(id))
    WITH CHECK (public.is_team_admin(id));

-- Team Members: visible to teammates
CREATE POLICY "Teammates can view team roster"
    ON public.team_members FOR SELECT
    TO authenticated
    USING (public.is_team_member(team_id) OR user_id = auth.uid());

CREATE POLICY "Team admins or self can manage team members"
    ON public.team_members FOR ALL
    TO authenticated
    USING (public.is_team_admin(team_id) OR user_id = auth.uid())
    WITH CHECK (public.is_team_admin(team_id) OR user_id = auth.uid());

-- Scores: owner or team member access
CREATE POLICY "Users can access their scores or team scores"
    ON public.scores FOR SELECT
    TO authenticated
    USING (owner_id = auth.uid() OR public.is_team_member(team_id));

CREATE POLICY "Users can create scores for themselves or team"
    ON public.scores FOR INSERT
    TO authenticated
    WITH CHECK (owner_id = auth.uid() OR public.is_team_member(team_id));

CREATE POLICY "Users can modify their scores or team scores"
    ON public.scores FOR UPDATE
    TO authenticated
    USING (owner_id = auth.uid() OR public.is_team_member(team_id))
    WITH CHECK (owner_id = auth.uid() OR public.is_team_member(team_id));

CREATE POLICY "Users can delete their scores or team admins can delete"
    ON public.scores FOR DELETE
    TO authenticated
    USING (owner_id = auth.uid() OR public.is_team_admin(team_id));

-- Sections, Measures, Note Events, Chord Symbols (Cascade inheritance from parent Score)
CREATE POLICY "Sections select via score"
    ON public.sections FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM public.scores s WHERE s.id = score_id AND (s.owner_id = auth.uid() OR public.is_team_member(s.team_id))));

CREATE POLICY "Sections write via score"
    ON public.sections FOR ALL TO authenticated
    USING (EXISTS (SELECT 1 FROM public.scores s WHERE s.id = score_id AND (s.owner_id = auth.uid() OR public.is_team_member(s.team_id))))
    WITH CHECK (EXISTS (SELECT 1 FROM public.scores s WHERE s.id = score_id AND (s.owner_id = auth.uid() OR public.is_team_member(s.team_id))));

CREATE POLICY "Measures select via score"
    ON public.measures FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.sections sc
        JOIN public.scores s ON s.id = sc.score_id
        WHERE sc.id = section_id AND (s.owner_id = auth.uid() OR public.is_team_member(s.team_id))
    ));

CREATE POLICY "Measures write via score"
    ON public.measures FOR ALL TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.sections sc
        JOIN public.scores s ON s.id = sc.score_id
        WHERE sc.id = section_id AND (s.owner_id = auth.uid() OR public.is_team_member(s.team_id))
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.sections sc
        JOIN public.scores s ON s.id = sc.score_id
        WHERE sc.id = section_id AND (s.owner_id = auth.uid() OR public.is_team_member(s.team_id))
    ));

CREATE POLICY "Note events access via score"
    ON public.note_events FOR ALL TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.measures m
        JOIN public.sections sc ON sc.id = m.section_id
        JOIN public.scores s ON s.id = sc.score_id
        WHERE m.id = measure_id AND (s.owner_id = auth.uid() OR public.is_team_member(s.team_id))
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.measures m
        JOIN public.sections sc ON sc.id = m.section_id
        JOIN public.scores s ON s.id = sc.score_id
        WHERE m.id = measure_id AND (s.owner_id = auth.uid() OR public.is_team_member(s.team_id))
    ));

CREATE POLICY "Chord symbols access via score"
    ON public.chord_symbols FOR ALL TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.measures m
        JOIN public.sections sc ON sc.id = m.section_id
        JOIN public.scores s ON s.id = sc.score_id
        WHERE m.id = measure_id AND (s.owner_id = auth.uid() OR public.is_team_member(s.team_id))
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.measures m
        JOIN public.sections sc ON sc.id = m.section_id
        JOIN public.scores s ON s.id = sc.score_id
        WHERE m.id = measure_id AND (s.owner_id = auth.uid() OR public.is_team_member(s.team_id))
    ));

-- Songs, Setlists, Calendar Events policies
CREATE POLICY "Songs select and write"
    ON public.songs FOR ALL TO authenticated
    USING (owner_id = auth.uid() OR public.is_team_member(team_id))
    WITH CHECK (owner_id = auth.uid() OR public.is_team_member(team_id));

CREATE POLICY "Setlists select and write"
    ON public.setlists FOR ALL TO authenticated
    USING (owner_id = auth.uid() OR public.is_team_member(team_id))
    WITH CHECK (owner_id = auth.uid() OR public.is_team_member(team_id));

CREATE POLICY "Calendar events select and write"
    ON public.calendar_events FOR ALL TO authenticated
    USING (owner_id = auth.uid() OR public.is_team_member(team_id))
    WITH CHECK (owner_id = auth.uid() OR public.is_team_member(team_id));
