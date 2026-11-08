-- Meeting Action Tracker: actions table, row-level security and realtime

create table public.actions (
  id uuid primary key default gen_random_uuid(),
  text text not null check (char_length(text) between 1 and 200),
  owner text not null check (char_length(owner) between 1 and 40),
  due date not null,
  done boolean not null default false,
  created_at timestamptz not null default now()
);

create index actions_owner_idx on public.actions (lower(owner));
create index actions_due_idx on public.actions (due);

alter table public.actions enable row level security;

-- Demo app with no sign-in: anyone with the publishable key can read and edit actions.
-- Replace these with authenticated-only policies before using real data.
create policy "Public read actions"   on public.actions for select to anon, authenticated using (true);
create policy "Public insert actions" on public.actions for insert to anon, authenticated with check (true);
create policy "Public update actions" on public.actions for update to anon, authenticated using (true) with check (true);
create policy "Public delete actions" on public.actions for delete to anon, authenticated using (true);

-- Live updates for teammates
alter publication supabase_realtime add table public.actions;
