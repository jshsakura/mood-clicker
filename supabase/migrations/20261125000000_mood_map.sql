-- The shared mood map: one row per person, day and mood, holding a tap count and an H3 cell at
-- resolution 7. No coordinates, notes or calendar data ever reach this table.
--
-- The app never touches the table. It calls four functions:
--   put_mood_drop    writes the caller's row for a day and mood (upsert)
--   mood_map         reads sums per cell, leaving out cells with too few people
--   delete_my_data   removes the caller's rows and anonymous account
--   purge_mood_drops runs daily from pg_cron and drops rows past the keep period
-- Row level security is on with no policies, and the client roles have no grants on the table,
-- so a raw select or insert fails even if a function is wrong somewhere else.

-- Numbers a person decides (see the open decisions in docs/PLAN.md), one function each so they
-- change in one place.

-- A cell shows on the map only when this many people dropped a mood in it over the range.
create function public.map_min_people() returns integer
language sql immutable set search_path = '' as $$ select 5 $$;

-- Rows older than this many days are deleted every night.
create function public.map_keep_days() returns integer
language sql immutable set search_path = '' as $$ select 30 $$;

-- How often one person may rewrite one mood of one day. The app sends once after a tapping run.
create function public.map_max_writes() returns integer
language sql immutable set search_path = '' as $$ select 300 $$;

-- The most taps one mood can hold in a day. Far above what a hand can do.
create function public.map_max_taps() returns integer
language sql immutable set search_path = '' as $$ select 100000 $$;

-- Whether a number is a valid H3 cell index at resolution 7. The h3 extension is not on the
-- Supabase extension list, so this reads the bits of the index directly:
--   bit 63 is 0, bits 59-62 (mode) are 1 for a cell, bits 56-58 are reserved and 0,
--   bits 52-55 hold the resolution, bits 45-51 the base cell (0 to 121),
--   then fifteen 3-bit digits: the first 7 are 0 to 6, the unused 8 are all 7.
-- Pentagon cells have one more rule (no deleted subsequence) that this does not check.
create function public.is_map_cell(c bigint) returns boolean
language sql immutable strict set search_path = '' as $$
  select c >= 0
    and (c >> 59) & 15 = 1
    and (c >> 56) & 7 = 0
    and (c >> 52) & 15 = 7
    and (c >> 45) & 127 < 122
    and c & 16777215 = 16777215
    and (select bool_and((c >> (45 - 3 * i)) & 7 <= 6) from generate_series(1, 7) as i)
$$;

create table public.mood_drops (
  user_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  mood text not null check (mood in ('happy', 'excited', 'angry', 'sad', 'anxious')),
  cell bigint not null check (public.is_map_cell(cell)),
  taps integer not null check (taps between 0 and public.map_max_taps()),
  writes integer not null default 1,
  updated_at timestamptz not null default now(),
  primary key (user_id, day, mood)
);

create index mood_drops_day_cell on public.mood_drops (day, cell);

alter table public.mood_drops enable row level security;
revoke all on public.mood_drops from anon, authenticated;

-- Writes the caller's count for one mood of one day. Sending again replaces the count and the
-- cell (a person who moved shows in the new cell). The day must be within one day of the server
-- date, so a phone can not fill old or future days.
create function public.put_mood_drop(p_day date, p_cell bigint, p_mood text, p_taps integer)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  written integer;
begin
  if uid is null then
    raise exception 'sign in before sending a mood' using errcode = '42501';
  end if;
  if p_day is null or p_day not between current_date - 1 and current_date + 1 then
    raise exception 'day % is not today', p_day using errcode = '22023';
  end if;
  insert into public.mood_drops as d (user_id, day, mood, cell, taps)
  values (uid, p_day, p_mood, p_cell, p_taps)
  on conflict (user_id, day, mood) do update
    set cell = excluded.cell,
        taps = excluded.taps,
        writes = d.writes + 1,
        updated_at = now()
    where d.writes < public.map_max_writes();
  get diagnostics written = row_count;
  if written = 0 then
    raise exception 'too many writes for this mood today' using errcode = '54000';
  end if;
end
$$;

-- Tap sums per cell for the days from p_from to p_to (at most a week), for the cells asked.
-- A cell with fewer than map_min_people() people in the range is left out, so nobody's mood
-- can be told apart in a quiet neighbourhood.
create function public.mood_map(p_from date, p_to date, p_cells bigint[])
returns table (
  cell bigint,
  people integer,
  happy bigint,
  excited bigint,
  angry bigint,
  sad bigint,
  anxious bigint
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if p_from is null or p_to is null or p_to < p_from or p_to - p_from > 6 then
    raise exception 'the range must be one to seven days' using errcode = '22023';
  end if;
  if cardinality(p_cells) > 2000 then
    raise exception 'ask for at most 2000 cells' using errcode = '22023';
  end if;
  return query
  select d.cell,
         count(distinct d.user_id)::integer,
         coalesce(sum(d.taps) filter (where d.mood = 'happy'), 0)::bigint,
         coalesce(sum(d.taps) filter (where d.mood = 'excited'), 0)::bigint,
         coalesce(sum(d.taps) filter (where d.mood = 'angry'), 0)::bigint,
         coalesce(sum(d.taps) filter (where d.mood = 'sad'), 0)::bigint,
         coalesce(sum(d.taps) filter (where d.mood = 'anxious'), 0)::bigint
  from public.mood_drops d
  where d.day between p_from and p_to
    and d.cell = any (p_cells)
  group by d.cell
  having count(distinct d.user_id) >= public.map_min_people();
end
$$;

-- Removes the caller's rows and anonymous account. Settings calls it when map sharing is
-- turned off. The rows go with the account through the foreign key.
create function public.delete_my_data()
returns void
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'sign in before deleting' using errcode = '42501';
  end if;
  delete from public.mood_drops where user_id = uid;
  delete from auth.users where id = uid and is_anonymous;
end
$$;

-- Drops rows past the keep period, then anonymous accounts that are older than the keep period
-- and hold no rows. Returns how many rows went.
create function public.purge_mood_drops()
returns integer
language plpgsql security definer set search_path = '' as $$
declare
  dropped integer;
begin
  delete from public.mood_drops where day < current_date - public.map_keep_days();
  get diagnostics dropped = row_count;
  delete from auth.users u
  where u.is_anonymous
    and u.created_at < now() - make_interval(days => public.map_keep_days())
    and not exists (select 1 from public.mood_drops d where d.user_id = u.id);
  return dropped;
end
$$;

-- Functions are executable by everyone by default. Open only what the app calls.
revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function public.put_mood_drop(date, bigint, text, integer) to authenticated;
grant execute on function public.delete_my_data() to authenticated;
grant execute on function public.mood_map(date, date, bigint[]) to anon, authenticated;

create extension if not exists pg_cron with schema pg_catalog;
select cron.schedule('purge-mood-drops', '17 3 * * *', 'select public.purge_mood_drops()');
