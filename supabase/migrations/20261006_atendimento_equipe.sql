-- Tela "Atendimento da equipe" (visão do gestor, aprovada pelo Tales em 06/10).
-- O Antônio (dono da Projetar, corretor "José Antonio" no CRM) também vê essa
-- tela, então vira administrador.
insert into public.crm_admins (user_id)
  values ('2e87a9f1-bfb3-4a20-a89d-43a604cd1b73')  -- Antônio
  on conflict do nothing;

-- Último acesso de cada corretor ao CRM (o login fica numa área que a página
-- não lê). Só devolve algo para administrador.
create or replace function public.crm_ultimos_acessos()
  returns table (corretor_id uuid, ultimo_acesso timestamptz)
  language sql stable security definer set search_path = public, auth as $$
  select uc.corretor_id, u.last_sign_in_at
  from public.usuarios_corretores uc join auth.users u on u.id = uc.user_id
  where public.crm_is_admin()
$$;
revoke execute on function public.crm_ultimos_acessos() from public, anon;
grant execute on function public.crm_ultimos_acessos() to authenticated;
