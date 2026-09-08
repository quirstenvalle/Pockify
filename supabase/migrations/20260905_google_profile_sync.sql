-- Keep Google / OAuth signups synced into public.profiles, including avatar.
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
    employment_status = coalesce(excluded.employment_status, public.profiles.employment_status),
    birth_date = coalesce(excluded.birth_date, public.profiles.birth_date),
    monthly_income = coalesce(excluded.monthly_income, public.profiles.monthly_income),
    monthly_budget_goal = coalesce(excluded.monthly_budget_goal, public.profiles.monthly_budget_goal),
    avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url),
    updated_at = now();

  return new;
end;
$function$;
