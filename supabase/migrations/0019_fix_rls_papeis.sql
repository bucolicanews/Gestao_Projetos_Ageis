-- 0019_fix_rls_papeis.sql
-- Garante políticas corretas em papeis_projeto (idempotente)

DROP POLICY IF EXISTS "autenticados_leem_papeis"    ON public.papeis_projeto;
DROP POLICY IF EXISTS "autenticados_gerenciam_papeis" ON public.papeis_projeto;
DROP POLICY IF EXISTS "papeis_select"  ON public.papeis_projeto;
DROP POLICY IF EXISTS "papeis_insert"  ON public.papeis_projeto;
DROP POLICY IF EXISTS "papeis_update"  ON public.papeis_projeto;
DROP POLICY IF EXISTS "papeis_delete"  ON public.papeis_projeto;

CREATE POLICY "papeis_select"
  ON public.papeis_projeto FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "papeis_insert"
  ON public.papeis_projeto FOR INSERT
  TO authenticated WITH CHECK (true);

CREATE POLICY "papeis_update"
  ON public.papeis_projeto FOR UPDATE
  TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "papeis_delete"
  ON public.papeis_projeto FOR DELETE
  TO authenticated USING (true);
