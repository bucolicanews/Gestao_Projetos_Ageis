-- ============================================================
-- 0001_inicial.sql — Esquema inicial do sistema ágil
-- ============================================================

-- ENUMS
create type public.papel_app as enum ('admin', 'desenvolvedor', 'visualizador');
create type public.status_projeto as enum ('ativo', 'pausado', 'concluido', 'arquivado');
create type public.prioridade_tarefa as enum ('baixa', 'media', 'alta', 'urgente');
create type public.coluna_kanban as enum ('backlog', 'a_fazer', 'em_progresso', 'em_revisao', 'concluido');
create type public.status_sprint as enum ('planejada', 'ativa', 'concluida');

-- ============================================================
-- USUARIOS (perfil estendido)
-- ============================================================
create table public.usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null,
  email text not null unique,
  avatar_url text,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

-- ============================================================
-- PAPEIS (separado para evitar privilege escalation)
-- ============================================================
create table public.papeis_usuario (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  papel papel_app not null,
  unique (usuario_id, papel)
);

create or replace function public.tem_papel(_usuario_id uuid, _papel papel_app)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.papeis_usuario
    where usuario_id = _usuario_id and papel = _papel
  )
$$;

-- ============================================================
-- PROJETOS
-- ============================================================
create table public.projetos (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  descricao text,
  status status_projeto not null default 'ativo',
  proprietario_id uuid not null references auth.users(id) on delete cascade,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
create index idx_projetos_proprietario on public.projetos(proprietario_id);

-- Membros do projeto (equipe)
create table public.membros_projeto (
  id uuid primary key default gen_random_uuid(),
  projeto_id uuid not null references public.projetos(id) on delete cascade,
  usuario_id uuid not null references auth.users(id) on delete cascade,
  papel papel_app not null default 'desenvolvedor',
  unique (projeto_id, usuario_id)
);
create index idx_membros_projeto_usuario on public.membros_projeto(usuario_id);

create or replace function public.eh_membro(_projeto_id uuid, _usuario_id uuid)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.membros_projeto
    where projeto_id = _projeto_id and usuario_id = _usuario_id
  ) or exists (
    select 1 from public.projetos
    where id = _projeto_id and proprietario_id = _usuario_id
  )
$$;

-- ============================================================
-- SPRINTS
-- ============================================================
create table public.sprints (
  id uuid primary key default gen_random_uuid(),
  projeto_id uuid not null references public.projetos(id) on delete cascade,
  nome text not null,
  objetivo text,
  status status_sprint not null default 'planejada',
  data_inicio date,
  data_fim date,
  criado_em timestamptz not null default now()
);
create index idx_sprints_projeto on public.sprints(projeto_id);

-- ============================================================
-- TAREFAS (User Stories)
-- ============================================================
create table public.tarefas (
  id uuid primary key default gen_random_uuid(),
  projeto_id uuid not null references public.projetos(id) on delete cascade,
  sprint_id uuid references public.sprints(id) on delete set null,
  tarefa_pai_id uuid references public.tarefas(id) on delete cascade,
  titulo text not null,
  descricao text,
  prioridade prioridade_tarefa not null default 'media',
  coluna coluna_kanban not null default 'backlog',
  posicao int not null default 0,
  responsavel_id uuid references auth.users(id) on delete set null,
  criado_por uuid not null references auth.users(id),
  prazo date,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
create index idx_tarefas_projeto on public.tarefas(projeto_id);
create index idx_tarefas_sprint on public.tarefas(sprint_id);
create index idx_tarefas_responsavel on public.tarefas(responsavel_id);
create index idx_tarefas_coluna on public.tarefas(projeto_id, coluna, posicao);

-- ============================================================
-- COMENTARIOS
-- ============================================================
create table public.comentarios (
  id uuid primary key default gen_random_uuid(),
  tarefa_id uuid not null references public.tarefas(id) on delete cascade,
  autor_id uuid not null references auth.users(id) on delete cascade,
  conteudo text not null,
  criado_em timestamptz not null default now()
);
create index idx_comentarios_tarefa on public.comentarios(tarefa_id);

-- ============================================================
-- TRIGGER: atualizado_em
-- ============================================================
create or replace function public.tocar_atualizado_em()
returns trigger language plpgsql as $$
begin new.atualizado_em = now(); return new; end;
$$;

create trigger trg_projetos_upd before update on public.projetos
  for each row execute function public.tocar_atualizado_em();
create trigger trg_tarefas_upd before update on public.tarefas
  for each row execute function public.tocar_atualizado_em();
create trigger trg_usuarios_upd before update on public.usuarios
  for each row execute function public.tocar_atualizado_em();

-- ============================================================
-- TRIGGER: criar perfil automaticamente no signup
-- ============================================================
create or replace function public.handle_novo_usuario()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.usuarios (id, nome, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)), new.email);
  insert into public.papeis_usuario (usuario_id, papel) values (new.id, 'desenvolvedor');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_novo_usuario();
