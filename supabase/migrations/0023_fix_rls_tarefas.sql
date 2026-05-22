-- 0023_fix_rls_tarefas.sql
-- Corrige políticas de tarefas do 0022.
-- Problema: INSERT falhava quando organizacao_id era NULL em projetos antigos
-- ou quando o usuário era membro do projeto mas não da mesma org direta.
-- Solução: adiciona membros_projeto como terceira condição em todas as políticas.

-- Função auxiliar reutilizável: verifica acesso ao projeto
-- Retorna TRUE se o usuário atual tem acesso ao projeto (org, dono ou membro)
CREATE OR REPLACE FUNCTION public.tem_acesso_projeto(_projeto_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.projetos p
    WHERE p.id = _projeto_id
      AND (
        -- Mesma organização (multi-tenant principal)
        (p.organizacao_id IS NOT NULL AND p.organizacao_id = minha_organizacao_id())
        -- Proprietário direto
        OR p.proprietario_id = auth.uid()
        -- Membro explícito do projeto
        OR EXISTS (
          SELECT 1 FROM public.membros_projeto mp
          WHERE mp.projeto_id = p.id AND mp.usuario_id = auth.uid()
        )
      )
  )
$$;

-- ============================================================
-- Recriar políticas de tarefas usando a função
-- ============================================================
DROP POLICY IF EXISTS "tarefas_select" ON public.tarefas;
DROP POLICY IF EXISTS "tarefas_insert" ON public.tarefas;
DROP POLICY IF EXISTS "tarefas_update" ON public.tarefas;
DROP POLICY IF EXISTS "tarefas_delete" ON public.tarefas;

CREATE POLICY "tarefas_select" ON public.tarefas
  FOR SELECT TO authenticated
  USING (tem_acesso_projeto(projeto_id));

CREATE POLICY "tarefas_insert" ON public.tarefas
  FOR INSERT TO authenticated
  WITH CHECK (tem_acesso_projeto(projeto_id));

CREATE POLICY "tarefas_update" ON public.tarefas
  FOR UPDATE TO authenticated
  USING (tem_acesso_projeto(projeto_id));

CREATE POLICY "tarefas_delete" ON public.tarefas
  FOR DELETE TO authenticated
  USING (tem_acesso_projeto(projeto_id));

-- ============================================================
-- Mesma correção para sprints
-- ============================================================
DROP POLICY IF EXISTS "sprints_select" ON public.sprints;
DROP POLICY IF EXISTS "sprints_insert" ON public.sprints;
DROP POLICY IF EXISTS "sprints_update" ON public.sprints;
DROP POLICY IF EXISTS "sprints_delete" ON public.sprints;

CREATE POLICY "sprints_select" ON public.sprints
  FOR SELECT TO authenticated
  USING (tem_acesso_projeto(projeto_id));

CREATE POLICY "sprints_insert" ON public.sprints
  FOR INSERT TO authenticated
  WITH CHECK (tem_acesso_projeto(projeto_id));

CREATE POLICY "sprints_update" ON public.sprints
  FOR UPDATE TO authenticated
  USING (tem_acesso_projeto(projeto_id));

CREATE POLICY "sprints_delete" ON public.sprints
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = sprints.projeto_id
        AND p.proprietario_id = auth.uid()
    )
  );

-- ============================================================
-- historico_movimentacao
-- ============================================================
DROP POLICY IF EXISTS "hist_select_org" ON public.historico_movimentacao;
DROP POLICY IF EXISTS "hist_insert_org" ON public.historico_movimentacao;

CREATE POLICY "hist_select_org" ON public.historico_movimentacao
  FOR SELECT TO authenticated
  USING (tem_acesso_projeto(projeto_id));

CREATE POLICY "hist_insert_org" ON public.historico_movimentacao
  FOR INSERT TO authenticated
  WITH CHECK (tem_acesso_projeto(projeto_id));

-- ============================================================
-- comentarios
-- ============================================================
DROP POLICY IF EXISTS "comentarios_select" ON public.comentarios;
DROP POLICY IF EXISTS "comentarios_insert" ON public.comentarios;

CREATE POLICY "comentarios_select" ON public.comentarios
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.tarefas t
      WHERE t.id = comentarios.tarefa_id
        AND tem_acesso_projeto(t.projeto_id)
    )
  );

CREATE POLICY "comentarios_insert" ON public.comentarios
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.tarefas t
      WHERE t.id = comentarios.tarefa_id
        AND tem_acesso_projeto(t.projeto_id)
    )
  );

-- ============================================================
-- velocity_historico
-- ============================================================
DROP POLICY IF EXISTS "vel_select_org" ON public.velocity_historico;
DROP POLICY IF EXISTS "vel_write_org"  ON public.velocity_historico;

CREATE POLICY "vel_select_org" ON public.velocity_historico
  FOR SELECT TO authenticated
  USING (tem_acesso_projeto(projeto_id));

CREATE POLICY "vel_write_org" ON public.velocity_historico
  FOR ALL TO authenticated
  USING (tem_acesso_projeto(projeto_id));

-- ============================================================
-- Garantir organizacao_id em projetos que ficaram com NULL
-- (projetos criados antes do 0020)
-- ============================================================
UPDATE public.projetos p
SET organizacao_id = (
  SELECT u.organizacao_id FROM public.usuarios u
  WHERE u.id = p.proprietario_id
)
WHERE p.organizacao_id IS NULL
  AND EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = p.proprietario_id AND u.organizacao_id IS NOT NULL
  );
