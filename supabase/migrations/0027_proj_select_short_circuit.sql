-- 0027_proj_select_short_circuit.sql
-- proj_select via tem_acesso_projeto() (SECURITY DEFINER) falhava ao avaliar
-- INSERT...RETURNING porque a função não enxerga a row em buffer da TX atual.
-- Solução: short-circuit inline para checks diretos (proprietário, mesma org),
-- delegando à função SECURITY DEFINER só o caso "membro via membros_projeto"
-- (necessário pra quebrar recursão com membros_select).

DROP POLICY IF EXISTS "proj_select" ON public.projetos;

CREATE POLICY "proj_select" ON public.projetos
  FOR SELECT TO authenticated
  USING (
    proprietario_id = auth.uid()
    OR (organizacao_id IS NOT NULL AND organizacao_id = minha_organizacao_id())
    OR tem_acesso_projeto(id)
  );
