-- 0024_fix_recursao_rls_projetos.sql
-- Corrige recursão infinita entre RLS de projetos e membros_projeto.
-- Causa: proj_select (0020) consulta membros_projeto, e membros_select (0022)
-- consulta projetos → ciclo. Solução: usar tem_acesso_projeto() (SECURITY DEFINER
-- do 0023) que bypassa RLS, quebrando a recursão.

-- ============================================================
-- 1. projetos.proj_select — substituir EXISTS inline por função
-- ============================================================
DROP POLICY IF EXISTS "proj_select" ON public.projetos;

CREATE POLICY "proj_select" ON public.projetos
  FOR SELECT TO authenticated
  USING (tem_acesso_projeto(id));

-- ============================================================
-- 2. membros_projeto.membros_select — mesma técnica
-- ============================================================
DROP POLICY IF EXISTS "membros_select" ON public.membros_projeto;

CREATE POLICY "membros_select" ON public.membros_projeto
  FOR SELECT TO authenticated
  USING (tem_acesso_projeto(projeto_id));

-- ============================================================
-- 3. proj_update — manter critério mas sem consultar membros_projeto inline
--    (membros admin/dev podem editar). Permitido via função SECURITY DEFINER auxiliar.
-- ============================================================
CREATE OR REPLACE FUNCTION public.pode_editar_projeto(_projeto_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.projetos p
    WHERE p.id = _projeto_id
      AND (
        p.proprietario_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM public.membros_projeto mp
          WHERE mp.projeto_id = p.id
            AND mp.usuario_id = auth.uid()
            AND mp.papel IN ('admin', 'desenvolvedor')
        )
      )
  )
$$;

DROP POLICY IF EXISTS "proj_update" ON public.projetos;

CREATE POLICY "proj_update" ON public.projetos
  FOR UPDATE TO authenticated
  USING (pode_editar_projeto(id));
