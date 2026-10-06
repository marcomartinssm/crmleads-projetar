-- Fecha a visualização de leads.
-- Antes: as regras de leads liberavam tudo para "quem não está vinculado a um
-- corretor". Isso incluía quem não fez login (chave pública da página) e
-- qualquer conta criada pelo cadastro aberto: 615 leads com nome e telefone
-- legíveis por qualquer pessoa. Agora vale: administrador vê tudo, corretor vê
-- só os leads dele, o resto não vê nada.

-- Quem é administrador do CRM (antes era um id fixo dentro de cada regra).
create table if not exists public.crm_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.crm_admins enable row level security;
drop policy if exists crm_admins_proprio on public.crm_admins;
create policy crm_admins_proprio on public.crm_admins
  for select to authenticated using (user_id = auth.uid());
insert into public.crm_admins (user_id)
  values ('8cf56dfd-4a82-4113-834c-fa829c0ffaf7')  -- Marco
  on conflict do nothing;

create or replace function public.crm_is_admin() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.crm_admins where user_id = auth.uid())
$$;

create or replace function public.crm_meu_corretor() returns uuid
  language sql stable security definer set search_path = public as $$
  select corretor_id from public.usuarios_corretores where user_id = auth.uid() limit 1
$$;

-- Leads
drop policy if exists corretor_ve_proprios_leads on public.leads;
drop policy if exists corretor_atualiza_proprios_leads on public.leads;
drop policy if exists corretor_cria_proprio_lead on public.leads;
create policy corretor_ve_proprios_leads on public.leads for select to authenticated
  using (public.crm_is_admin() or corretor_id = public.crm_meu_corretor());
create policy corretor_atualiza_proprios_leads on public.leads for update to authenticated
  using (public.crm_is_admin() or corretor_id = public.crm_meu_corretor())
  with check (public.crm_is_admin() or corretor_id = public.crm_meu_corretor());
create policy corretor_cria_proprio_lead on public.leads for insert to authenticated
  with check (public.crm_is_admin() or corretor_id = public.crm_meu_corretor());

-- Interações: só as dos leads que a pessoa pode ver
drop policy if exists usuarios_veem_interacoes on public.interacoes;
drop policy if exists usuarios_criam_interacoes on public.interacoes;
create policy usuarios_veem_interacoes on public.interacoes for select to authenticated
  using (public.crm_is_admin() or exists (
    select 1 from public.leads l
    where l.id = interacoes.lead_id and l.corretor_id = public.crm_meu_corretor()));
create policy usuarios_criam_interacoes on public.interacoes for insert to authenticated
  with check (public.crm_is_admin() or exists (
    select 1 from public.leads l
    where l.id = interacoes.lead_id and l.corretor_id = public.crm_meu_corretor()));

-- Corretores, funis e fases: leitura só para quem fez login
drop policy if exists usuarios_veem_corretores on public.corretores;
create policy usuarios_veem_corretores on public.corretores for select to authenticated using (true);
drop policy if exists usuarios_veem_funis on public.funis;
create policy usuarios_veem_funis on public.funis for select to authenticated using (true);
drop policy if exists usuarios_veem_fases on public.fases;
create policy usuarios_veem_fases on public.fases for select to authenticated using (true);

-- Permissões de funil estavam sem proteção nenhuma (qualquer um podia alterar)
alter table public.funis_permissoes enable row level security;
drop policy if exists usuarios_veem_permissoes on public.funis_permissoes;
create policy usuarios_veem_permissoes on public.funis_permissoes for select to authenticated using (true);
drop policy if exists admin_gerencia_permissoes on public.funis_permissoes;
create policy admin_gerencia_permissoes on public.funis_permissoes for all to authenticated
  using (public.crm_is_admin()) with check (public.crm_is_admin());

-- As regras antigas com o id do Marco fixo continuam valendo para o admin.
