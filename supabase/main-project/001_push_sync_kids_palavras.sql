-- 001_push_sync_kids_palavras.sql
-- RODAR NO PROJETO PRINCIPAL (Sistema Videira - ctobdkstnrhepixyujms).
--
-- Sincroniza public.palavras com o Sistema Kids (mxuvvsklqaelvxmpnzhe)
-- em tempo real. A cada INSERT ou UPDATE em public.palavras a trigger
-- chama a Edge Function clonar-palavra, que faz upsert em rk_palavras
-- pelo campo origem_id. O INSERT no Kids dispara a notificacao de push
-- para os assinantes do Kids.
--
-- Pre-requisitos: extensoes pg_net e supabase_vault habilitadas.
--
-- Antes de rodar, cadastre o secret do Sistema Kids no Vault (substitua
-- <KIDS_PUSH_SECRET> pelo valor real, nao commitar):
--
--   -- se ainda nao existir:
--   select vault.create_secret('<KIDS_PUSH_SECRET>', 'kids_push_secret',
--     'Secret do Sistema Kids para sincronizar palavras');
--   -- se ja existir:
--   select vault.update_secret(
--     (select id from vault.secrets where name = 'kids_push_secret'),
--     '<KIDS_PUSH_SECRET>', 'kids_push_secret');

create or replace function public.push_sync_kids_palavras()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'net', 'vault'
as $function$
declare
  v_secret text;
  v_url text := 'https://mxuvvsklqaelvxmpnzhe.supabase.co/functions/v1/clonar-palavra';
begin
  select decrypted_secret
    into v_secret
    from vault.decrypted_secrets
   where name = 'kids_push_secret'
   limit 1;

  if v_secret is null then
    return new;
  end if;

  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-secret', v_secret
    ),
    body := jsonb_build_object(
      'type', tg_op,
      'table', tg_table_name,
      'record', to_jsonb(new)
    ),
    timeout_milliseconds := 5000
  );

  return new;
end;
$function$;

drop trigger if exists push_sync_kids_palavras on public.palavras;
create trigger push_sync_kids_palavras
after insert or update on public.palavras
for each row execute function public.push_sync_kids_palavras();
