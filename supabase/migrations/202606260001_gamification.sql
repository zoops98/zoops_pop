create table if not exists public.student_game_profiles (
  student_id uuid primary key references public.students(id) on delete cascade,
  academy_id uuid not null references public.academies(id) on delete cascade,
  xp integer not null default 0 check (xp >= 0),
  streak_days integer not null default 0 check (streak_days >= 0),
  last_active_date date,
  updated_at timestamptz not null default now()
);

create table if not exists public.student_reward_events (
  id bigint generated always as identity primary key,
  academy_id uuid not null references public.academies(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  event_key text not null,
  event_type text not null check (
    event_type in ('listen_word', 'spelling_word', 'listen_unit', 'section_mastery')
  ),
  points integer not null check (points between 0 and 100),
  created_at timestamptz not null default now(),
  unique (student_id, event_key)
);

create table if not exists public.listen_select_attempts (
  id bigint generated always as identity primary key,
  academy_id uuid not null references public.academies(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  section_key text not null,
  unit_key text not null,
  unit_name text not null,
  word text not null,
  attempt_count integer not null default 1 check (attempt_count > 0),
  is_correct boolean not null,
  created_at timestamptz not null default now()
);

create table if not exists public.student_badges (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  badge_key text not null,
  badge_name text not null,
  badge_kind text not null check (badge_kind in ('unit', 'section')),
  section_key text not null,
  unit_key text,
  earned_at timestamptz not null default now(),
  unique (student_id, badge_key)
);

create index if not exists reward_events_student_idx
  on public.student_reward_events (student_id, created_at desc);
create index if not exists listen_attempts_student_idx
  on public.listen_select_attempts (student_id, created_at desc);
create index if not exists student_badges_student_idx
  on public.student_badges (student_id, earned_at desc);

alter table public.student_game_profiles enable row level security;
alter table public.student_reward_events enable row level security;
alter table public.listen_select_attempts enable row level security;
alter table public.student_badges enable row level security;

grant select, insert, update, delete
on public.student_game_profiles, public.student_reward_events,
   public.listen_select_attempts, public.student_badges
to authenticated;

grant usage, select on all sequences in schema public to authenticated;

create policy "students read own game profile"
on public.student_game_profiles for select
to authenticated
using (student_id in (
  select id from public.students where auth_user_id = auth.uid()
));

create policy "academy staff read game profiles"
on public.student_game_profiles for select
to authenticated
using (
  academy_id = public.current_academy_id()
  and public.current_role() in ('academy_owner', 'teacher')
);

create policy "students read own rewards"
on public.student_reward_events for select
to authenticated
using (student_id in (
  select id from public.students where auth_user_id = auth.uid()
));

create policy "academy staff read rewards"
on public.student_reward_events for select
to authenticated
using (
  academy_id = public.current_academy_id()
  and public.current_role() in ('academy_owner', 'teacher')
);

create policy "students read own listen attempts"
on public.listen_select_attempts for select
to authenticated
using (student_id in (
  select id from public.students where auth_user_id = auth.uid()
));

create policy "academy staff read listen attempts"
on public.listen_select_attempts for select
to authenticated
using (
  academy_id = public.current_academy_id()
  and public.current_role() in ('academy_owner', 'teacher')
);

create policy "students read own badges"
on public.student_badges for select
to authenticated
using (student_id in (
  select id from public.students where auth_user_id = auth.uid()
));

create policy "academy staff read badges"
on public.student_badges for select
to authenticated
using (
  academy_id = public.current_academy_id()
  and public.current_role() in ('academy_owner', 'teacher')
);

create or replace function public.touch_student_streak(
  p_student_id uuid,
  p_academy_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.student_game_profiles (
    student_id, academy_id, xp, streak_days, last_active_date
  )
  values (p_student_id, p_academy_id, 0, 1, current_date)
  on conflict (student_id)
  do update set
    streak_days = case
      when public.student_game_profiles.last_active_date = current_date
        then public.student_game_profiles.streak_days
      when public.student_game_profiles.last_active_date = current_date - 1
        then public.student_game_profiles.streak_days + 1
      else 1
    end,
    last_active_date = current_date,
    updated_at = now();
end;
$$;

create or replace function public.record_listen_select_result(
  p_section_key text,
  p_unit_key text,
  p_unit_name text,
  p_word text,
  p_attempt_count integer,
  p_is_correct boolean,
  p_unit_complete boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  learner public.students%rowtype;
  awarded_points integer := 0;
  event_inserted integer := 0;
  unit_badge_inserted integer := 0;
  section_badge_inserted integer := 0;
  unit_badge_key text;
  section_badge_key text;
  section_unit_badges integer;
  profile public.student_game_profiles%rowtype;
begin
  select * into learner
  from public.students
  where auth_user_id = auth.uid() and status = 'active';
  if learner.id is null then
    raise exception 'Active student account required';
  end if;

  insert into public.listen_select_attempts (
    academy_id, student_id, section_key, unit_key, unit_name,
    word, attempt_count, is_correct
  )
  values (
    learner.academy_id, learner.id, trim(p_section_key), trim(p_unit_key),
    trim(p_unit_name), lower(trim(p_word)), greatest(p_attempt_count, 1),
    p_is_correct
  );

  perform public.touch_student_streak(learner.id, learner.academy_id);

  if p_is_correct then
    insert into public.student_reward_events (
      academy_id, student_id, event_key, event_type, points
    )
    values (
      learner.academy_id, learner.id,
      'listen:' || trim(p_unit_key) || ':' || lower(trim(p_word)),
      'listen_word', 5
    )
    on conflict (student_id, event_key) do nothing;
    get diagnostics event_inserted = row_count;
    if event_inserted > 0 then awarded_points := awarded_points + 5; end if;
  end if;

  if p_is_correct and p_unit_complete then
    unit_badge_key := 'unit:' || trim(p_unit_key);
    insert into public.student_badges (
      academy_id, student_id, badge_key, badge_name, badge_kind,
      section_key, unit_key
    )
    values (
      learner.academy_id, learner.id, unit_badge_key,
      trim(p_unit_name) || ' Sound Monster', 'unit',
      trim(p_section_key), trim(p_unit_key)
    )
    on conflict (student_id, badge_key) do nothing;
    get diagnostics unit_badge_inserted = row_count;

    if unit_badge_inserted > 0 then
      insert into public.student_reward_events (
        academy_id, student_id, event_key, event_type, points
      )
      values (
        learner.academy_id, learner.id, unit_badge_key, 'listen_unit', 40
      )
      on conflict (student_id, event_key) do nothing;
      awarded_points := awarded_points + 40;
    end if;

    select count(*) into section_unit_badges
    from public.student_badges
    where student_id = learner.id
      and section_key = trim(p_section_key)
      and badge_kind = 'unit';

    if section_unit_badges >= 6 then
      section_badge_key := 'section:' || trim(p_section_key);
      insert into public.student_badges (
        academy_id, student_id, badge_key, badge_name, badge_kind,
        section_key
      )
      values (
        learner.academy_id, learner.id, section_badge_key,
        trim(p_section_key) || ' Phonics Hero', 'section', trim(p_section_key)
      )
      on conflict (student_id, badge_key) do nothing;
      get diagnostics section_badge_inserted = row_count;

      if section_badge_inserted > 0 then
        insert into public.student_reward_events (
          academy_id, student_id, event_key, event_type, points
        )
        values (
          learner.academy_id, learner.id,
          section_badge_key, 'section_mastery', 100
        )
        on conflict (student_id, event_key) do nothing;
        awarded_points := awarded_points + 100;
      end if;
    end if;
  end if;

  if awarded_points > 0 then
    update public.student_game_profiles
    set xp = xp + awarded_points, updated_at = now()
    where student_id = learner.id;
  end if;

  select * into profile
  from public.student_game_profiles
  where student_id = learner.id;

  return jsonb_build_object(
    'xp', profile.xp,
    'streak_days', profile.streak_days,
    'awarded_points', awarded_points,
    'unit_badge_earned', unit_badge_inserted > 0,
    'section_badge_earned', section_badge_inserted > 0
  );
end;
$$;

create or replace function public.award_spelling_success(
  p_section_key text,
  p_unit_key text,
  p_word text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  learner public.students%rowtype;
  inserted integer := 0;
  profile public.student_game_profiles%rowtype;
begin
  select * into learner
  from public.students
  where auth_user_id = auth.uid() and status = 'active';
  if learner.id is null then
    raise exception 'Active student account required';
  end if;

  perform public.touch_student_streak(learner.id, learner.academy_id);

  insert into public.student_reward_events (
    academy_id, student_id, event_key, event_type, points
  )
  values (
    learner.academy_id, learner.id,
    'spell:' || trim(p_unit_key) || ':' || lower(trim(p_word)),
    'spelling_word', 5
  )
  on conflict (student_id, event_key) do nothing;
  get diagnostics inserted = row_count;

  if inserted > 0 then
    update public.student_game_profiles
    set xp = xp + 5, updated_at = now()
    where student_id = learner.id;
  end if;

  select * into profile
  from public.student_game_profiles
  where student_id = learner.id;

  return jsonb_build_object(
    'xp', profile.xp,
    'streak_days', profile.streak_days,
    'awarded_points', case when inserted > 0 then 5 else 0 end
  );
end;
$$;

create or replace function public.get_student_game_state()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  learner public.students%rowtype;
  profile public.student_game_profiles%rowtype;
  today_seconds integer := 0;
  today_listen integer := 0;
  today_spelling integer := 0;
  badges jsonb;
begin
  select * into learner
  from public.students
  where auth_user_id = auth.uid() and status = 'active';
  if learner.id is null then
    raise exception 'Active student account required';
  end if;

  insert into public.student_game_profiles (student_id, academy_id)
  values (learner.id, learner.academy_id)
  on conflict (student_id) do nothing;

  select * into profile
  from public.student_game_profiles
  where student_id = learner.id;

  select coalesce(sum(duration_seconds), 0)::integer into today_seconds
  from public.learning_sessions
  where student_id = learner.id
    and started_at >= current_date
    and started_at < current_date + 1;

  select count(distinct word)::integer into today_listen
  from public.listen_select_attempts
  where student_id = learner.id
    and is_correct
    and created_at >= current_date
    and created_at < current_date + 1;

  select count(distinct word)::integer into today_spelling
  from public.word_attempts
  where student_id = learner.id
    and is_correct
    and created_at >= current_date
    and created_at < current_date + 1;

  select coalesce(jsonb_agg(jsonb_build_object(
    'badge_key', badge_key,
    'badge_name', badge_name,
    'badge_kind', badge_kind,
    'section_key', section_key,
    'unit_key', unit_key,
    'earned_at', earned_at
  ) order by earned_at desc), '[]'::jsonb)
  into badges
  from public.student_badges
  where student_id = learner.id;

  return jsonb_build_object(
    'xp', profile.xp,
    'level', floor(profile.xp / 100.0)::integer + 1,
    'level_xp', profile.xp % 100,
    'streak_days', profile.streak_days,
    'today_seconds', today_seconds,
    'today_listen_correct', today_listen,
    'today_spelling_correct', today_spelling,
    'badges', badges
  );
end;
$$;

grant execute on function public.record_listen_select_result(
  text, text, text, text, integer, boolean, boolean
) to authenticated;
grant execute on function public.award_spelling_success(text, text, text)
to authenticated;
grant execute on function public.get_student_game_state()
to authenticated;
