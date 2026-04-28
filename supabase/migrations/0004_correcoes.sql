-- ============================================================
-- 0004_correcoes.sql — Correções incrementais
-- Foco: garantir que o usuário consiga LOGAR e VER seus dados.
-- Idempotente: pode ser executada várias vezes sem erro.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Trigger de novo usuário tolerante a falhas
--    (se já existe perfil, não quebra o signup)
-- ------------------------------------------------------------
create or replace function public.handle_novo_usuario()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.usuarios (id, nome, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)),
    new.email
  )
  on conflict (id) do nothing;

  insert into public.papeis_usuario (usuario_id, papel)
  values (new.id, 'desenvolvedor')
  on conflict (usuario_id, papel) do nothing;

  return new;
exception when others then
  -- nunca bloquear o signup por causa do perfil
  raise warning 'handle_novo_usuario falhou: %', sqlerrm;
  return new;
end;
$$;

-- Recria o trigger garantindo que existe
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_novo_usuario();

-- Backfill: cria perfil para usuários que já existem em auth.users
-- mas não têm linha em public.usuarios (ex.: signup antes do trigger).
insert into public.usuarios (id, nome, email)
select
  u.id,
  coalesce(u.raw_user_meta_data->>'nome', split_part(u.email, '@', 1)),
  u.email
from auth.users u
left join public.usuarios pu on pu.id = u.id
where pu.id is null
  and u.email is not null
on conflict (id) do nothing;

insert into public.papeis_usuario (usuario_id, papel)
select u.id, 'desenvolvedor'::papel_app
from auth.users u
left join public.papeis_usuario pp on pp.usuario_id = u.id
where pp.usuario_id is null
on conflict (usuario_id, papel) do nothing;

-- ------------------------------------------------------------
-- 2) Auto-adicionar o proprietário como membro do projeto
--    (resolve "criei projeto e a lista volta vazia")
-- ------------------------------------------------------------
create or replace function public.adicionar_proprietario_como_membro()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.membros_projeto (projeto_id, usuario_id, papel)
  values (new.id, new.proprietario_id, 'admin')
  on conflict (projeto_id, usuario_id) do nothing;
  return new;
end;
$$;

drop trigger if exists trg_projeto_proprietario_membro on public.projetos;
create trigger trg_projeto_proprietario_membro
  after insert on public.projetos
  for each row execute function public.adicionar_proprietario_como_membro();

-- Backfill para projetos antigos
insert into public.membros_projeto (projeto_id, usuario_id, papel)
select p.id, p.proprietario_id, 'admin'::papel_app
from public.projetos p
left join public.membros_projeto m
  on m.projeto_id = p.id and m.usuario_id = p.proprietario_id
where m.id is null
on conflict (projeto_id, usuario_id) do nothing;

-- ------------------------------------------------------------
-- 3) INSERT em papeis_usuario (faltava policy — só tinha SELECT)
-- ------------------------------------------------------------
drop policy if exists "papeis_insert_proprio" on public.papeis_usuario;
create policy "papeis_insert_proprio" on public.papeis_usuario
  for insert to authenticated
  with check (usuario_id = auth.uid());

-- ------------------------------------------------------------
-- 4) INSERT em usuarios pelo próprio usuário (caso o trigger falhe)
-- ------------------------------------------------------------
drop policy if exists "usuarios_insert_proprio" on public.usuarios;
create policy "usuarios_insert_proprio" on public.usuarios
  for insert to authenticated
  with check (id = auth.uid());

-- ------------------------------------------------------------
-- 5) Garante que Realtime funciona na tabela tarefas
-- ------------------------------------------------------------
alter table public.tarefas replica identity full;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'tarefas'
  ) then
    alter publication supabase_realtime add table public.tarefas;
  end if;
end $$;
