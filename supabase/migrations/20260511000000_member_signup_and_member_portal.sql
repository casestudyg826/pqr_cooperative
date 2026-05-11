alter table public.app_users
  drop constraint if exists app_users_role_check;

alter table public.app_users
  add constraint app_users_role_check
  check (role in ('administrator', 'treasurer', 'member'));

alter table public.app_users
  add column if not exists member_id uuid references public.members(id) on delete set null;

create unique index if not exists app_users_member_id_key
  on public.app_users(member_id)
  where member_id is not null;

create or replace function public.pqr_login(p_username text, p_password text)
returns table(token text, user_record jsonb)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  target_user public.app_users%rowtype;
  raw_token text;
begin
  select *
  into target_user
  from public.app_users
  where lower(username) = lower(trim(p_username))
    and is_active
  limit 1;

  if target_user.id is null
     or target_user.password_hash <> crypt(p_password, target_user.password_hash) then
    raise exception 'Invalid username or password.' using errcode = 'P0001';
  end if;

  raw_token := encode(gen_random_bytes(32), 'hex');

  insert into public.app_sessions(token_hash, user_id, expires_at)
  values (encode(digest(raw_token, 'sha256'), 'hex'), target_user.id, now() + interval '8 hours');

  insert into public.audit_events(actor_id, event_type, table_name, record_id)
  values (target_user.id, 'login', 'app_users', target_user.id::text);

  return query
  select
    raw_token,
    jsonb_build_object(
      'id', target_user.id,
      'username', target_user.username,
      'display_name', target_user.display_name,
      'role', target_user.role,
      'member_id', target_user.member_id
    );
end;
$$;

create or replace function public.pqr_member_signup(
  p_full_name text,
  p_address text,
  p_phone text,
  p_username text,
  p_password text
)
returns table(token text, user_record jsonb)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  created_member public.members;
  created_user public.app_users;
  raw_token text;
begin
  if trim(coalesce(p_password, '')) = '' then
    raise exception 'Password is required.' using errcode = 'P0001';
  end if;

  if exists (select 1 from public.app_users where lower(username) = lower(trim(p_username))) then
    raise exception 'Username already exists.' using errcode = 'P0001';
  end if;

  insert into public.members(full_name, address, phone, status)
  values (trim(p_full_name), trim(p_address), trim(p_phone), 'active')
  returning * into created_member;

  insert into public.app_users(display_name, username, password_hash, role, member_id)
  values (
    created_member.full_name,
    trim(p_username),
    crypt(p_password, gen_salt('bf')),
    'member',
    created_member.id
  )
  returning * into created_user;

  raw_token := encode(gen_random_bytes(32), 'hex');
  insert into public.app_sessions(token_hash, user_id, expires_at)
  values (
    encode(digest(raw_token, 'sha256'), 'hex'),
    created_user.id,
    now() + interval '8 hours'
  );

  insert into public.audit_events(actor_id, event_type, table_name, record_id, details)
  values (
    created_user.id,
    'member_signup',
    'app_users',
    created_user.id::text,
    jsonb_build_object('member_id', created_member.id, 'username', created_user.username)
  );

  return query
  select
    raw_token,
    jsonb_build_object(
      'id', created_user.id,
      'username', created_user.username,
      'display_name', created_user.display_name,
      'role', created_user.role,
      'member_id', created_user.member_id
    );
end;
$$;

alter table public.loans
  add column if not exists approved_at timestamptz;

alter table public.loans
  alter column annual_interest_rate drop not null,
  alter column term_months drop not null,
  alter column due_date drop not null;

alter table public.loans
  drop constraint if exists loans_annual_interest_rate_check,
  drop constraint if exists loans_term_months_check;

alter table public.loans
  add constraint loans_annual_interest_rate_check
  check (annual_interest_rate is null or annual_interest_rate >= 0),
  add constraint loans_term_months_check
  check (term_months is null or term_months > 0),
  add constraint loans_terms_required_on_approval_check
  check (
    status not in ('approved', 'paid')
    or (
      annual_interest_rate is not null
      and term_months is not null
      and due_date is not null
    )
  );

revoke execute on function public.pqr_member_signup(text, text, text, text, text)
from public, anon, authenticated;
grant execute on function public.pqr_member_signup(text, text, text, text, text)
to service_role;
