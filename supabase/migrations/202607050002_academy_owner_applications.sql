create table if not exists public.academy_owner_applications (
  id uuid primary key default gen_random_uuid(),
  academy_name text not null,
  academy_code text not null,
  owner_name text not null,
  owner_email text not null,
  owner_phone text,
  expected_students integer not null default 100 check (expected_students between 1 and 5000),
  request_note text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_academy_id uuid references public.academies(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists academy_owner_applications_status_idx
  on public.academy_owner_applications (status, created_at desc);

create unique index if not exists academy_owner_applications_pending_email_idx
  on public.academy_owner_applications (lower(owner_email))
  where status = 'pending';

create unique index if not exists academy_owner_applications_pending_code_idx
  on public.academy_owner_applications (upper(academy_code))
  where status = 'pending';

drop trigger if exists academy_owner_applications_set_updated_at
on public.academy_owner_applications;
create trigger academy_owner_applications_set_updated_at
before update on public.academy_owner_applications
for each row execute function public.set_updated_at();

alter table public.academy_owner_applications enable row level security;

drop policy if exists "super admins read owner applications"
on public.academy_owner_applications;
create policy "super admins read owner applications"
on public.academy_owner_applications for select
to authenticated
using (public.is_super_admin());

drop policy if exists "super admins update owner applications"
on public.academy_owner_applications;
create policy "super admins update owner applications"
on public.academy_owner_applications for update
to authenticated
using (public.is_super_admin())
with check (public.is_super_admin());

grant select, update on public.academy_owner_applications to authenticated;

create or replace function public.submit_academy_owner_application(
  p_academy_name text,
  p_academy_code text,
  p_owner_name text,
  p_owner_email text,
  p_owner_phone text default null,
  p_expected_students integer default 100,
  p_request_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_application_id uuid;
  clean_code text := upper(regexp_replace(trim(coalesce(p_academy_code, '')), '[^A-Za-z0-9_-]', '', 'g'));
  clean_email text := lower(trim(coalesce(p_owner_email, '')));
begin
  if length(trim(coalesce(p_academy_name, ''))) < 2
     or length(trim(coalesce(p_academy_name, ''))) > 80 then
    raise exception 'Academy name must be 2-80 characters';
  end if;

  if clean_code !~ '^[A-Z0-9][A-Z0-9_-]{2,23}$' then
    raise exception 'Academy code must be 3-24 letters, numbers, - or _';
  end if;

  if length(trim(coalesce(p_owner_name, ''))) < 2
     or length(trim(coalesce(p_owner_name, ''))) > 60 then
    raise exception 'Owner name must be 2-60 characters';
  end if;

  if clean_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
    raise exception 'Enter a valid owner email';
  end if;

  if coalesce(p_expected_students, 100) < 1 or coalesce(p_expected_students, 100) > 5000 then
    raise exception 'Expected students must be between 1 and 5000';
  end if;

  if exists (select 1 from public.academies where upper(code) = clean_code) then
    raise exception 'This academy code is already in use';
  end if;

  if exists (
    select 1
    from public.academy_owner_applications
    where status = 'pending'
      and lower(owner_email) = clean_email
  ) then
    raise exception 'This email already has a pending application';
  end if;

  if exists (
    select 1
    from public.academy_owner_applications
    where status = 'pending'
      and upper(academy_code) = clean_code
  ) then
    raise exception 'This academy code already has a pending application';
  end if;

  insert into public.academy_owner_applications (
    academy_name,
    academy_code,
    owner_name,
    owner_email,
    owner_phone,
    expected_students,
    request_note
  )
  values (
    trim(p_academy_name),
    clean_code,
    trim(p_owner_name),
    clean_email,
    nullif(trim(coalesce(p_owner_phone, '')), ''),
    coalesce(p_expected_students, 100),
    nullif(trim(coalesce(p_request_note, '')), '')
  )
  returning id into new_application_id;

  return new_application_id;
end;
$$;

create or replace function public.get_super_admin_owner_applications()
returns table (
  id uuid,
  academy_name text,
  academy_code text,
  owner_name text,
  owner_email text,
  owner_phone text,
  expected_students integer,
  request_note text,
  status text,
  created_at timestamptz,
  reviewed_at timestamptz,
  created_academy_id uuid
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
    app.id,
    app.academy_name,
    app.academy_code,
    app.owner_name,
    app.owner_email,
    app.owner_phone,
    app.expected_students,
    app.request_note,
    app.status,
    app.created_at,
    app.reviewed_at,
    app.created_academy_id
  from public.academy_owner_applications app
  order by
    case app.status when 'pending' then 0 when 'approved' then 1 else 2 end,
    app.created_at desc;
end;
$$;

create or replace function public.reject_academy_owner_application(
  p_application_id uuid
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

  update public.academy_owner_applications
  set status = 'rejected',
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where id = p_application_id
    and status = 'pending';

  if not found then
    raise exception 'Pending application not found';
  end if;
end;
$$;

grant execute on function public.submit_academy_owner_application(
  text, text, text, text, text, integer, text
) to anon, authenticated;

grant execute on function public.get_super_admin_owner_applications()
to authenticated;

grant execute on function public.reject_academy_owner_application(uuid)
to authenticated;
