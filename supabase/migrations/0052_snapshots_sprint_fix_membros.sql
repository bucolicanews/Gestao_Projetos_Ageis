-- 0052_snapshots_sprint_fix_membros.sql
-- 1) Cria snapshots_sprint para burndown
-- 2) Cria função registrar_snapshot_sprint
-- 3) Corrige FK de sprint_membros.usuario_id para public.usuarios
--    (auth.users impede join via PostgREST)

-- ============================================================
-- 1) Tabela snapshots_sprint
-- ============================================================
CREATE TABLE IF NOT EXISTS public.snapshots_sprint (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  sprint_id       uuid        NOT NULL REFERENCES public.sprints(id) ON DELETE CASCADE,
  data            date        NOT NULL DEFAULT CURRENT_DATE,
  total_tarefas   int         NOT NULL DEFAULT 0,
  restantes       int         NOT NULL DEFAULT 0,
  sp_total        int         NOT NULL DEFAULT 0,
  sp_restantes    int         NOT NULL DEFAULT 0,
  criado_em       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (sprint_id, data)
);

CREATE INDEX IF NOT EXISTS idx_snapshots_sprint_sprint ON public.snapshots_sprint(sprint_id, data);

ALTER TABLE public.snapshots_sprint ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "snap_select_membros" ON public.snapshots_sprint;
CREATE POLICY "snap_select_membros" ON public.snapshots_sprint
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.sprints s
      JOIN public.membros_projeto mp ON mp.projeto_id = s.projeto_id
      WHERE s.id = sprint_id AND mp.usuario_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "snap_write_membros" ON public.snapshots_sprint;
CREATE POLICY "snap_write_membros" ON public.snapshots_sprint
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.sprints s
      JOIN public.membros_projeto mp ON mp.projeto_id = s.projeto_id
      WHERE s.id = sprint_id AND mp.usuario_id = auth.uid()
    )
  );

-- ============================================================
-- 2) Função registrar_snapshot_sprint
-- ============================================================
CREATE OR REPLACE FUNCTION public.registrar_snapshot_sprint(_sprint_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  _total      int;
  _restantes  int;
  _sp_total   int;
  _sp_rest    int;
BEGIN
  SELECT
    COUNT(*)                                                         INTO _total
  FROM public.tarefas
  WHERE sprint_id = _sprint_id;

  SELECT
    COUNT(*) FILTER (WHERE coluna <> 'concluido')                   INTO _restantes
  FROM public.tarefas
  WHERE sprint_id = _sprint_id;

  SELECT
    COALESCE(SUM(pontos), 0)                                        INTO _sp_total
  FROM public.tarefas
  WHERE sprint_id = _sprint_id;

  SELECT
    COALESCE(SUM(pontos) FILTER (WHERE coluna <> 'concluido'), 0)   INTO _sp_rest
  FROM public.tarefas
  WHERE sprint_id = _sprint_id;

  INSERT INTO public.snapshots_sprint (sprint_id, data, total_tarefas, restantes, sp_total, sp_restantes)
  VALUES (_sprint_id, CURRENT_DATE, _total, _restantes, _sp_total, _sp_rest)
  ON CONFLICT (sprint_id, data) DO UPDATE
    SET total_tarefas = EXCLUDED.total_tarefas,
        restantes     = EXCLUDED.restantes,
        sp_total      = EXCLUDED.sp_total,
        sp_restantes  = EXCLUDED.sp_restantes,
        criado_em     = now();
END;
$$;

-- ============================================================
-- 3) Corrigir FK sprint_membros.usuario_id → public.usuarios
--    (era auth.users — PostgREST não consegue resolver o join)
-- ============================================================
ALTER TABLE public.sprint_membros
  DROP CONSTRAINT IF EXISTS sprint_membros_usuario_id_fkey;

ALTER TABLE public.sprint_membros
  ADD CONSTRAINT sprint_membros_usuario_id_fkey
  FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;
