-- Tales ganha acesso de administrador ao CRM (06/10), sem vínculo de corretor,
-- para ver tudo como o Marco.
insert into public.crm_admins (user_id)
  values ('d59cdb9d-62be-453d-8513-112948d0f252')  -- Tales (talesvmatos@gmail.com)
  on conflict do nothing;

-- As regras antigas davam edição total só ao id fixo do Marco; passam a valer
-- para qualquer administrador (tabela crm_admins, onde o Marco continua).
alter policy acesso_corretores on public.corretores using (public.crm_is_admin()) with check (public.crm_is_admin());
alter policy acesso_funis on public.funis using (public.crm_is_admin()) with check (public.crm_is_admin());
alter policy acesso_fases on public.fases using (public.crm_is_admin()) with check (public.crm_is_admin());
alter policy acesso_leads on public.leads using (public.crm_is_admin()) with check (public.crm_is_admin());
alter policy acesso_interacoes on public.interacoes using (public.crm_is_admin()) with check (public.crm_is_admin());
