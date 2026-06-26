create or replace function public.start_learning_session(
  p_section_key text,
  p_unit_key text,
  p_unit_name text,
  p_mode text,
  p_total_count integer
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  learner public.students%rowtype;
  new_session_id uuid;
begin
  if p_mode not in ('study', 'spelling') then
    raise exception 'Invalid learning mode';
  end if;

  select *
  into learner
  from public.students
  where auth_user_id = auth.uid()
    and status = 'active';

  if learner.id is null then
    raise exception 'Active student account required';
  end if;

  insert into public.learning_sessions (
    academy_id, student_id, section_key, unit_key, unit_name, mode, total_count
  )
  values (
    learner.academy_id, learner.id, trim(p_section_key), trim(p_unit_key),
    trim(p_unit_name), p_mode, greatest(p_total_count, 0)
  )
  returning id into new_session_id;

  insert into public.unit_progress (
    academy_id, student_id, section_key, unit_key, unit_name,
    spelling_attempts, mastery_status, last_studied_at
  )
  values (
    learner.academy_id, learner.id, trim(p_section_key), trim(p_unit_key),
    trim(p_unit_name), case when p_mode = 'spelling' then 1 else 0 end,
    'learning', now()
  )
  on conflict (student_id, section_key, unit_key)
  do update set
    unit_name = excluded.unit_name,
    spelling_attempts = public.unit_progress.spelling_attempts
      + case when p_mode = 'spelling' then 1 else 0 end,
    mastery_status = case
      when public.unit_progress.mastery_status = 'not_started' then 'learning'
      else public.unit_progress.mastery_status
    end,
    last_studied_at = now();

  return new_session_id;
end;
$$;

create or replace function public.record_word_attempt(
  p_session_id uuid,
  p_word text,
  p_is_correct boolean,
  p_attempt_number integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  learner public.students%rowtype;
  target_session public.learning_sessions%rowtype;
begin
  select * into learner
  from public.students
  where auth_user_id = auth.uid() and status = 'active';

  select * into target_session
  from public.learning_sessions
  where id = p_session_id and student_id = learner.id and ended_at is null;

  if target_session.id is null then
    raise exception 'Active learning session not found';
  end if;

  insert into public.word_attempts (
    academy_id, session_id, student_id, word, attempt_number, is_correct
  )
  values (
    learner.academy_id, target_session.id, learner.id, lower(trim(p_word)),
    greatest(p_attempt_number, 1), p_is_correct
  );

  update public.learning_sessions
  set
    last_word = lower(trim(p_word)),
    correct_count = (
      select count(*) from (
        select distinct on (word) word, is_correct
        from public.word_attempts
        where session_id = p_session_id
        order by word, attempt_number desc, id desc
      ) latest
      where is_correct
    )
  where id = p_session_id;
end;
$$;

create or replace function public.record_audio_replay(
  p_session_id uuid,
  p_word text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.learning_sessions session
  set
    audio_replays = session.audio_replays + 1,
    last_word = lower(trim(p_word))
  where session.id = p_session_id
    and session.ended_at is null
    and session.student_id in (
      select id from public.students where auth_user_id = auth.uid()
    );
end;
$$;

create or replace function public.finish_learning_session(
  p_session_id uuid,
  p_study_board_completed boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  learner public.students%rowtype;
  target_session public.learning_sessions%rowtype;
  first_accuracy numeric(5,2);
  final_accuracy numeric(5,2);
  wrong_total integer := 0;
  elapsed_seconds integer;
  existing_qualifying integer := 0;
  qualifying_increment integer := 0;
  next_mastery text := 'learning';
begin
  select * into learner
  from public.students
  where auth_user_id = auth.uid() and status = 'active';

  select * into target_session
  from public.learning_sessions
  where id = p_session_id and student_id = learner.id
  for update;

  if target_session.id is null or target_session.ended_at is not null then
    return;
  end if;

  elapsed_seconds := greatest(target_session.duration_seconds, 0);

  if target_session.mode = 'spelling' then
    select round(
      100.0 * count(*) filter (where first_try.is_correct)
      / nullif(target_session.total_count, 0), 2
    )
    into first_accuracy
    from (
      select distinct on (word) word, is_correct
      from public.word_attempts
      where session_id = p_session_id
      order by word, attempt_number asc, id asc
    ) first_try;

    select round(
      100.0 * count(*) filter (where latest.is_correct)
      / nullif(target_session.total_count, 0), 2
    )
    into final_accuracy
    from (
      select distinct on (word) word, is_correct
      from public.word_attempts
      where session_id = p_session_id
      order by word, attempt_number desc, id desc
    ) latest;

    select count(*) into wrong_total
    from public.word_attempts
    where session_id = p_session_id and not is_correct;
  end if;

  select qualifying_sessions
  into existing_qualifying
  from public.unit_progress
  where student_id = learner.id
    and section_key = target_session.section_key
    and unit_key = target_session.unit_key;

  existing_qualifying := coalesce(existing_qualifying, 0);
  qualifying_increment := case
    when target_session.mode = 'spelling' and final_accuracy >= 90 then 1
    else 0
  end;

  next_mastery := case
    when existing_qualifying + qualifying_increment >= 2 then 'mastered'
    when target_session.mode = 'spelling' and final_accuracy < 70 then 'review'
    else 'learning'
  end;

  update public.learning_sessions
  set
    study_board_completed = p_study_board_completed,
    first_attempt_accuracy = first_accuracy,
    final_accuracy = final_accuracy,
    duration_seconds = elapsed_seconds,
    ended_at = now()
  where id = p_session_id;

  update public.unit_progress
  set
    last_word = target_session.last_word,
    study_board_completed = study_board_completed or p_study_board_completed,
    first_attempt_accuracy = coalesce(first_accuracy, first_attempt_accuracy),
    final_accuracy = coalesce(final_accuracy, final_accuracy),
    wrong_count = wrong_count + wrong_total,
    audio_replays = audio_replays + target_session.audio_replays,
    total_study_seconds = total_study_seconds + elapsed_seconds,
    qualifying_sessions = qualifying_sessions + qualifying_increment,
    mastery_status = case
      when mastery_status = 'mastered' then 'mastered'
      else next_mastery
    end,
    last_studied_at = now()
  where student_id = learner.id
    and section_key = target_session.section_key
    and unit_key = target_session.unit_key;
end;
$$;

grant execute on function public.start_learning_session(text, text, text, text, integer)
to authenticated;
grant execute on function public.record_word_attempt(uuid, text, boolean, integer)
to authenticated;
grant execute on function public.record_audio_replay(uuid, text)
to authenticated;
grant execute on function public.finish_learning_session(uuid, boolean)
to authenticated;
