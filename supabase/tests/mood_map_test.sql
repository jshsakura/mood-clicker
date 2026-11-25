-- Runs with `supabase test db` against a local database. Everything rolls back at the end.
begin;
create extension if not exists pgtap with schema extensions;

select plan(27);

-- A valid resolution 7 cell: mode 1, resolution 7, base cell 20, the first digit set to [n],
-- the other used digits 0 and the unused digits all 7. Made up, not anybody's place.
create function pg_temp.cell(n integer) returns bigint language sql immutable as $$
  select (1::bigint << 59) | (7::bigint << 52) | (20::bigint << 45) | (n::bigint << 42) | 16777215
$$;

-- Acts as the given account until the next reset role.
create function pg_temp.sign_in(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

-- Eight made-up anonymous accounts.
insert into auth.users (id, instance_id, aud, role, is_anonymous, created_at)
select ('00000000-0000-4000-8000-00000000000' || n)::uuid,
       '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', true, now()
from generate_series(1, 8) as n;

-- The cell check.
select ok(public.is_map_cell(pg_temp.cell(0)), 'a resolution 7 cell passes');
select ok(not public.is_map_cell(pg_temp.cell(7)), 'a used digit of 7 is refused');
select ok(not public.is_map_cell((pg_temp.cell(0) & ~(15::bigint << 52)) | (8::bigint << 52)),
          'another resolution is refused');
select ok(not public.is_map_cell((pg_temp.cell(0) & ~(15::bigint << 59)) | (2::bigint << 59)),
          'an edge index is refused');
select ok(not public.is_map_cell(pg_temp.cell(0) - 1), 'unused digits other than 7 are refused');
select ok(not public.is_map_cell(-1), 'a negative number is refused');
select ok(not public.is_map_cell((pg_temp.cell(0) & ~(127::bigint << 45)) | (122::bigint << 45)),
          'a base cell past 121 is refused');

-- No raw access for the client roles.
set local role anon;
select throws_ok('select * from public.mood_drops', '42501', null, 'anon can not read raw rows');
select throws_ok($$select public.put_mood_drop(current_date, 1, 'sad', 1)$$, '42501', null,
                 'anon can not send a mood');
reset role;

set local role authenticated;
select pg_temp.sign_in('00000000-0000-4000-8000-000000000001');
select throws_ok('select * from public.mood_drops', '42501', null, 'a signed in user can not read raw rows');
select throws_ok(
  format($$insert into public.mood_drops (user_id, day, mood, cell, taps)
           values ('00000000-0000-4000-8000-000000000002', current_date, 'sad', %s, 1)$$, pg_temp.cell(0)),
  '42501', null, 'a signed in user can not insert raw rows, not even someone else''s');
select throws_ok('select public.purge_mood_drops()', '42501', null, 'a user can not run the purge');

-- Sending.
select lives_ok(format($$select public.put_mood_drop(current_date, %s, 'sad', 12)$$, pg_temp.cell(0)),
                'a user sends a mood for today');
select lives_ok(format($$select public.put_mood_drop(current_date, %s, 'sad', 30)$$, pg_temp.cell(1)),
                'sending again replaces it');
select throws_ok(format($$select public.put_mood_drop(current_date, %s, 'bored', 1)$$, pg_temp.cell(0)),
                 '23514', null, 'an unknown mood is refused');
select throws_ok(format($$select public.put_mood_drop(current_date, %s, 'sad', -1)$$, pg_temp.cell(0)),
                 '23514', null, 'a negative count is refused');
select throws_ok(format($$select public.put_mood_drop(current_date, %s, 'sad', 100001)$$, pg_temp.cell(0)),
                 '23514', null, 'a count past the cap is refused');
select throws_ok(format($$select public.put_mood_drop(current_date - 2, %s, 'sad', 1)$$, pg_temp.cell(0)),
                 '22023', null, 'an old day is refused');
select throws_ok($$select public.put_mood_drop(current_date, 12345, 'sad', 1)$$,
                 '23514', null, 'a number that is no cell is refused');
reset role;

select results_eq(
  $$select cell, taps, writes from public.mood_drops where user_id = '00000000-0000-4000-8000-000000000001'$$,
  format('values (%s::bigint, 30, 2)', pg_temp.cell(1)),
  'the row holds the last send and counts the writes');

-- The write cap.
update public.mood_drops set writes = public.map_max_writes()
where user_id = '00000000-0000-4000-8000-000000000001';
set local role authenticated;
select pg_temp.sign_in('00000000-0000-4000-8000-000000000001');
select throws_ok(format($$select public.put_mood_drop(current_date, %s, 'sad', 31)$$, pg_temp.cell(1)),
                 '54000', null, 'a write past the daily cap is refused');
reset role;

-- The map: four people in cell 2 stay hidden, five in cell 3 show with their sums.
insert into public.mood_drops (user_id, day, mood, cell, taps)
select ('00000000-0000-4000-8000-00000000000' || n)::uuid, current_date, 'happy', pg_temp.cell(2), 10
from generate_series(1, 4) as n;
insert into public.mood_drops (user_id, day, mood, cell, taps)
select ('00000000-0000-4000-8000-00000000000' || n)::uuid, current_date,
       case when n % 2 = 0 then 'excited' else 'angry' end, pg_temp.cell(3), n
from generate_series(1, 5) as n;

set local role anon;
select results_eq(
  format('select cell, people, happy, excited, angry, sad, anxious from public.mood_map(current_date, current_date, array[%s, %s])',
         pg_temp.cell(2), pg_temp.cell(3)),
  format('values (%s::bigint, 5, 0::bigint, 6::bigint, 9::bigint, 0::bigint, 0::bigint)', pg_temp.cell(3)),
  'a cell with fewer than five people is left out, one with five shows its sums');
select throws_ok(
  format('select * from public.mood_map(current_date - 7, current_date, array[%s])', pg_temp.cell(3)),
  '22023', null, 'a range past a week is refused');
reset role;

-- Deleting my data.
set local role authenticated;
select pg_temp.sign_in('00000000-0000-4000-8000-000000000003');
select lives_ok('select public.delete_my_data()', 'a user deletes their data');
reset role;
select is((select count(*)::integer from public.mood_drops
           where user_id = '00000000-0000-4000-8000-000000000003'), 0, 'their rows are gone');
select is((select count(*)::integer from auth.users
           where id = '00000000-0000-4000-8000-000000000003'), 0, 'their anonymous account is gone');

-- The purge.
insert into public.mood_drops (user_id, day, mood, cell, taps)
values ('00000000-0000-4000-8000-000000000004', current_date - public.map_keep_days() - 1, 'sad', pg_temp.cell(0), 1);
select is(public.purge_mood_drops(), 1, 'the purge drops rows past the keep period and nothing else');

select * from finish();
rollback;
