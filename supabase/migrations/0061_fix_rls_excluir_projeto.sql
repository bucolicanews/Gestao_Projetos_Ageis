-- 0061_fix_rls_excluir_projeto.sql
-- Corrige 0060: mp.papel é text mas pp.id é uuid → cast direto no JOIN falha.
-- Solução: subquery filtra apenas registros com papel UUID válido antes do cast.

DROP POLICY IF EXISTS "projetos_delete" ON public.projetos;

CREATE POLICY "projetos_delete" ON public.projetos
  FOR DELETE TO authenticated
  USING (
    proprietario_id = auth.uid()
    OR
    EXISTS (
      SELECT 1
      FROM (
        SELECT mp.projeto_id,
               mp.usuario_id,
               mp.papel::uuid AS papel_uuid
        FROM   public.membros_projeto mp
        WHERE  mp.papel ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      ) mp_valido
      JOIN public.papeis_projeto pp ON pp.id = mp_valido.papel_uuid
      WHERE mp_valido.projeto_id = projetos.id
        AND mp_valido.usuario_id = auth.uid()
        AND 'excluir_projeto' = ANY(pp.permissoes)
    )
  );

NOTIFY pgrst, 'reload schema';
