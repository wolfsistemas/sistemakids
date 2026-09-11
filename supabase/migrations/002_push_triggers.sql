-- 002_push_triggers.sql
-- Dispara notificacoes Web Push automaticas a partir de eventos no banco.
--
-- O secret de autorizacao da Edge Function fica no Vault sob o nome 'push_secret'.
-- A Edge Function 'notificar' resolve os destinatarios de cada evento.
--
-- No Sistema Kids nao existem tabelas de eventos/inscricoes (a agenda vem do
-- Google Apps Script), por isso os triggers cobrem apenas:
--   rk_palavras    -> nova palavra/aviso (todos)
--   rk_sugestoes   -> novo pedido de oracao (pastoras)
--   rk_relatorios  -> novo relatorio de celula (cadeia superior_id)

create extension if not exists pg_net;

create or replace function public.push_triggers_dispatch()
returns trigger
language plpgsql
security definer
set search_path = public, net, vault
as $$
declare
  v_secret text;
  v_url text := 'https://mxuvvsklqaelvxmpnzhe.supabase.co/functions/v1/notificar';
  v_body jsonb;
begin
  select decrypted_secret
    into v_secret
    from vault.decrypted_secrets
   where name = 'push_secret'
   limit 1;

  if v_secret is null then
    return new;
  end if;

  v_body := jsonb_build_object(
    'type', tg_op,
    'table', tg_table_name,
    'record', to_jsonb(new)
  );

  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-secret', v_secret
    ),
    body := v_body,
    timeout_milliseconds := 5000
  );

  return new;
end;
$$;

drop trigger if exists push_notify_palavras on public.rk_palavras;
create trigger push_notify_palavras
  after insert on public.rk_palavras
  for each row execute function public.push_triggers_dispatch();

drop trigger if exists push_notify_sugestoes on public.rk_sugestoes;
create trigger push_notify_sugestoes
  after insert on public.rk_sugestoes
  for each row execute function public.push_triggers_dispatch();

drop trigger if exists push_notify_relatorios on public.rk_relatorios;
create trigger push_notify_relatorios
  after insert on public.rk_relatorios
  for each row execute function public.push_triggers_dispatch();
