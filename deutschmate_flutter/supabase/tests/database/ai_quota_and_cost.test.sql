create extension if not exists pgtap with schema extensions;

begin;
select plan(8);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values (
  '30000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated',
  'rls-ai-student@example.test', '', now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"display_name":"AI Student"}'::jsonb, now(), now()
);

insert into public.ai_conversations (id, user_id, locale, cefr_level)
values (
  '40000000-0000-4000-8000-000000000004',
  '30000000-0000-4000-8000-000000000003', 'ar', 'a1'
);

select is(
  public.reserve_ai_request(
    '30000000-0000-4000-8000-000000000003', 'quota-test-1', 'test-model',
    20, 1, 150, 10000, 100
  ),
  'reserved',
  'AI reservation is granted within daily and project budgets'
);

select is(
  public.reserve_ai_request(
    '30000000-0000-4000-8000-000000000003', 'quota-test-rate', 'test-model',
    20, 1, 150, 10000, 100
  ),
  'rate_limit',
  'per-minute limit blocks concurrent burst requests'
);

select is(
  public.reserve_ai_request(
    '30000000-0000-4000-8000-000000000003', 'quota-test-budget', 'test-model',
    20, 5, 150, 10000, 100
  ),
  'budget_exceeded',
  'reservation cannot exceed the user daily budget'
);

select is(
  public.settle_ai_request(
    'quota-test-1',
    '40000000-0000-4000-8000-000000000004',
    120, 80, 45, 'اشرح قاعدة أدوات التعريف', 'تم حفظ إجابة المساعد'
  ),
  true,
  'completed usage is settled and assistant reply stored atomically'
);

select is(
  (select actual_cost_microusd from public.ai_daily_usage
    where user_id = '30000000-0000-4000-8000-000000000003'
      and usage_date = (now() at time zone 'UTC')::date),
  45::bigint,
  'actual provider cost is recorded'
);

select is(
  (select reserved_cost_microusd from public.ai_daily_usage
    where user_id = '30000000-0000-4000-8000-000000000003'
      and usage_date = (now() at time zone 'UTC')::date),
  0::bigint,
  'settlement releases the reserved amount'
);

select is(
  public.reserve_ai_request(
    '30000000-0000-4000-8000-000000000003', 'quota-test-release', 'test-model',
    20, 5, 150, 10000, 100
  ),
  'reserved',
  'failed requests may reserve remaining budget'
);

select is(
  public.release_ai_request('quota-test-release', 'provider_error'),
  true,
  'failed provider request releases its reserved cost'
);

select * from finish();
rollback;
