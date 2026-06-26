create or replace function public.learning_session_updates_streak()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.touch_student_streak(new.student_id, new.academy_id);
  return new;
end;
$$;

drop trigger if exists learning_session_streak on public.learning_sessions;
create trigger learning_session_streak
after insert on public.learning_sessions
for each row execute function public.learning_session_updates_streak();
