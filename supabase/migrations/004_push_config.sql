-- 004_push_config.sql
-- Liga/desliga cada tipo de notificacao pelo Painel Admin.
-- A chave 'global' desliga todas de uma vez.
--
-- Somente as notificacoes realmente implementadas no Sistema Kids:
--   palavra / oracao / relatorio / aniversario.

create table if not exists public.rk_push_config (
  chave text primary key,
  ativo boolean not null default true,
  atualizado_em timestamptz not null default now()
);

insert into public.rk_push_config (chave, ativo) values
  ('global', true),
  ('palavra', true),
  ('oracao', true),
  ('relatorio', true),
  ('aniversario', true)
on conflict (chave) do nothing;

alter table public.rk_push_config enable row level security;

drop policy if exists rk_push_config_select on public.rk_push_config;
create policy rk_push_config_select
  on public.rk_push_config
  for select
  to authenticated
  using (true);

drop policy if exists rk_push_config_insert on public.rk_push_config;
create policy rk_push_config_insert
  on public.rk_push_config
  for insert
  to authenticated
  with check (
    exists (
      select 1 from public.rk_pessoas
      where lower(email) = lower(auth.jwt() ->> 'email')
        and categoria ilike '%admin%'
    )
  );

drop policy if exists rk_push_config_update on public.rk_push_config;
create policy rk_push_config_update
  on public.rk_push_config
  for update
  to authenticated
  using (
    exists (
      select 1 from public.rk_pessoas
      where lower(email) = lower(auth.jwt() ->> 'email')
        and categoria ilike '%admin%'
    )
  )
  with check (
    exists (
      select 1 from public.rk_pessoas
      where lower(email) = lower(auth.jwt() ->> 'email')
        and categoria ilike '%admin%'
    )
  );

grant select, insert, update on public.rk_push_config to authenticated;
grant select, insert, update on public.rk_push_config to service_role;
