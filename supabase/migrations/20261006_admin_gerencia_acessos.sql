-- Gerenciar login de corretor pelo CRM (pedido do Tales em 06/10): o
-- administrador precisa ver o email de login e se o acesso está bloqueado.
create or replace function public.crm_acessos()
  returns table (corretor_id uuid, email text, bloqueado boolean, ultimo_acesso timestamptz)
  language sql stable security definer set search_path = public, auth as $$
  select uc.corretor_id, u.email::text,
         coalesce(u.banned_until > now(), false), u.last_sign_in_at
  from public.usuarios_corretores uc join auth.users u on u.id = uc.user_id
  where public.crm_is_admin()
$$;
revoke execute on function public.crm_acessos() from public, anon;
grant execute on function public.crm_acessos() to authenticated;
