-- 005_palavras_origem_id.sql
-- Vincula cada palavra do Sistema Kids ao registro de origem no
-- Sistema Videira (projeto principal).
--
-- A Edge Function clonar-palavra faz upsert por origem_id, tornando a
-- sincronizacao idempotente (INSERT novo / UPDATE existente).

alter table public.rk_palavras
  add column if not exists origem_id uuid;

create unique index if not exists rk_palavras_origem_id_key
  on public.rk_palavras (origem_id);
