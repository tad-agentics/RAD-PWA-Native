create table workflows (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  prompts jsonb not null default '{}',
  is_active boolean not null default true,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

alter table workflows enable row level security;

-- Workflows are read by service role (Edge Functions) only.
-- No user-facing RLS policies needed — Edge Functions use service role key.

-- Only one active workflow at a time (partial unique index).
-- PostgreSQL has no UNIQUE on a boolean value alone, so we use a partial
-- index that's unique only over the rows where is_active = true.
create unique index uq_workflows_single_active
  on workflows (is_active)
  where is_active = true;

-- Reuse update_updated_at() from the jobs migration.
create trigger workflows_updated_at
  before update on workflows
  for each row execute function update_updated_at();
