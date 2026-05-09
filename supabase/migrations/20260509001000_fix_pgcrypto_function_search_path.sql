alter function public.pqr_login(text, text)
  set search_path = public, extensions, pg_temp;

alter function public.create_app_user(uuid, text, text, text, text)
  set search_path = public, extensions, pg_temp;

alter function public.update_app_user(uuid, uuid, text, text, text, text, boolean)
  set search_path = public, extensions, pg_temp;
