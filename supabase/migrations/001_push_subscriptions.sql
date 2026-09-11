-- 001_push_subscriptions.sql
-- Tabela de inscricoes Web Push + RLS.
-- O usuario autenticado so enxerga/grava as inscricoes da propria pessoa
-- (casando rk_pessoas.email com o e-mail do JWT).

create table if not exists public.rk_push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  pessoa_id uuid not null references public.rk_pessoas(id) on delete cascade,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  user_agent text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists rk_push_subscriptions_pessoa_id_idx
  on public.rk_push_subscriptions (pessoa_id);

alter table public.rk_push_subscriptions enable row level security;

drop policy if exists rk_push_select_own on public.rk_push_subscriptions;
create policy rk_push_select_own
  on public.rk_push_subscriptions
  for select
  to authenticated
  using (
    pessoa_id in (
      select id from public.rk_pessoas
      where lower(email) = lower(auth.jwt() ->> 'email')
    )
  );

drop policy if exists rk_push_insert_own on public.rk_push_subscriptions;
create policy rk_push_insert_own
  on public.rk_push_subscriptions
  for insert
  to authenticated
  with check (
    pessoa_id in (
      select id from public.rk_pessoas
      where lower(email) = lower(auth.jwt() ->> 'email')
    )
  );

drop policy if exists rk_push_update_own on public.rk_push_subscriptions;
create policy rk_push_update_own
  on public.rk_push_subscriptions
  for update
  to authenticated
  using (
    pessoa_id in (
      select id from public.rk_pessoas
      where lower(email) = lower(auth.jwt() ->> 'email')
    )
  )
  with check (
    pessoa_id in (
      select id from public.rk_pessoas
      where lower(email) = lower(auth.jwt() ->> 'email')
    )
  );

drop policy if exists rk_push_delete_own on public.rk_push_subscriptions;
create policy rk_push_delete_own
  on public.rk_push_subscriptions
  for delete
  to authenticated
  using (
    pessoa_id in (
      select id from public.rk_pessoas
      where lower(email) = lower(auth.jwt() ->> 'email')
    )
  );

grant select, insert, update, delete on public.rk_push_subscriptions to authenticated;
grant select, insert, update, delete on public.rk_push_subscriptions to service_role;
