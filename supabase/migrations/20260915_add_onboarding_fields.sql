-- Sign-up redesign + first-login financial onboarding.
-- profiles: country (drives currency automatically), onboarding completion
-- flag, and the answers collected during the first-login setup wizard.
alter table public.profiles
  add column if not exists country text,
  add column if not exists onboarding_completed boolean not null default false,
  add column if not exists income_source text,
  add column if not exists income_frequency text,
  add column if not exists income_amount numeric(12, 2),
  add column if not exists budget_objectives text[];

-- goals: support a "regular savings amount" goal (a recurring target with
-- no fixed end amount) alongside the existing total-target goal shape.
alter table public.goals
  add column if not exists is_recurring boolean not null default false,
  add column if not exists recurring_amount numeric(12, 2),
  add column if not exists recurring_frequency text;

-- Sync country into profiles on signup too (metadata path), matching the
-- other fields already handled here. onboarding_completed is intentionally
-- left out of both the insert and the on-conflict update: it must only
-- ever be set true by the onboarding completion write.
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  insert into public.profiles (
    id,
    full_name,
    email,
    currency,
    country,
    employment_status,
    birth_date,
    monthly_income,
    monthly_budget_goal,
    avatar_url,
    updated_at
  )
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name'
    ),
    new.email,
    nullif(new.raw_user_meta_data->>'currency', ''),
    nullif(new.raw_user_meta_data->>'country', ''),
    nullif(new.raw_user_meta_data->>'employment_status', ''),
    nullif(new.raw_user_meta_data->>'birth_date', '')::date,
    nullif(new.raw_user_meta_data->>'monthly_income', '')::numeric,
    nullif(new.raw_user_meta_data->>'monthly_budget_goal', '')::numeric,
    coalesce(
      nullif(new.raw_user_meta_data->>'avatar_url', ''),
      nullif(new.raw_user_meta_data->>'picture', '')
    ),
    now()
  )
  on conflict (id) do update set
    full_name = coalesce(excluded.full_name, public.profiles.full_name),
    email = coalesce(excluded.email, public.profiles.email),
    currency = coalesce(excluded.currency, public.profiles.currency),
    country = coalesce(excluded.country, public.profiles.country),
    employment_status = coalesce(excluded.employment_status, public.profiles.employment_status),
    birth_date = coalesce(excluded.birth_date, public.profiles.birth_date),
    monthly_income = coalesce(excluded.monthly_income, public.profiles.monthly_income),
    monthly_budget_goal = coalesce(excluded.monthly_budget_goal, public.profiles.monthly_budget_goal),
    avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url),
    updated_at = now();

  return new;
end;
$function$;
