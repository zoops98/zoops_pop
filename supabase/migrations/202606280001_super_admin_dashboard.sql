alter table public.academies
add column if not exists owner_email text;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'super_admin'
  );
$$;

create or replace function public.get_super_admin_academy_dashboard()
returns table (
  academy_id uuid,
  academy_name text,
  academy_code text,
  owner_id uuid,
  owner_email text,
  owner_display_name text,
  status text,
  student_limit integer,
  student_count bigint,
  active_student_count bigint,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_super_admin() then
    raise exception 'Super admin access required';
  end if;

  return query
  select
    a.id as academy_id,
    a.name as academy_name,
    a.code as academy_code,
    a.owner_id,
    a.owner_email,
    p.display_name as owner_display_name,
    a.status,
    a.student_limit,
    count(s.id) as student_count,
    count(s.id) filter (where s.status = 'active') as active_student_count,
    a.created_at,
    a.updated_at
  from public.academies a
  left join public.profiles p
    on p.id = a.owner_id
  left join public.students s
    on s.academy_id = a.id
   and s.status <> 'archived'
  group by a.id, p.display_name
  order by a.created_at desc;
end;
$$;

create or replace function public.update_super_admin_academy(
  p_academy_id uuid,
  p_status text,
  p_student_limit integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_super_admin() then
    raise exception 'Super admin access required';
  end if;

  if p_status not in ('trial', 'active', 'suspended', 'expired') then
    raise exception 'Invalid academy status';
  end if;

  if p_student_limit is null or p_student_limit < 1 or p_student_limit > 5000 then
    raise exception 'Student limit must be between 1 and 5000';
  end if;

  update public.academies
  set status = p_status,
      student_limit = p_student_limit
  where id = p_academy_id;

  if not found then
    raise exception 'Academy not found';
  end if;
end;
$$;

grant execute on function public.is_super_admin()
to authenticated;

grant execute on function public.get_super_admin_academy_dashboard()
to authenticated;

grant execute on function public.update_super_admin_academy(uuid, text, integer)
to authenticated;
