-- ============================================================================
-- Battuta: Workspace Resource Quotas & Usage Metering
--
-- Enables centralized workspace-level billing, quota governance, and real-time
-- tracking of Gemini AI tokens and Supabase Storage bytes without requiring
-- end-users to manage individual API keys.
-- ============================================================================

-- ── 1. Workspace Quotas Table ─────────────────────────────────────────────
create table if not exists public.workspace_quotas (
    workspace_id uuid primary key references public.bands(id) on delete cascade,
    monthly_gemini_credits_limit int not null default 5000,
    max_storage_bytes bigint not null default 1073741824, -- 1 GB in bytes
    tier text not null default 'pro',                     -- 'free', 'standard', 'pro'
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- ── 2. Aggregated Usage Ledger ────────────────────────────────────────────
create table if not exists public.workspace_usage (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references public.bands(id) on delete cascade,
    user_id uuid not null references public.user_profiles(id) on delete cascade,
    billing_period text not null, -- Format: 'YYYY-MM'
    
    -- Gemini AI Metering
    gemini_tokens_used bigint not null default 0,
    gemini_scans_count int not null default 0,
    gemini_credits_consumed int not null default 0,
    
    -- Supabase Storage Metering
    storage_used_bytes bigint not null default 0,
    files_uploaded_count int not null default 0,
    
    last_activity_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique(workspace_id, user_id, billing_period)
);

create index if not exists idx_workspace_usage_band on public.workspace_usage(workspace_id);
create index if not exists idx_workspace_usage_user on public.workspace_usage(user_id);
create index if not exists idx_workspace_usage_period on public.workspace_usage(billing_period);

-- ── 3. Row Level Security (RLS) ───────────────────────────────────────────
alter table public.workspace_quotas enable row level security;
alter table public.workspace_usage enable row level security;

-- Members can view their workspace quotas
create policy "Members can view their band quotas"
on public.workspace_quotas for select
to authenticated
using ( public.is_member_of_band(workspace_id) );

-- Members can view band usage
create policy "Members can view band usage"
on public.workspace_usage for select
to authenticated
using ( public.is_member_of_band(workspace_id) );

-- ── 4. Atomic Telemetry Ingestion RPC ──────────────────────────────────────
create or replace function public.record_gemini_scan_usage(
    p_workspace_id uuid,
    p_tokens int,
    p_credits int
)
returns void
language plpgsql
security invoker
as $$
declare
    v_period text := to_char(now(), 'YYYY-MM');
begin
    insert into public.workspace_usage (
        workspace_id,
        user_id,
        billing_period,
        gemini_tokens_used,
        gemini_scans_count,
        gemini_credits_consumed,
        last_activity_at,
        updated_at
    )
    values (
        p_workspace_id,
        auth.uid(),
        v_period,
        p_tokens,
        1,
        p_credits,
        now(),
        now()
    )
    on conflict (workspace_id, user_id, billing_period) do update set
        gemini_tokens_used = workspace_usage.gemini_tokens_used + excluded.gemini_tokens_used,
        gemini_scans_count = workspace_usage.gemini_scans_count + 1,
        gemini_credits_consumed = workspace_usage.gemini_credits_consumed + excluded.gemini_credits_consumed,
        last_activity_at = now(),
        updated_at = now();
end;
$$;
