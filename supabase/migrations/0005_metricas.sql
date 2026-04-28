-- ============================================================
-- 0005_metricas.sql — Indicadores de produção e fluxo
-- Adiciona: histórico de movimentação, lead/cycle time, pontos,
--          WIP limit por projeto, view de métricas.
-- Idempotente.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Campos novos em tarefas
-- ------------------------------------------------------------
alter table public.tarefas
  add column if not exists pontos int,
  add column if not exists entrou_coluna_em timestamptz not null default now(),
  add column if not exists concluido_em timestamptz;

-- ------------------------------------------------------------
-- 2) WIP limit por coluna (jsonb) em projetos
--    Ex.: {"em_progresso": 3, "em_revisao": 2}
-- ------------------------------------------------------------
alter table public.projetos
  add column if not exists wip_limite jsonb not null default '{}'::jsonb;

-- ------------------------------------------------------------
-- 3) Histórico de movimentação entre colunas
-- ------------------------------------------------------------
create table if not exists public.historico_movimentacao (
  id uuid primary key default gen_random_uuid(),
  tarefa_id uuid not null references public.tarefas(id) on delete cascade,
  projeto_id uuid not null references public.projetos(id) on delete cascade,
  coluna_origem coluna_kanban,
  coluna_destino coluna_kanban not null,
  movido_por uuid references auth.users(id) on delete set null,
  movido_em timestamptz not null default now()
);
create index if not exists idx_hist_mov_tarefa on public.historico_movimentacao(tarefa_id, movido_em);
create index if not exists idx_hist_mov_projeto on public.historico_movimentacao(projeto_id, movido_em);

alter table public.historico_movimentacao enable row level security;

drop policy if exists "hist_select_membros" on public.historico_movimentacao;
create policy "hist_select_membros" on public.historico_movimentacao
  for select to authenticated
  using (public.eh_membro(projeto_id, auth.uid()));

drop policy if exists "hist_insert_sistema" on public.historico_movimentacao;
create policy "hist_insert_sistema" on public.historico_movimentacao
  for insert to authenticated
  with check (public.eh_membro(projeto_id, auth.uid()));

-- ------------------------------------------------------------
-- 4) Trigger: ao mover coluna registra histórico + atualiza
--    entrou_coluna_em e concluido_em
-- ------------------------------------------------------------
create or replace function public.tocar_movimento_kanban()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if TG_OP = 'INSERT' then
    insert into public.historico_movimentacao
      (tarefa_id, projeto_id, coluna_origem, coluna_destino, movido_por)
    values (new.id, new.projeto_id, null, new.coluna, new.criado_por);

    if new.coluna = 'concluido' then
      new.concluido_em := now();
    end if;
    return new;
  end if;

  if TG_OP = 'UPDATE' and new.coluna is distinct from old.coluna then
    new.entrou_coluna_em := now();
    if new.coluna = 'concluido' and old.coluna <> 'concluido' then
      new.concluido_em := now();
    elsif new.coluna <> 'concluido' then
      new.concluido_em := null;
    end if;

    insert into public.historico_movimentacao
      (tarefa_id, projeto_id, coluna_origem, coluna_destino, movido_por)
    values (new.id, new.projeto_id, old.coluna, new.coluna, auth.uid());
  end if;

  return new;
end;
$$;

drop trigger if exists trg_tarefas_movimento on public.tarefas;
create trigger trg_tarefas_movimento
  before insert or update of coluna on public.tarefas
  for each row execute function public.tocar_movimento_kanban();

-- ------------------------------------------------------------
-- 5) View de métricas por tarefa (lead time, cycle time)
-- ------------------------------------------------------------
create or replace view public.v_metricas_tarefa
with (security_invoker = on) as
select
  t.id,
  t.projeto_id,
  t.titulo,
  t.coluna,
  t.prioridade,
  t.responsavel_id,
  t.pontos,
  t.criado_em,
  t.concluido_em,
  t.entrou_coluna_em,
  -- lead time em horas: criação -> conclusão
  case when t.concluido_em is not null
    then extract(epoch from (t.concluido_em - t.criado_em)) / 3600.0
  end as lead_time_horas,
  -- cycle time em horas: primeira vez que entrou em em_progresso -> concluído
  case when t.concluido_em is not null then (
    select extract(epoch from (t.concluido_em - min(h.movido_em))) / 3600.0
    from public.historico_movimentacao h
    where h.tarefa_id = t.id and h.coluna_destino = 'em_progresso'
  ) end as cycle_time_horas,
  -- idade na coluna atual em horas
  extract(epoch from (now() - t.entrou_coluna_em)) / 3600.0 as idade_coluna_horas,
  -- atrasada?
  (t.prazo is not null and t.prazo < current_date and t.coluna <> 'concluido') as atrasada
from public.tarefas t;

-- ------------------------------------------------------------
-- 6) Backfill: marca concluido_em para tarefas já em 'concluido'
-- ------------------------------------------------------------
update public.tarefas
set concluido_em = coalesce(concluido_em, atualizado_em)
where coluna = 'concluido' and concluido_em is null;
