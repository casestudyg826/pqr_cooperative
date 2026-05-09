create extension if not exists pgcrypto;

create sequence if not exists public.member_code_seq start 4;

create or replace function public.next_member_code()
returns text
language sql
set search_path = public, pg_temp
as $$
  select 'PQR-' || lpad(nextval('public.member_code_seq')::text, 4, '0');
$$;

create table if not exists public.app_users (
  id uuid primary key default gen_random_uuid(),
  username text not null,
  display_name text not null,
  password_hash text not null,
  role text not null check (role in ('administrator', 'treasurer')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists app_users_username_lower_key
  on public.app_users (lower(username));

create table if not exists public.app_sessions (
  token_hash text primary key,
  user_id uuid not null references public.app_users(id) on delete cascade,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists app_sessions_user_id_idx
  on public.app_sessions(user_id);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  member_code text not null unique default public.next_member_code(),
  full_name text not null,
  address text not null,
  phone text not null,
  joined_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.savings_transactions (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  type text not null check (type in ('contribution', 'withdrawal')),
  amount numeric(12, 2) not null check (amount > 0),
  occurred_at timestamptz not null default now(),
  note text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists savings_transactions_member_id_occurred_at_idx
  on public.savings_transactions(member_id, occurred_at desc);

create table if not exists public.loans (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  principal numeric(12, 2) not null check (principal > 0),
  annual_interest_rate numeric(8, 6) not null check (annual_interest_rate >= 0),
  term_months integer not null check (term_months > 0),
  applied_at timestamptz not null default now(),
  due_date timestamptz not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'paid', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists loans_member_id_applied_at_idx
  on public.loans(member_id, applied_at desc);

create table if not exists public.repayments (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.loans(id) on delete cascade,
  amount numeric(12, 2) not null check (amount > 0),
  paid_at timestamptz not null default now(),
  note text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists repayments_loan_id_paid_at_idx
  on public.repayments(loan_id, paid_at desc);

create table if not exists public.backup_runs (
  id uuid primary key default gen_random_uuid(),
  requested_by uuid references public.app_users(id) on delete set null,
  status text not null check (status in ('completed', 'failed')),
  summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.app_users(id) on delete set null,
  event_type text not null,
  table_name text,
  record_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists audit_events_actor_id_created_at_idx
  on public.audit_events(actor_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_app_users_updated_at on public.app_users;
create trigger set_app_users_updated_at
before update on public.app_users
for each row execute function public.set_updated_at();

drop trigger if exists set_members_updated_at on public.members;
create trigger set_members_updated_at
before update on public.members
for each row execute function public.set_updated_at();

drop trigger if exists set_loans_updated_at on public.loans;
create trigger set_loans_updated_at
before update on public.loans
for each row execute function public.set_updated_at();

create or replace function public.current_member_balance(p_member_id uuid)
returns numeric
language sql
stable
set search_path = public, pg_temp
as $$
  select coalesce(
    sum(case when type = 'contribution' then amount else -amount end),
    0
  )
  from public.savings_transactions
  where member_id = p_member_id;
$$;

create or replace function public.loan_outstanding(p_loan_id uuid)
returns numeric
language sql
stable
set search_path = public, pg_temp
as $$
  select greatest(
    coalesce(l.principal + (l.principal * l.annual_interest_rate * (l.term_months::numeric / 12)), 0)
    - coalesce(sum(r.amount), 0),
    0
  )
  from public.loans l
  left join public.repayments r on r.loan_id = l.id
  where l.id = p_loan_id
  group by l.id;
$$;

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
      'role', target_user.role
    );
end;
$$;

create or replace function public.create_app_user(
  p_actor_id uuid,
  p_display_name text,
  p_username text,
  p_password text,
  p_role text
)
returns public.app_users
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  created_user public.app_users;
begin
  if trim(coalesce(p_password, '')) = '' then
    raise exception 'Password is required.' using errcode = 'P0001';
  end if;

  insert into public.app_users(display_name, username, password_hash, role)
  values (
    trim(p_display_name),
    trim(p_username),
    crypt(p_password, gen_salt('bf')),
    p_role
  )
  returning * into created_user;

  insert into public.audit_events(actor_id, event_type, table_name, record_id, details)
  values (p_actor_id, 'create_user', 'app_users', created_user.id::text, to_jsonb(created_user) - 'password_hash');

  return created_user;
end;
$$;

create or replace function public.update_app_user(
  p_actor_id uuid,
  p_user_id uuid,
  p_display_name text,
  p_username text,
  p_password text,
  p_role text,
  p_is_active boolean
)
returns public.app_users
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  updated_user public.app_users;
begin
  update public.app_users
  set
    display_name = trim(p_display_name),
    username = trim(p_username),
    password_hash = case
      when trim(coalesce(p_password, '')) = '' then password_hash
      else crypt(p_password, gen_salt('bf'))
    end,
    role = p_role,
    is_active = p_is_active
  where id = p_user_id
  returning * into updated_user;

  if updated_user.id is null then
    raise exception 'User was not found.' using errcode = 'P0001';
  end if;

  insert into public.audit_events(actor_id, event_type, table_name, record_id, details)
  values (p_actor_id, 'update_user', 'app_users', updated_user.id::text, to_jsonb(updated_user) - 'password_hash');

  return updated_user;
end;
$$;

create or replace function public.record_savings_transaction(
  p_actor_id uuid,
  p_member_id uuid,
  p_type text,
  p_amount numeric,
  p_note text
)
returns public.savings_transactions
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  balance numeric;
  created_transaction public.savings_transactions;
begin
  if p_type not in ('contribution', 'withdrawal') then
    raise exception 'Invalid savings transaction type.' using errcode = 'P0001';
  end if;

  if p_amount <= 0 then
    raise exception 'Amount must be greater than zero.' using errcode = 'P0001';
  end if;

  if not exists (select 1 from public.members where id = p_member_id) then
    raise exception 'Member was not found.' using errcode = 'P0001';
  end if;

  balance := public.current_member_balance(p_member_id);
  if p_type = 'withdrawal' and p_amount > balance then
    raise exception 'Withdrawal exceeds account balance.' using errcode = 'P0001';
  end if;

  insert into public.savings_transactions(member_id, type, amount, note)
  values (p_member_id, p_type, p_amount, coalesce(nullif(trim(p_note), ''), p_type))
  returning * into created_transaction;

  insert into public.audit_events(actor_id, event_type, table_name, record_id, details)
  values (p_actor_id, 'record_savings_transaction', 'savings_transactions', created_transaction.id::text, to_jsonb(created_transaction));

  return created_transaction;
end;
$$;

create or replace function public.record_loan_repayment(
  p_actor_id uuid,
  p_loan_id uuid,
  p_amount numeric,
  p_note text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  outstanding_before numeric;
  created_repayment public.repayments;
  updated_loan public.loans;
begin
  if p_amount <= 0 then
    raise exception 'Amount must be greater than zero.' using errcode = 'P0001';
  end if;

  select public.loan_outstanding(p_loan_id) into outstanding_before;

  if outstanding_before is null then
    raise exception 'Loan was not found.' using errcode = 'P0001';
  end if;

  if p_amount > outstanding_before then
    raise exception 'Payment exceeds outstanding balance.' using errcode = 'P0001';
  end if;

  insert into public.repayments(loan_id, amount, note)
  values (p_loan_id, p_amount, coalesce(nullif(trim(p_note), ''), 'Loan repayment'))
  returning * into created_repayment;

  update public.loans
  set status = case
    when public.loan_outstanding(p_loan_id) <= 0 then 'paid'
    else 'approved'
  end
  where id = p_loan_id
  returning * into updated_loan;

  insert into public.audit_events(actor_id, event_type, table_name, record_id, details)
  values (p_actor_id, 'record_loan_repayment', 'repayments', created_repayment.id::text, to_jsonb(created_repayment));

  return jsonb_build_object(
    'repayment', to_jsonb(created_repayment),
    'loan', to_jsonb(updated_loan)
  );
end;
$$;

alter table public.app_users enable row level security;
alter table public.app_sessions enable row level security;
alter table public.members enable row level security;
alter table public.savings_transactions enable row level security;
alter table public.loans enable row level security;
alter table public.repayments enable row level security;
alter table public.backup_runs enable row level security;
alter table public.audit_events enable row level security;

drop policy if exists "service_role manages app_users" on public.app_users;
create policy "service_role manages app_users"
on public.app_users for all
to service_role
using (true)
with check (true);

drop policy if exists "service_role manages app_sessions" on public.app_sessions;
create policy "service_role manages app_sessions"
on public.app_sessions for all
to service_role
using (true)
with check (true);

drop policy if exists "service_role manages members" on public.members;
create policy "service_role manages members"
on public.members for all
to service_role
using (true)
with check (true);

drop policy if exists "service_role manages savings_transactions" on public.savings_transactions;
create policy "service_role manages savings_transactions"
on public.savings_transactions for all
to service_role
using (true)
with check (true);

drop policy if exists "service_role manages loans" on public.loans;
create policy "service_role manages loans"
on public.loans for all
to service_role
using (true)
with check (true);

drop policy if exists "service_role manages repayments" on public.repayments;
create policy "service_role manages repayments"
on public.repayments for all
to service_role
using (true)
with check (true);

drop policy if exists "service_role manages backup_runs" on public.backup_runs;
create policy "service_role manages backup_runs"
on public.backup_runs for all
to service_role
using (true)
with check (true);

drop policy if exists "service_role manages audit_events" on public.audit_events;
create policy "service_role manages audit_events"
on public.audit_events for all
to service_role
using (true)
with check (true);

revoke all on table public.app_users from anon, authenticated;
revoke all on table public.app_sessions from anon, authenticated;
revoke all on table public.members from anon, authenticated;
revoke all on table public.savings_transactions from anon, authenticated;
revoke all on table public.loans from anon, authenticated;
revoke all on table public.repayments from anon, authenticated;
revoke all on table public.backup_runs from anon, authenticated;
revoke all on table public.audit_events from anon, authenticated;

grant usage on schema public to service_role;
grant all on table public.app_users to service_role;
grant all on table public.app_sessions to service_role;
grant all on table public.members to service_role;
grant all on table public.savings_transactions to service_role;
grant all on table public.loans to service_role;
grant all on table public.repayments to service_role;
grant all on table public.backup_runs to service_role;
grant all on table public.audit_events to service_role;
grant usage, select on sequence public.member_code_seq to service_role;

revoke execute on function public.pqr_login(text, text) from public, anon, authenticated;
revoke execute on function public.create_app_user(uuid, text, text, text, text) from public, anon, authenticated;
revoke execute on function public.update_app_user(uuid, uuid, text, text, text, text, boolean) from public, anon, authenticated;
revoke execute on function public.record_savings_transaction(uuid, uuid, text, numeric, text) from public, anon, authenticated;
revoke execute on function public.record_loan_repayment(uuid, uuid, numeric, text) from public, anon, authenticated;
grant execute on function public.pqr_login(text, text) to service_role;
grant execute on function public.create_app_user(uuid, text, text, text, text) to service_role;
grant execute on function public.update_app_user(uuid, uuid, text, text, text, text, boolean) to service_role;
grant execute on function public.record_savings_transaction(uuid, uuid, text, numeric, text) to service_role;
grant execute on function public.record_loan_repayment(uuid, uuid, numeric, text) to service_role;

insert into public.app_users(id, username, display_name, password_hash, role)
select '00000000-0000-0000-0000-000000000001'::uuid, 'admin', 'System Administrator', crypt('admin123', gen_salt('bf')), 'administrator'
where not exists (select 1 from public.app_users where lower(username) = 'admin');

insert into public.app_users(id, username, display_name, password_hash, role)
select '00000000-0000-0000-0000-000000000002'::uuid, 'treasurer', 'Cooperative Treasurer', crypt('treasurer123', gen_salt('bf')), 'treasurer'
where not exists (select 1 from public.app_users where lower(username) = 'treasurer');

insert into public.members(id, member_code, full_name, address, phone, joined_at, status)
values
  ('10000000-0000-0000-0000-000000000001', 'PQR-0001', 'Maria Santos', 'Lahug, Cebu City', '0917 100 2001', '2021-03-12 00:00:00+00', 'active'),
  ('10000000-0000-0000-0000-000000000002', 'PQR-0002', 'Juan Dela Cruz', 'Mabolo, Cebu City', '0918 200 3002', '2022-07-03 00:00:00+00', 'active'),
  ('10000000-0000-0000-0000-000000000003', 'PQR-0003', 'Ana Reyes', 'Talisay City, Cebu', '0919 300 4003', '2023-01-22 00:00:00+00', 'active')
on conflict (id) do nothing;

insert into public.savings_transactions(id, member_id, type, amount, occurred_at, note)
values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'contribution', 15000, '2025-01-15 00:00:00+00', 'Opening savings balance'),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'contribution', 9200, '2025-02-07 00:00:00+00', 'Monthly contribution'),
  ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 'contribution', 12500, '2025-02-18 00:00:00+00', 'Opening savings balance'),
  ('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', 'withdrawal', 2000, '2025-03-10 00:00:00+00', 'Member withdrawal')
on conflict (id) do nothing;

insert into public.loans(id, member_id, principal, annual_interest_rate, term_months, applied_at, due_date, status)
values
  ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 30000, 0.12, 12, '2025-01-20 00:00:00+00', '2026-01-20 00:00:00+00', 'approved'),
  ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 18000, 0.10, 10, '2025-04-05 00:00:00+00', '2026-02-05 00:00:00+00', 'pending')
on conflict (id) do nothing;

insert into public.repayments(id, loan_id, amount, paid_at, note)
values
  ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 7000, '2025-04-02 00:00:00+00', 'Partial repayment')
on conflict (id) do nothing;
