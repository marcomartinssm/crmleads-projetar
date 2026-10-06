-- O administrador precisa saber quem já tem login para a tela de Corretores
-- mostrar "Criar acesso" só para quem ainda não tem.
drop policy if exists admin_ve_vinculos on public.usuarios_corretores;
create policy admin_ve_vinculos on public.usuarios_corretores for select to authenticated
  using (public.crm_is_admin());
