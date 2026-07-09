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
begin
  raise exception 'Academy owner accounts must be created by the super admin.';
end;
$$;

revoke all on function public.create_my_academy(text, text, text)
from public, anon, authenticated;
