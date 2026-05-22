-- 0022_rls_isolamento_org.sql
-- Corrige isolamento multi-tenant.
-- Tabelas tarefas/sprints não tinham RLS habilitado → qualquer usuário autenticado via tudo.
-- historico_movimentacao tinha USING(true) aberto (0006).
-- Todos os recursos agora escopados por projetos.organizacao_id = minha_organizacao_id().

-- ============================================================
-- 1. TAREFAS
-- ============================================================
ALTER TABLE public.tarefas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Membros podem atualizar tarefas do projeto" ON public.tarefas;
DROP POLICY IF EXISTS "tarefas_select"  ON public.tarefas;
DROP POLICY IF EXISTS "tarefas_insert"  ON public.tarefas;
DROP POLICY IF EXISTS "tarefas_update"  ON public.tarefas;
DROP POLICY IF EXISTS "tarefas_delete"  ON public.tarefas;

CREATE POLICY "tarefas_select" ON public.tarefas
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = tarefas.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

CREATE POLICY "tarefas_insert" ON public.tarefas
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = tarefas.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

CREATE POLICY "tarefas_update" ON public.tarefas
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = tarefas.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

CREATE POLICY "tarefas_delete" ON public.tarefas
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = tarefas.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

-- ============================================================
-- 2. SPRINTS
-- ============================================================
ALTER TABLE public.sprints ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sprints_select" ON public.sprints;
DROP POLICY IF EXISTS "sprints_insert" ON public.sprints;
DROP POLICY IF EXISTS "sprints_update" ON public.sprints;
DROP POLICY IF EXISTS "sprints_delete" ON public.sprints;

CREATE POLICY "sprints_select" ON public.sprints
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = sprints.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

CREATE POLICY "sprints_insert" ON public.sprints
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = sprints.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

CREATE POLICY "sprints_update" ON public.sprints
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = sprints.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

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
-- 3. HISTORICO_MOVIMENTACAO — remove políticas abertas do 0006
-- ============================================================
DROP POLICY IF EXISTS "Membros veem historico"      ON public.historico_movimentacao;
DROP POLICY IF EXISTS "Sistema insere historico"    ON public.historico_movimentacao;
DROP POLICY IF EXISTS "hist_select_membros"         ON public.historico_movimentacao;
DROP POLICY IF EXISTS "hist_insert_sistema"         ON public.historico_movimentacao;
DROP POLICY IF EXISTS "hist_select_org"             ON public.historico_movimentacao;
DROP POLICY IF EXISTS "hist_insert_org"             ON public.historico_movimentacao;

CREATE POLICY "hist_select_org" ON public.historico_movimentacao
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = historico_movimentacao.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

CREATE POLICY "hist_insert_org" ON public.historico_movimentacao
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = historico_movimentacao.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

-- ============================================================
-- 4. COMENTARIOS
-- ============================================================
ALTER TABLE public.comentarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "comentarios_select" ON public.comentarios;
DROP POLICY IF EXISTS "comentarios_insert" ON public.comentarios;
DROP POLICY IF EXISTS "comentarios_update" ON public.comentarios;
DROP POLICY IF EXISTS "comentarios_delete" ON public.comentarios;

CREATE POLICY "comentarios_select" ON public.comentarios
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.tarefas t
      JOIN public.projetos p ON p.id = t.projeto_id
      WHERE t.id = comentarios.tarefa_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

CREATE POLICY "comentarios_insert" ON public.comentarios
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.tarefas t
      JOIN public.projetos p ON p.id = t.projeto_id
      WHERE t.id = comentarios.tarefa_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

CREATE POLICY "comentarios_update" ON public.comentarios
  FOR UPDATE TO authenticated
  USING (autor_id = auth.uid());

CREATE POLICY "comentarios_delete" ON public.comentarios
  FOR DELETE TO authenticated
  USING (autor_id = auth.uid());

-- ============================================================
-- 5. MEMBROS_PROJETO — garantir isolamento
-- ============================================================
ALTER TABLE public.membros_projeto ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "membros_select" ON public.membros_projeto;
DROP POLICY IF EXISTS "membros_insert" ON public.membros_projeto;
DROP POLICY IF EXISTS "membros_delete" ON public.membros_projeto;
-- nomes antigos:
DROP POLICY IF EXISTS "Membros podem ver equipe"             ON public.membros_projeto;
DROP POLICY IF EXISTS "Proprietário gerencia membros"        ON public.membros_projeto;

CREATE POLICY "membros_select" ON public.membros_projeto
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = membros_projeto.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

CREATE POLICY "membros_insert" ON public.membros_projeto
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = membros_projeto.projeto_id
        AND p.proprietario_id = auth.uid()
    )
  );

CREATE POLICY "membros_update" ON public.membros_projeto
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = membros_projeto.projeto_id
        AND p.proprietario_id = auth.uid()
    )
  );

CREATE POLICY "membros_delete" ON public.membros_projeto
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = membros_projeto.projeto_id
        AND p.proprietario_id = auth.uid()
    )
  );

-- ============================================================
-- 6. VELOCITY_HISTORICO — upgrade de eh_membro para org-scoped
-- ============================================================
DROP POLICY IF EXISTS "vel_select_membros" ON public.velocity_historico;
DROP POLICY IF EXISTS "vel_select_org"     ON public.velocity_historico;
DROP POLICY IF EXISTS "vel_write_org"      ON public.velocity_historico;

CREATE POLICY "vel_select_org" ON public.velocity_historico
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = velocity_historico.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

CREATE POLICY "vel_write_org" ON public.velocity_historico
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = velocity_historico.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );
