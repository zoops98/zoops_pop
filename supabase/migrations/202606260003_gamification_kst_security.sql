create or replace function public.touch_student_streak(
  p_student_id uuid,
  p_academy_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  korea_today date := (now() at time zone 'Asia/Seoul')::date;
begin
  insert into public.student_game_profiles (
    student_id, academy_id, xp, streak_days, last_active_date
  )
  values (p_student_id, p_academy_id, 0, 1, korea_today)
  on conflict (student_id)
  do update set
    streak_days = case
      when public.student_game_profiles.last_active_date = korea_today
        then public.student_game_profiles.streak_days
      when public.student_game_profiles.last_active_date = korea_today - 1
        then public.student_game_profiles.streak_days + 1
      else 1
    end,
    last_active_date = korea_today,
    updated_at = now();
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
  korea_today date := (now() at time zone 'Asia/Seoul')::date;
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
    and (started_at at time zone 'Asia/Seoul')::date = korea_today;

  select count(distinct word)::integer into today_listen
  from public.listen_select_attempts
  where student_id = learner.id
    and is_correct
    and (created_at at time zone 'Asia/Seoul')::date = korea_today;

  select count(distinct word)::integer into today_spelling
  from public.word_attempts
  where student_id = learner.id
    and is_correct
    and (created_at at time zone 'Asia/Seoul')::date = korea_today;

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

revoke all on function public.touch_student_streak(uuid, uuid)
from public, anon, authenticated;

revoke all on function public.learning_session_updates_streak()
from public, anon, authenticated;
