-- 0060_rls_excluir_projeto_papel.sql
-- Atualiza política de DELETE em projetos para respeitar permissão
-- 'excluir_projeto' definida no papel do membro, além do proprietário.

DROP POLICY IF EXISTS "proj_delete" ON public.projetos;
DROP POLICY IF EXISTS "projetos_delete" ON public.projetos;

CREATE POLICY "projetos_delete" ON public.projetos
  FOR DELETE TO authenticated
  USING (
    -- Dono sempre pode excluir
    proprietario_id = auth.uid()
    OR
    -- Membro com permissão 'excluir_projeto' no papel do projeto
    EXISTS (
      SELECT 1
      FROM public.membros_projeto mp
      JOIN public.papeis_projeto pp ON pp.id = mp.papel
      WHERE mp.projeto_id = projetos.id
        AND mp.usuario_id  = auth.uid()
        AND 'excluir_projeto' = ANY(pp.permissoes)
        -- Ignora registros legados onde papel não é UUID válido
        AND mp.papel ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    )
  );

NOTIFY pgrst, 'reload schema';
