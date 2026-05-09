create table jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'completed', 'failed')),
  tier text not null default 'free'
    check (tier in ('free', 'paid')),
  fingerprint_hash text unique,
  input jsonb not null default '{}',
  output jsonb,
  error text,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

alter table jobs enable row level security;

create policy "users_select_own_jobs" on jobs
  for select using (auth.uid() = user_id);

create policy "users_insert_own_jobs" on jobs
  for insert with check (auth.uid() = user_id);

create index ix_jobs_user_id on jobs(user_id);
create index ix_jobs_status on jobs(status);
create index ix_jobs_created_at on jobs(created_at);

-- Auto-update updated_at on row change
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger jobs_updated_at
  before update on jobs
  for each row execute function update_updated_at();
