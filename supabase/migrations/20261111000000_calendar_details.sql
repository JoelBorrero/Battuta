-- ==============================================================================
-- Calendar details: event type, linked setlist, materialized occurrences
-- ==============================================================================
-- The app shows recurring schedules as projected occurrences. An occurrence
-- becomes a real calendar_events row the first time an admin edits or assigns
-- it; (series_id, occurrence_date) makes sure that happens only once.
-- Write access is unchanged: admins of a non-archived organization.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Recurring schedules: time, place and kind of service
-- ------------------------------------------------------------------------------

alter table public.recurring_schedules
    add column time_of_day time not null default '09:00',
    add column location text,
    add column event_type text not null default 'sundayService',
    add constraint recurring_schedules_event_type_check
        check (event_type in ('sundayService', 'rehearsal', 'midweek', 'youthService', 'specialEvent')),
    -- Target of the composite foreign key of calendar_events.series_id.
    add constraint recurring_schedules_id_organization_key unique (id, organization_id);

-- ------------------------------------------------------------------------------
-- 2. Calendar events: kind, setlist and the schedule occurrence they came from
-- ------------------------------------------------------------------------------

alter table public.calendar_events
    add column event_type text not null default 'sundayService',
    add column setlist_id text,
    add column series_id text,
    add column occurrence_date date,
    add constraint calendar_events_event_type_check
        check (event_type in ('sundayService', 'rehearsal', 'midweek', 'youthService', 'specialEvent')),
    -- An event of a series always knows which occurrence it is. (The series can
    -- disappear later: series_id becomes null and the date stays.)
    add constraint calendar_events_occurrence_check
        check (series_id is null or occurrence_date is not null),
    -- An occurrence is materialized once.
    add constraint calendar_events_occurrence_key unique (series_id, occurrence_date),
    -- Only setlists of the same organization; deleting the setlist unlinks it.
    add constraint calendar_events_setlist_fkey
        foreign key (setlist_id, organization_id)
        references public.setlists (id, organization_id) on delete set null (setlist_id),
    -- Only schedules of the same organization; deleting the schedule keeps the
    -- events that were already materialized.
    add constraint calendar_events_series_fkey
        foreign key (series_id, organization_id)
        references public.recurring_schedules (id, organization_id) on delete set null (series_id);

create index calendar_events_series_idx on public.calendar_events (series_id);
create index calendar_events_setlist_idx on public.calendar_events (setlist_id);
