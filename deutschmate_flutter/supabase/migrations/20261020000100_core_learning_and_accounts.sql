-- Initial DeutschMate schema. User-visible reads/writes are protected by RLS.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '' check (char_length(display_name) <= 50),
  preferred_locale text not null default 'ar'
    check (preferred_locale in ('ar', 'de', 'en')),
  role text not null default 'student'
    check (role in ('student', 'teacher', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.course_levels (
  id text primary key check (id in ('a1', 'a2', 'b1', 'b2', 'c1', 'c2')),
  title jsonb not null,
  summary jsonb not null,
  sort_order smallint not null unique check (sort_order between 1 and 6),
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.course_units (
  id text primary key,
  level_id text not null references public.course_levels (id) on delete restrict,
  title jsonb not null,
  learning_outcomes jsonb not null default '[]'::jsonb,
  sort_order smallint not null check (sort_order > 0),
  content_status text not null default 'sample'
    check (content_status in ('sample', 'reviewed', 'licensed')),
  is_published boolean not null default false,
  unique (level_id, sort_order)
);

create table public.lessons (
  id text primary key,
  unit_id text not null references public.course_units (id) on delete restrict,
  title jsonb not null,
  content jsonb not null,
  content_status text not null default 'sample'
    check (content_status in ('sample', 'reviewed', 'licensed')),
  sort_order smallint not null check (sort_order > 0),
  is_published boolean not null default false,
  unique (unit_id, sort_order)
);

create table public.student_progress (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  state jsonb not null default '{}'::jsonb
    check (pg_column_size(state) <= 65536),
  updated_at timestamptz not null default now()
);

create table public.teacher_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles (id) on delete cascade,
  qualifications jsonb not null default '[]'::jsonb,
  specialties text[] not null default '{}',
  cefr_levels text[] not null default '{}'
    check (cefr_levels <@ array['a1', 'a2', 'b1', 'b2', 'c1', 'c2']::text[]),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'needs_changes')),
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles (id) on delete set null,
  review_note text
);

create table public.notification_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  event_type text not null check (char_length(event_type) between 1 and 80),
  payload jsonb not null default '{}'::jsonb
    check (pg_column_size(payload) <= 16384),
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create table public.ai_usage_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  provider text not null,
  model text not null,
  request_id text not null unique,
  input_tokens integer not null default 0 check (input_tokens >= 0),
  output_tokens integer not null default 0 check (output_tokens >= 0),
  cost_microusd bigint not null default 0 check (cost_microusd >= 0),
  reserved_cost_microusd bigint not null default 0 check (reserved_cost_microusd >= 0),
  status text not null default 'reserved'
    check (status in ('reserved', 'completed', 'failed')),
  failure_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  locale text not null check (locale in ('ar', 'de', 'en')),
  cefr_level text not null check (cefr_level in ('a1', 'a2', 'b1', 'b2', 'c1', 'c2')),
  summary text not null default '' check (char_length(summary) <= 4000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id)
);

create table public.ai_messages (
  id bigint generated always as identity primary key,
  conversation_id uuid not null,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null check (char_length(content) between 1 and 8000),
  request_id text,
  created_at timestamptz not null default now(),
  foreign key (conversation_id, user_id)
    references public.ai_conversations (id, user_id) on delete cascade
);

create index ai_messages_conversation_created_idx
  on public.ai_messages (user_id, conversation_id, created_at desc);

create table public.ai_daily_usage (
  user_id uuid not null references public.profiles (id) on delete cascade,
  usage_date date not null,
  request_count integer not null default 0 check (request_count >= 0),
  reserved_cost_microusd bigint not null default 0 check (reserved_cost_microusd >= 0),
  actual_cost_microusd bigint not null default 0 check (actual_cost_microusd >= 0),
  input_tokens bigint not null default 0 check (input_tokens >= 0),
  output_tokens bigint not null default 0 check (output_tokens >= 0),
  primary key (user_id, usage_date)
);

create table public.ai_project_daily_usage (
  usage_date date primary key,
  request_count bigint not null default 0 check (request_count >= 0),
  reserved_cost_microusd bigint not null default 0 check (reserved_cost_microusd >= 0),
  actual_cost_microusd bigint not null default 0 check (actual_cost_microusd >= 0)
);

