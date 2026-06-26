create extension if not exists pgcrypto;

create table if not exists public.academies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text not null unique,
  owner_id uuid not null references auth.users(id) on delete restrict,
  status text not null default 'active'
    check (status in ('trial', 'active', 'suspended', 'expired')),
  student_limit integer not null default 100 check (student_limit > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  academy_id uuid references public.academies(id) on delete cascade,
  role text not null default 'academy_owner'
    check (role in ('super_admin', 'academy_owner', 'teacher', 'student')),
  display_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies(id) on delete cascade,
  auth_user_id uuid unique references auth.users(id) on delete set null,
  english_name text not null,
  student_login_id text not null,
  status text not null default 'active'
    check (status in ('active', 'paused', 'archived')),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (academy_id, student_login_id)
);

create table if not exists public.learning_sessions (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  section_key text not null,
  unit_key text not null,
  unit_name text not null,
  mode text not null check (mode in ('study', 'spelling')),
  last_word text,
  study_board_completed boolean not null default false,
  first_attempt_accuracy numeric(5,2),
  final_accuracy numeric(5,2),
  correct_count integer not null default 0,
  total_count integer not null default 0,
  audio_replays integer not null default 0,
  duration_seconds integer not null default 0,
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

create table if not exists public.word_attempts (
  id bigint generated always as identity primary key,
  academy_id uuid not null references public.academies(id) on delete cascade,
  session_id uuid not null references public.learning_sessions(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  word text not null,
  attempt_number integer not null default 1,
  is_correct boolean not null,
  audio_replays integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.unit_progress (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  section_key text not null,
  unit_key text not null,
  unit_name text not null,
  last_word text,
  study_board_completed boolean not null default false,
  spelling_attempts integer not null default 0,
  first_attempt_accuracy numeric(5,2),
  final_accuracy numeric(5,2),
  wrong_count integer not null default 0,
  audio_replays integer not null default 0,
  total_study_seconds integer not null default 0,
  qualifying_sessions integer not null default 0,
  mastery_status text not null default 'not_started'
    check (mastery_status in ('not_started', 'learning', 'review', 'mastered')),
  last_studied_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (student_id, section_key, unit_key)
);

create table if not exists public.feedback_reports (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  period_start date not null,
  period_end date not null,
  metric_snapshot jsonb not null default '{}'::jsonb,
  ai_draft jsonb,
  edited_feedback text,
  status text not null default 'draft'
    check (status in ('draft', 'approved', 'delivered')),
  created_by uuid not null references auth.users(id) on delete restrict,
  approved_by uuid references auth.users(id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists students_academy_idx
  on public.students (academy_id);
create index if not exists learning_sessions_student_idx
  on public.learning_sessions (student_id, started_at desc);
create index if not exists word_attempts_student_word_idx
  on public.word_attempts (student_id, word);
create index if not exists unit_progress_student_idx
  on public.unit_progress (student_id, last_studied_at desc);
create index if not exists feedback_reports_student_idx
  on public.feedback_reports (student_id, period_end desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists academies_set_updated_at on public.academies;
create trigger academies_set_updated_at
before update on public.academies
for each row execute function public.set_updated_at();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists students_set_updated_at on public.students;
create trigger students_set_updated_at
before update on public.students
for each row execute function public.set_updated_at();

drop trigger if exists unit_progress_set_updated_at on public.unit_progress;
create trigger unit_progress_set_updated_at
before update on public.unit_progress
for each row execute function public.set_updated_at();

drop trigger if exists feedback_reports_set_updated_at on public.feedback_reports;
create trigger feedback_reports_set_updated_at
before update on public.feedback_reports
for each row execute function public.set_updated_at();

create or replace function public.current_academy_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select academy_id
  from public.profiles
  where id = auth.uid();
$$;

create or replace function public.current_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role
  from public.profiles
  where id = auth.uid();
$$;

create or replace function public.create_my_academy(
  academy_name text,
  academy_code text,
  owner_display_name text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_academy_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if exists (select 1 from public.profiles where id = auth.uid()) then
    raise exception 'This account is already configured';
  end if;

  insert into public.academies (name, code, owner_id)
  values (
    trim(academy_name),
    upper(trim(academy_code)),
    auth.uid()
  )
  returning id into new_academy_id;

  insert into public.profiles (id, academy_id, role, display_name)
  values (
    auth.uid(),
    new_academy_id,
    'academy_owner',
    trim(owner_display_name)
  );

  return new_academy_id;
end;
$$;

grant execute on function public.create_my_academy(text, text, text)
to authenticated;

grant usage on schema public to authenticated, service_role;

grant select, insert, update, delete
on all tables in schema public
to authenticated;

grant all privileges
on all tables in schema public
to service_role;

grant usage, select
on all sequences in schema public
to authenticated;

grant all privileges
on all sequences in schema public
to service_role;

alter table public.academies enable row level security;
alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table public.learning_sessions enable row level security;
alter table public.word_attempts enable row level security;
alter table public.unit_progress enable row level security;
alter table public.feedback_reports enable row level security;

drop policy if exists "owners read own academy" on public.academies;
create policy "owners read own academy"
on public.academies for select
to authenticated
using (owner_id = auth.uid());

drop policy if exists "owners update own academy" on public.academies;
create policy "owners update own academy"
on public.academies for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists "members read academy profiles" on public.profiles;
create policy "members read academy profiles"
on public.profiles for select
to authenticated
using (id = auth.uid() or academy_id = public.current_academy_id());

drop policy if exists "members update own profile" on public.profiles;
create policy "members update own profile"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid() and academy_id = public.current_academy_id());

drop policy if exists "owners manage students" on public.students;
create policy "owners manage students"
on public.students for all
to authenticated
using (
  academy_id = public.current_academy_id()
  and public.current_role() in ('academy_owner', 'teacher')
)
with check (
  academy_id = public.current_academy_id()
  and public.current_role() in ('academy_owner', 'teacher')
);

drop policy if exists "students read own student record" on public.students;
create policy "students read own student record"
on public.students for select
to authenticated
using (auth_user_id = auth.uid());

drop policy if exists "academy members read sessions" on public.learning_sessions;
create policy "academy members read sessions"
on public.learning_sessions for select
to authenticated
using (
  academy_id = public.current_academy_id()
  or student_id in (
    select id from public.students where auth_user_id = auth.uid()
  )
);

drop policy if exists "students create own sessions" on public.learning_sessions;
create policy "students create own sessions"
on public.learning_sessions for insert
to authenticated
with check (
  student_id in (
    select id from public.students where auth_user_id = auth.uid()
  )
  and academy_id = public.current_academy_id()
);

drop policy if exists "students update own sessions" on public.learning_sessions;
create policy "students update own sessions"
on public.learning_sessions for update
to authenticated
using (
  student_id in (
    select id from public.students where auth_user_id = auth.uid()
  )
)
with check (
  student_id in (
    select id from public.students where auth_user_id = auth.uid()
  )
);

drop policy if exists "academy members read word attempts" on public.word_attempts;
create policy "academy members read word attempts"
on public.word_attempts for select
to authenticated
using (
  academy_id = public.current_academy_id()
  or student_id in (
    select id from public.students where auth_user_id = auth.uid()
  )
);

drop policy if exists "students create word attempts" on public.word_attempts;
create policy "students create word attempts"
on public.word_attempts for insert
to authenticated
with check (
  student_id in (
    select id from public.students where auth_user_id = auth.uid()
  )
  and academy_id = public.current_academy_id()
);

drop policy if exists "academy members read unit progress" on public.unit_progress;
create policy "academy members read unit progress"
on public.unit_progress for select
to authenticated
using (
  academy_id = public.current_academy_id()
  or student_id in (
    select id from public.students where auth_user_id = auth.uid()
  )
);

drop policy if exists "students insert own unit progress" on public.unit_progress;
create policy "students insert own unit progress"
on public.unit_progress for insert
to authenticated
with check (
  student_id in (
    select id from public.students where auth_user_id = auth.uid()
  )
  and academy_id = public.current_academy_id()
);

drop policy if exists "students update own unit progress" on public.unit_progress;
create policy "students update own unit progress"
on public.unit_progress for update
to authenticated
using (
  student_id in (
    select id from public.students where auth_user_id = auth.uid()
  )
)
with check (
  student_id in (
    select id from public.students where auth_user_id = auth.uid()
  )
);

drop policy if exists "owners manage feedback" on public.feedback_reports;
create policy "owners manage feedback"
on public.feedback_reports for all
to authenticated
using (
  academy_id = public.current_academy_id()
  and public.current_role() in ('academy_owner', 'teacher')
)
with check (
  academy_id = public.current_academy_id()
  and public.current_role() in ('academy_owner', 'teacher')
);
