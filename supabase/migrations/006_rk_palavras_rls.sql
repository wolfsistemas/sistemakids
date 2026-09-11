-- 006_rk_palavras_rls.sql
-- Restringe a escrita em rk_palavras.
--
-- Leitura: qualquer usuario autenticado (policy rk_select_all_palavras, mantida).
-- Escrita (INSERT/UPDATE/DELETE): apenas categoria Administrador ou Pastor(a).
-- A Edge Function clonar-palavra usa a service_role, que ignora RLS, entao a
-- sincronizacao vinda do Sistema Videira continua funcionando normalmente.

drop policy if exists permite_autenticado on public.rk_palavras;

drop policy if exists rk_palavras_insert_staff on public.rk_palavras;
create policy rk_palavras_insert_staff
  on public.rk_palavras
  for insert
  to authenticated
  with check (
    exists (
      select 1 from public.rk_pessoas p
      where lower(p.email) = lower(auth.jwt() ->> 'email')
        and (p.categoria ilike '%admin%' or p.categoria ilike '%pastor%')
    )
  );

drop policy if exists rk_palavras_update_staff on public.rk_palavras;
create policy rk_palavras_update_staff
  on public.rk_palavras
  for update
  to authenticated
  using (
    exists (
      select 1 from public.rk_pessoas p
      where lower(p.email) = lower(auth.jwt() ->> 'email')
        and (p.categoria ilike '%admin%' or p.categoria ilike '%pastor%')
    )
  )
  with check (
    exists (
      select 1 from public.rk_pessoas p
      where lower(p.email) = lower(auth.jwt() ->> 'email')
        and (p.categoria ilike '%admin%' or p.categoria ilike '%pastor%')
    )
  );

drop policy if exists rk_palavras_delete_staff on public.rk_palavras;
create policy rk_palavras_delete_staff
  on public.rk_palavras
  for delete
  to authenticated
  using (
    exists (
      select 1 from public.rk_pessoas p
      where lower(p.email) = lower(auth.jwt() ->> 'email')
        and (p.categoria ilike '%admin%' or p.categoria ilike '%pastor%')
    )
  );