create table public.audit_events (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles (id) on delete set null,
  action text not null,
  target_type text not null,
  target_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index notification_events_user_unread_idx
  on public.notification_events (user_id, created_at desc)
  where read_at is null;
create index ai_usage_events_user_created_idx
  on public.ai_usage_events (user_id, created_at desc);

create function public.reserve_ai_request(
  p_user_id uuid,
  p_request_id text,
  p_model text,
  p_daily_limit integer,
  p_per_minute_limit integer,
  p_user_daily_budget_microusd bigint,
  p_project_daily_budget_microusd bigint,
  p_reserve_cost_microusd bigint
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'UTC')::date;
  v_user public.ai_daily_usage%rowtype;
  v_project public.ai_project_daily_usage%rowtype;
  v_recent_requests integer;
begin
  if p_user_id is null or p_request_id is null or char_length(p_request_id) > 96
    or p_daily_limit < 1 or p_per_minute_limit < 1
    or p_user_daily_budget_microusd < 1
    or p_project_daily_budget_microusd < 1
    or p_reserve_cost_microusd < 1 then
    return 'budget_exceeded';
  end if;

  insert into public.ai_project_daily_usage (usage_date)
  values (v_today) on conflict (usage_date) do nothing;
  insert into public.ai_daily_usage (user_id, usage_date)
  values (p_user_id, v_today) on conflict (user_id, usage_date) do nothing;

  -- Every reservation locks project budget first, then the user bucket.
  select * into v_project from public.ai_project_daily_usage
    where usage_date = v_today for update;
  select * into v_user from public.ai_daily_usage
    where user_id = p_user_id and usage_date = v_today for update;

  select count(*)::integer into v_recent_requests
  from public.ai_usage_events
  where user_id = p_user_id
    and created_at >= now() - interval '1 minute';
  if v_recent_requests >= p_per_minute_limit then return 'rate_limit'; end if;
  if v_user.request_count >= p_daily_limit then return 'daily_limit'; end if;
  if v_user.actual_cost_microusd + v_user.reserved_cost_microusd
      + p_reserve_cost_microusd > p_user_daily_budget_microusd
    or v_project.actual_cost_microusd + v_project.reserved_cost_microusd
      + p_reserve_cost_microusd > p_project_daily_budget_microusd then
    return 'budget_exceeded';
  end if;

  update public.ai_daily_usage set
    request_count = request_count + 1,
    reserved_cost_microusd = reserved_cost_microusd + p_reserve_cost_microusd
  where user_id = p_user_id and usage_date = v_today;
  update public.ai_project_daily_usage set
    request_count = request_count + 1,
    reserved_cost_microusd = reserved_cost_microusd + p_reserve_cost_microusd
  where usage_date = v_today;
  insert into public.ai_usage_events (
    user_id, provider, model, request_id, reserved_cost_microusd, status
  ) values (p_user_id, 'openai', p_model, p_request_id, p_reserve_cost_microusd, 'reserved');
  return 'reserved';
exception when unique_violation then
  return 'duplicate_request';
end;
$$;

create function public.settle_ai_request(
  p_request_id text,
  p_conversation_id uuid,
  p_input_tokens integer,
  p_output_tokens integer,
  p_cost_microusd bigint,
  p_user_message text,
  p_reply text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.ai_usage_events%rowtype;
  v_day date;
begin
  select * into v_event from public.ai_usage_events
    where request_id = p_request_id for update;
  if not found or v_event.status <> 'reserved'
    or p_input_tokens < 0 or p_output_tokens < 0 or p_cost_microusd < 0
    or p_user_message is null or char_length(p_user_message) not between 1 and 4000
    or p_reply is null or char_length(p_reply) not between 1 and 8000 then
    return false;
  end if;
  v_day := (v_event.created_at at time zone 'UTC')::date;

  update public.ai_usage_events set
    input_tokens = p_input_tokens,
    output_tokens = p_output_tokens,
    cost_microusd = p_cost_microusd,
    reserved_cost_microusd = 0,
    status = 'completed',
    updated_at = now()
  where id = v_event.id;
  update public.ai_project_daily_usage set
    reserved_cost_microusd = greatest(0, reserved_cost_microusd - v_event.reserved_cost_microusd),
    actual_cost_microusd = actual_cost_microusd + p_cost_microusd
  where usage_date = v_day;
  update public.ai_daily_usage set
    reserved_cost_microusd = greatest(0, reserved_cost_microusd - v_event.reserved_cost_microusd),
    actual_cost_microusd = actual_cost_microusd + p_cost_microusd,
    input_tokens = input_tokens + p_input_tokens,
    output_tokens = output_tokens + p_output_tokens
  where user_id = v_event.user_id and usage_date = v_day;
  insert into public.ai_messages (conversation_id, user_id, role, content, request_id)
  values
    (p_conversation_id, v_event.user_id, 'user', p_user_message, p_request_id),
    (p_conversation_id, v_event.user_id, 'assistant', p_reply, p_request_id);
  update public.ai_conversations set updated_at = now()
  where id = p_conversation_id and user_id = v_event.user_id;
  return true;
end;
$$;

create function public.release_ai_request(p_request_id text, p_failure_code text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.ai_usage_events%rowtype;
  v_day date;
begin
  select * into v_event from public.ai_usage_events
    where request_id = p_request_id for update;
  if not found or v_event.status <> 'reserved' then return false; end if;
  v_day := (v_event.created_at at time zone 'UTC')::date;
  update public.ai_usage_events set
    reserved_cost_microusd = 0,
    status = 'failed',
    failure_code = left(coalesce(p_failure_code, 'unknown'), 80),
    updated_at = now()
  where id = v_event.id;
  update public.ai_project_daily_usage set
    reserved_cost_microusd = greatest(0, reserved_cost_microusd - v_event.reserved_cost_microusd)
  where usage_date = v_day;
  update public.ai_daily_usage set
    reserved_cost_microusd = greatest(0, reserved_cost_microusd - v_event.reserved_cost_microusd)
  where user_id = v_event.user_id and usage_date = v_day;
  return true;
end;
$$;

revoke execute on function public.reserve_ai_request(uuid, text, text, integer, integer, bigint, bigint, bigint)
  from public, anon, authenticated;
revoke execute on function public.settle_ai_request(text, uuid, integer, integer, bigint, text, text)
  from public, anon, authenticated;
revoke execute on function public.release_ai_request(text, text)
  from public, anon, authenticated;
grant execute on function public.reserve_ai_request(uuid, text, text, integer, integer, bigint, bigint, bigint)
  to service_role;
grant execute on function public.settle_ai_request(text, uuid, integer, integer, bigint, text, text)
  to service_role;
grant execute on function public.release_ai_request(text, text)
  to service_role;

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger student_progress_set_updated_at
before update on public.student_progress
for each row execute function public.set_updated_at();

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, preferred_locale, role)
  values (
    new.id,
    left(coalesce(new.raw_user_meta_data ->> 'display_name', ''), 50),
    case when new.raw_user_meta_data ->> 'preferred_locale' in ('ar', 'de', 'en')
      then new.raw_user_meta_data ->> 'preferred_locale'
      else 'ar'
    end,
    'student'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

insert into public.profiles (id, display_name, preferred_locale, role)
select
  users.id,
  left(coalesce(users.raw_user_meta_data ->> 'display_name', ''), 50),
  case when users.raw_user_meta_data ->> 'preferred_locale' in ('ar', 'de', 'en')
    then users.raw_user_meta_data ->> 'preferred_locale'
    else 'ar'
  end,
  'student'
from auth.users users
on conflict (id) do nothing;

revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.set_updated_at() from public, anon, authenticated;

alter table public.profiles enable row level security;
alter table public.course_levels enable row level security;
alter table public.course_units enable row level security;
alter table public.lessons enable row level security;
alter table public.student_progress enable row level security;
alter table public.teacher_applications enable row level security;
alter table public.notification_events enable row level security;
alter table public.ai_usage_events enable row level security;
alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;
alter table public.ai_daily_usage enable row level security;
alter table public.ai_project_daily_usage enable row level security;
alter table public.audit_events enable row level security;

create policy "profiles_read_self_or_admin" on public.profiles
for select to authenticated
using (
  id = (select auth.uid())
  or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "profiles_update_self" on public.profiles
for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy "published_levels_read" on public.course_levels
for select to anon, authenticated using (is_published);

create policy "published_units_read" on public.course_units
for select to anon, authenticated using (
  is_published and exists (
    select 1 from public.course_levels level
    where level.id = level_id and level.is_published
  )
);

create policy "published_lessons_read" on public.lessons
for select to anon, authenticated using (
  is_published and exists (
    select 1 from public.course_units unit
    join public.course_levels level on level.id = unit.level_id
    where unit.id = unit_id and unit.is_published and level.is_published
  )
);

create policy "progress_read_self" on public.student_progress
for select to authenticated using (user_id = (select auth.uid()));
create policy "progress_insert_self" on public.student_progress
for insert to authenticated with check (user_id = (select auth.uid()));
create policy "progress_update_self" on public.student_progress
for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy "teacher_application_read_self_or_admin"
on public.teacher_applications for select to authenticated
using (
  user_id = (select auth.uid())
  or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);
create policy "teacher_application_submit_self"
on public.teacher_applications for insert to authenticated
with check (
  user_id = (select auth.uid())
  and status = 'pending'
  and reviewed_at is null
  and reviewed_by is null
);

create policy "notifications_read_self" on public.notification_events
for select to authenticated using (user_id = (select auth.uid()));
create policy "ai_usage_read_self" on public.ai_usage_events
for select to authenticated using (user_id = (select auth.uid()));
create policy "ai_conversations_read_self" on public.ai_conversations
for select to authenticated using (user_id = (select auth.uid()));
create policy "ai_messages_read_self" on public.ai_messages
for select to authenticated using (user_id = (select auth.uid()));
create policy "audit_read_admin" on public.audit_events
for select to authenticated
using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

revoke all on public.profiles, public.course_levels, public.course_units,
  public.lessons, public.student_progress, public.teacher_applications,
  public.notification_events, public.ai_usage_events, public.audit_events,
  public.ai_conversations, public.ai_messages, public.ai_daily_usage,
  public.ai_project_daily_usage
from anon, authenticated;

grant select on public.profiles to authenticated;
grant update (display_name, preferred_locale) on public.profiles to authenticated;
grant select on public.course_levels, public.course_units, public.lessons
  to anon, authenticated;
grant select, insert, update on public.student_progress to authenticated;
grant select, insert on public.teacher_applications to authenticated;
grant select on public.notification_events, public.ai_usage_events to authenticated;
grant select on public.ai_conversations, public.ai_messages to authenticated;
grant select on public.audit_events to authenticated;

grant all on public.profiles, public.course_levels, public.course_units,
  public.lessons, public.student_progress, public.teacher_applications,
  public.notification_events, public.ai_usage_events, public.audit_events
  , public.ai_conversations, public.ai_messages, public.ai_daily_usage,
  public.ai_project_daily_usage
to service_role;
grant usage, select on sequence public.audit_events_id_seq to service_role;
grant usage, select on sequence public.ai_messages_id_seq to service_role;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'teacher-verification',
  'teacher-verification',
  false,
  10485760,
  array['application/pdf', 'image/jpeg', 'image/png']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "teacher_documents_upload_own_folder"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'teacher-verification'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.teacher_applications application
    where application.user_id = (select auth.uid())
      and application.status = 'pending'
  )
);

create policy "teacher_documents_read_self_or_admin"
on storage.objects for select to authenticated
using (
  bucket_id = 'teacher-verification'
  and (
    (storage.foldername(name))[1] = (select auth.uid())::text
    or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  )
);

create policy "teacher_documents_delete_self_pending"
on storage.objects for delete to authenticated
using (
  bucket_id = 'teacher-verification'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.teacher_applications application
    where application.user_id = (select auth.uid())
      and application.status = 'pending'
  )
);
