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

grant execute on function public.finish_learning_session(uuid, boolean)
to authenticated;
