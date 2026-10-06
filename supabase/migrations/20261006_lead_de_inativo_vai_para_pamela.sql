-- Lead que chegar para corretor desativado vai para a Pamela.
-- Motivo: a distribuição automática (fora deste repositório) continuou mandando
-- lead para o Vado depois de desativado; o último, de 28/09, nunca foi atendido.
-- Decisão do Tales em 06/10: tudo que era do Vado e o que cair em inativo vai
-- para a Pamela.
create or replace function public.crm_lead_sem_corretor_inativo() returns trigger
  language plpgsql security definer set search_path = public as $$
begin
  if new.corretor_id is not null and exists (
       select 1 from public.corretores where id = new.corretor_id and ativo = false) then
    new.corretor_id := '17b5f380-c02d-465f-9a08-2ee5519780f6'; -- Pamela de Aguiar
  end if;
  return new;
end $$;

drop trigger if exists lead_sem_corretor_inativo on public.leads;
create trigger lead_sem_corretor_inativo before insert on public.leads
  for each row execute function public.crm_lead_sem_corretor_inativo();
