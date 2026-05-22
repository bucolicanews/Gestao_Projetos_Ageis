-- ============================================================
-- 0021_sprint_engine.sql — Sprint Engine: campos ágeis completos
-- Adiciona: tipo_tarefa, criterio_aceite, complexidade, tags,
--           estimativa_horas, dor_ok, dod_ok em tarefas;
--           sp_planejados, capacidade_horas em sprints;
--           tabelas dependencias_tarefa, sprint_membros, velocity_historico.
-- Idempotente.
-- ============================================================

-- ============================================================
-- 1) Enum tipo_tarefa
-- ============================================================
DO $$ BEGIN
  CREATE TYPE public.tipo_tarefa AS ENUM ('feature', 'bug', 'melhoria', 'techdeb', 'spike');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- 2) Campos novos em tarefas
-- ============================================================
ALTER TABLE public.tarefas
  ADD COLUMN IF NOT EXISTS tipo_tarefa     public.tipo_tarefa NOT NULL DEFAULT 'feature',
  ADD COLUMN IF NOT EXISTS criterio_aceite text,
  ADD COLUMN IF NOT EXISTS complexidade    int,           -- escala livre 1-5
  ADD COLUMN IF NOT EXISTS tags            text[]  NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS estimativa_horas numeric(6,2),
  ADD COLUMN IF NOT EXISTS dor_ok          boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS dod_ok          boolean NOT NULL DEFAULT false;

-- Restringe pontos à escala Fibonacci (sem quebrar NULL nem 0 legado)
DO $$ BEGIN
  ALTER TABLE public.tarefas
    ADD CONSTRAINT chk_pontos_fibonacci
    CHECK (pontos IS NULL OR pontos IN (0, 1, 2, 3, 5, 8, 13, 21));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- 3) Campos novos em sprints
-- ============================================================
ALTER TABLE public.sprints
  ADD COLUMN IF NOT EXISTS sp_planejados   int     NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS capacidade_horas numeric(8,2);

-- ============================================================
-- 4) Tabela dependencias_tarefa
-- ============================================================
DO $$ BEGIN
  CREATE TYPE public.tipo_dependencia AS ENUM ('bloqueada_por', 'relacionada_com');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.dependencias_tarefa (
  id           uuid               PRIMARY KEY DEFAULT gen_random_uuid(),
  tarefa_id    uuid               NOT NULL REFERENCES public.tarefas(id) ON DELETE CASCADE,
  depende_de   uuid               NOT NULL REFERENCES public.tarefas(id) ON DELETE CASCADE,
  tipo         public.tipo_dependencia NOT NULL DEFAULT 'bloqueada_por',
  criado_em    timestamptz        NOT NULL DEFAULT now(),
  UNIQUE (tarefa_id, depende_de)
);
CREATE INDEX IF NOT EXISTS idx_dep_tarefa    ON public.dependencias_tarefa(tarefa_id);
CREATE INDEX IF NOT EXISTS idx_dep_depende   ON public.dependencias_tarefa(depende_de);

ALTER TABLE public.dependencias_tarefa ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "dep_select_membros" ON public.dependencias_tarefa;
CREATE POLICY "dep_select_membros" ON public.dependencias_tarefa
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.tarefas t
      JOIN public.membros_projeto mp ON mp.projeto_id = t.projeto_id
      WHERE t.id = tarefa_id AND mp.usuario_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "dep_write_membros" ON public.dependencias_tarefa;
CREATE POLICY "dep_write_membros" ON public.dependencias_tarefa
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.tarefas t
      JOIN public.membros_projeto mp ON mp.projeto_id = t.projeto_id
      WHERE t.id = tarefa_id AND mp.usuario_id = auth.uid()
    )
  );

-- ============================================================
-- 5) Tabela sprint_membros (capacity planning)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.sprint_membros (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  sprint_id           uuid        NOT NULL REFERENCES public.sprints(id) ON DELETE CASCADE,
  usuario_id          uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  horas_dia           numeric(4,1) NOT NULL DEFAULT 6,
  fator_produtividade numeric(3,2) NOT NULL DEFAULT 0.8,
  UNIQUE (sprint_id, usuario_id)
);
CREATE INDEX IF NOT EXISTS idx_sprint_membros_sprint ON public.sprint_membros(sprint_id);

ALTER TABLE public.sprint_membros ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sm_select_membros" ON public.sprint_membros;
CREATE POLICY "sm_select_membros" ON public.sprint_membros
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.sprints s
      JOIN public.membros_projeto mp ON mp.projeto_id = s.projeto_id
      WHERE s.id = sprint_id AND mp.usuario_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "sm_write_membros" ON public.sprint_membros;
