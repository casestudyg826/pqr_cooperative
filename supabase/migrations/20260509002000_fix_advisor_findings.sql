alter function public.next_member_code()
  set search_path = public, pg_temp;

alter function public.set_updated_at()
  set search_path = public, pg_temp;

alter function public.current_member_balance(uuid)
  set search_path = public, pg_temp;

alter function public.loan_outstanding(uuid)
  set search_path = public, pg_temp;

create index if not exists backup_runs_requested_by_idx
  on public.backup_runs(requested_by);

do $$
begin
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'rls_auto_enable'
      and p.pronargs = 0
  ) then
    revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
  end if;
end;
$$;
