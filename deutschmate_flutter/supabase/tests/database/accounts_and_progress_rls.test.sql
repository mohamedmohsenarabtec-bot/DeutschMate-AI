create extension if not exists pgtap with schema extensions;

begin;
select plan(8);

select has_table('public', 'student_progress', 'the account progress table exists');
select has_column('public', 'profiles', 'role', 'profiles carry a server-managed role');

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  ('10000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated',
   'rls-student-a@example.test', '', now(),
   '{"provider":"email","providers":["email"]}'::jsonb,
   '{"display_name":"Student A"}'::jsonb, now(), now()),
  ('20000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated',
   'rls-student-b@example.test', '', now(),
   '{"provider":"email","providers":["email"]}'::jsonb,
   '{"display_name":"Student B"}'::jsonb, now(), now());

insert into public.student_progress (user_id, state)
values
  ('10000000-0000-4000-8000-000000000001', '{"private_note":"belongs to A"}'),
  ('20000000-0000-4000-8000-000000000002', '{"private_note":"belongs to B"}');

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated","app_metadata":{}}',
  true
);

select is(
  (select count(*)::integer from public.student_progress),
  1,
  'student A can read only one progress row'
);
select results_eq(
  $$update public.student_progress
    set state = '{"private_note":"tampered"}'
    where user_id = '20000000-0000-4000-8000-000000000002'
    returning user_id$$,
  $$select null::uuid where false$$,
  'student A cannot update student B progress'
);
select throws_ok(
  $$update public.profiles set role = 'admin'
    where id = '10000000-0000-4000-8000-000000000001'$$,
  '42501',
  null,
  'a student cannot grant themselves an admin role'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-4000-8000-000000000002","role":"authenticated","app_metadata":{}}',
  true
);
select is(
  (select count(*)::integer from public.student_progress
    where user_id = '10000000-0000-4000-8000-000000000001'),
  0,
  'student B cannot read student A progress'
);
select is(
  (select count(*)::integer from public.profiles
    where id = '10000000-0000-4000-8000-000000000001'),
  0,
  'student B cannot read student A profile'
);
select is(
  (select count(*)::integer from public.student_progress
    where user_id = '20000000-0000-4000-8000-000000000002'),
  1,
  'student B can read their own progress'
);

select * from finish();
rollback;
