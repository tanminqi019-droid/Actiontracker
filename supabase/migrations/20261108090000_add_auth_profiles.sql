-- Sign-in with Supabase Auth: profiles linked to auth.users, admin-created accounts only,
-- and actions restricted to signed-in users.

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9._-]{2,30}$'),
  display_name text not null check (char_length(display_name) between 1 and 40),
  role text not null default 'member' check (role in ('admin','member')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Signed-in users can read the team list. No insert/update/delete policies:
-- profiles are only written by the trigger below, so nobody can change their own role.
create policy "Signed-in users can read profiles"
  on public.profiles for select to authenticated using (true);

-- Create a profile for every new auth user. Only accounts created server-side by an admin
-- (app_metadata.created_by_admin = true) are accepted; public self sign-ups are rejected.
-- Role is read from app_metadata, which users cannot edit.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce(new.raw_app_meta_data->>'created_by_admin', 'false') <> 'true' then
    raise exception 'Sign-ups are disabled. Ask an admin to create your account.';
  end if;

  insert into public.profiles (id, username, display_name, role)
  values (
    new.id,
    lower(coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1))),
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    case when new.raw_app_meta_data->>'role' = 'admin' then 'admin' else 'member' end
  );
  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Actions: signed-in users only
drop policy if exists "Public read actions"   on public.actions;
drop policy if exists "Public insert actions" on public.actions;
drop policy if exists "Public update actions" on public.actions;
drop policy if exists "Public delete actions" on public.actions;

alter table public.actions
  add column created_by uuid references auth.users(id) on delete set null default auth.uid();

create policy "Signed-in users can read actions"   on public.actions for select to authenticated using (true);
create policy "Signed-in users can add actions"    on public.actions for insert to authenticated with check (created_by = (select auth.uid()));
create policy "Signed-in users can update actions" on public.actions for update to authenticated using (true) with check (true);
create policy "Signed-in users can delete actions" on public.actions for delete to authenticated using (true);
