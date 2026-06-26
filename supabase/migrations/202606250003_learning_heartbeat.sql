create or replace function public.touch_learning_session(
  p_session_id uuid,
  p_elapsed_seconds integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.learning_sessions session
  set duration_seconds = greatest(
    session.duration_seconds,
    least(greatest(p_elapsed_seconds, 0), 14400)
  )
  where session.id = p_session_id
    and session.ended_at is null
    and session.student_id in (
      select id from public.students where auth_user_id = auth.uid()
    );
end;
$$;

grant execute on function public.touch_learning_session(uuid, integer)
to authenticated;
