-- Allow a new budget for the same category after the previous budget is consumed.
-- The Flutter app prevents overlapping active budgets for the same category.
alter table public.budgets
  drop constraint if exists budgets_user_id_category_key;