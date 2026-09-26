alter table public.transactions
  add column if not exists budget_id text references public.budgets(id) on delete set null;

create index if not exists transactions_user_budget_id_idx
  on public.transactions (user_id, budget_id);