CREATE POLICY "sm_write_membros" ON public.sprint_membros
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.sprints s
      JOIN public.membros_projeto mp ON mp.projeto_id = s.projeto_id
      WHERE s.id = sprint_id AND mp.usuario_id = auth.uid()
    )
  );

-- ============================================================
-- 6) Tabela velocity_historico
-- ============================================================
CREATE TABLE IF NOT EXISTS public.velocity_historico (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  sprint_id      uuid        NOT NULL REFERENCES public.sprints(id) ON DELETE CASCADE,
  projeto_id     uuid        NOT NULL REFERENCES public.projetos(id) ON DELETE CASCADE,
  sp_planejados  int         NOT NULL DEFAULT 0,
  sp_concluidos  int         NOT NULL DEFAULT 0,
  gravado_em     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_velocity_projeto ON public.velocity_historico(projeto_id, gravado_em);
CREATE UNIQUE INDEX IF NOT EXISTS idx_velocity_sprint ON public.velocity_historico(sprint_id);

ALTER TABLE public.velocity_historico ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "vel_select_membros" ON public.velocity_historico;
CREATE POLICY "vel_select_membros" ON public.velocity_historico
  FOR SELECT TO authenticated
  USING (public.eh_membro(projeto_id, auth.uid()));

-- ============================================================
-- 7) Função: calcular capacidade de uma sprint
--    Fórmula: SUM(horas_dia * fator_produtividade) * dias_uteis
-- ============================================================
CREATE OR REPLACE FUNCTION public.calcular_capacidade_sprint(_sprint_id uuid)
RETURNS numeric LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(
    (SELECT SUM(sm.horas_dia * sm.fator_produtividade)
     FROM public.sprint_membros sm
     WHERE sm.sprint_id = _sprint_id)
    *
    GREATEST(1, (
      SELECT (s.data_fim - s.data_inicio)::int
      FROM public.sprints s
      WHERE s.id = _sprint_id
    )),
    0
  )
$$;

-- ============================================================
-- 8) Trigger: ao ativar sprint → bloqueia sp_planejados + recalcula capacidade
--             ao concluir sprint → grava velocity_historico
-- ============================================================
CREATE OR REPLACE FUNCTION public.tocar_sprint_status()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  _sp_concluidos int;
BEGIN
  -- Sprint ativada: congela sp_planejados e calcula capacidade
  IF NEW.status = 'ativa' AND OLD.status = 'planejada' THEN
    NEW.sp_planejados := COALESCE((
      SELECT SUM(COALESCE(pontos, 0))
      FROM public.tarefas
      WHERE sprint_id = NEW.id
    ), 0);

    NEW.capacidade_horas := public.calcular_capacidade_sprint(NEW.id);
  END IF;

  -- Sprint concluída: grava velocity
  IF NEW.status = 'concluida' AND OLD.status = 'ativa' THEN
    _sp_concluidos := COALESCE((
      SELECT SUM(COALESCE(pontos, 0))
      FROM public.tarefas
      WHERE sprint_id = NEW.id AND coluna = 'concluido'
    ), 0);

    INSERT INTO public.velocity_historico (sprint_id, projeto_id, sp_planejados, sp_concluidos)
    VALUES (NEW.id, NEW.projeto_id, NEW.sp_planejados, _sp_concluidos)
    ON CONFLICT (sprint_id) DO UPDATE
      SET sp_concluidos = EXCLUDED.sp_concluidos,
          gravado_em    = now();
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sprints_status ON public.sprints;
CREATE TRIGGER trg_sprints_status
  BEFORE UPDATE OF status ON public.sprints
  FOR EACH ROW EXECUTE FUNCTION public.tocar_sprint_status();

-- ============================================================
-- 9) View: velocity média por projeto (últimas 10 sprints)
-- ============================================================
CREATE OR REPLACE VIEW public.v_velocity_projeto
WITH (security_invoker = on) AS
SELECT
  vh.projeto_id,
  COUNT(*)                                    AS num_sprints,
  ROUND(AVG(vh.sp_concluidos), 1)            AS velocity_media,
  ROUND(AVG(vh.sp_planejados), 1)            AS planejados_media,
  MAX(vh.sp_concluidos)                      AS velocity_max,
  MIN(vh.sp_concluidos)                      AS velocity_min,
  SUM(vh.sp_concluidos)                      AS sp_total,
  ROUND(
    CASE WHEN AVG(vh.sp_planejados) > 0
      THEN 100.0 * AVG(vh.sp_concluidos) / AVG(vh.sp_planejados)
    END, 1
  )                                          AS taxa_conclusao_pct
FROM public.velocity_historico vh
WHERE vh.sprint_id IN (
  SELECT id FROM public.sprints
  ORDER BY criado_em DESC
  LIMIT 10
)
GROUP BY vh.projeto_id;
