-- ============================================================
-- 0003_burndown.sql — Snapshot diário para burndown chart
-- ============================================================

create table public.snapshots_sprint (
  id uuid primary key default gen_random_uuid(),
  sprint_id uuid not null references public.sprints(id) on delete cascade,
  data date not null,
  total_tarefas int not null default 0,
  concluidas int not null default 0,
  restantes int not null default 0,
  criado_em timestamptz not null default now(),
  unique (sprint_id, data)
);
create index idx_snap_sprint on public.snapshots_sprint(sprint_id, data);

alter table public.snapshots_sprint enable row level security;

create policy "snap_select_membros" on public.snapshots_sprint
  for select to authenticated
  using (exists (
    select 1 from public.sprints s
    where s.id = sprint_id and public.eh_membro(s.projeto_id, auth.uid())
  ));

create policy "snap_insert_membros" on public.snapshots_sprint
  for insert to authenticated
  with check (exists (
    select 1 from public.sprints s
    where s.id = sprint_id and public.eh_membro(s.projeto_id, auth.uid())
  ));

-- Função que registra/atualiza snapshot de hoje para uma sprint
create or replace function public.registrar_snapshot_sprint(_sprint_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total int;
  v_concl int;
begin
  select
    count(*)::int,
    count(*) filter (where coluna = 'concluido')::int
  into v_total, v_concl
  from public.tarefas
  where sprint_id = _sprint_id;

  insert into public.snapshots_sprint (sprint_id, data, total_tarefas, concluidas, restantes)
  values (_sprint_id, current_date, v_total, v_concl, v_total - v_concl)
  on conflict (sprint_id, data)
  do update set
    total_tarefas = excluded.total_tarefas,
    concluidas    = excluded.concluidas,
    restantes     = excluded.restantes;
end;
$$;

-- Trigger: a cada UPDATE/INSERT/DELETE em tarefas com sprint, atualiza snapshot do dia
create or replace function public.aoMudarTarefaAtualizarSnapshot()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'DELETE') then
    if old.sprint_id is not null then
      perform public.registrar_snapshot_sprint(old.sprint_id);
    end if;
    return old;
  else
    if new.sprint_id is not null then
      perform public.registrar_snapshot_sprint(new.sprint_id);
    end if;
    if (tg_op = 'UPDATE' and old.sprint_id is not null and old.sprint_id is distinct from new.sprint_id) then
      perform public.registrar_snapshot_sprint(old.sprint_id);
    end if;
    return new;
  end if;
end;
$$;

drop trigger if exists trg_tarefas_snapshot on public.tarefas;
create trigger trg_tarefas_snapshot
  after insert or update or delete on public.tarefas
  for each row execute function public.aoMudarTarefaAtualizarSnapshot();
