create table if not exists public.budgets (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null,
  limit_amount numeric(12, 2) not null check (limit_amount > 0),
  budget_date date not null default current_date,
  created_at timestamptz not null default now()
);

alter table public.budgets
  add column if not exists budget_date date not null default current_date;

create index if not exists budgets_user_budget_date_idx
  on public.budgets (user_id, budget_date);

alter table public.budgets enable row level security;

drop policy if exists "Users can view own budgets" on public.budgets;
create policy "Users can view own budgets"
  on public.budgets for select
  using (auth.uid() = user_id);

drop policy if exists "Users can add own budgets" on public.budgets;
create policy "Users can add own budgets"
  on public.budgets for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own budgets" on public.budgets;
create policy "Users can update own budgets"
  on public.budgets for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own budgets" on public.budgets;
create policy "Users can delete own budgets"
  on public.budgets for delete
  using (auth.uid() = user_id);

create table if not exists public.goal_contributions (
  id uuid primary key default gen_random_uuid(),
  goal_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  amount numeric(12, 2) not null check (amount > 0),
  contributed_at date not null default current_date,
  created_at timestamptz not null default now()
);

create index if not exists goal_contributions_user_goal_date_idx
  on public.goal_contributions (user_id, goal_id, contributed_at, created_at);

alter table public.goal_contributions enable row level security;

drop policy if exists "Users can view own goal contributions"
  on public.goal_contributions;
create policy "Users can view own goal contributions"
  on public.goal_contributions for select
  using (auth.uid() = user_id);

drop policy if exists "Users can add own goal contributions"
  on public.goal_contributions;
create policy "Users can add own goal contributions"
  on public.goal_contributions for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own goal contributions"
  on public.goal_contributions;
create policy "Users can delete own goal contributions"
  on public.goal_contributions for delete
  using (auth.uid() = user_id);
