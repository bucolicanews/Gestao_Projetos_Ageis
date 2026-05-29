-- 0062_garantir_anotacoes_projeto.sql
-- 0059 foi marcada como aplicada mas o CREATE TABLE pode ter sido
-- revertido junto com o erro da 0060. Recria com IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS public.anotacoes_projeto (
    id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    projeto_id    uuid        NOT NULL REFERENCES public.projetos(id) ON DELETE CASCADE,
    titulo        text        NOT NULL,
    conteudo      text,
    criado_por    uuid        REFERENCES public.usuarios(id) ON DELETE SET NULL,
    criado_em     timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_anotacoes_projeto_id
    ON public.anotacoes_projeto(projeto_id);

CREATE INDEX IF NOT EXISTS idx_anotacoes_criado_por
    ON public.anotacoes_projeto(criado_por);

-- RLS (DROP IF EXISTS para evitar duplicata se 0059 rodou parcialmente)
ALTER TABLE public.anotacoes_projeto ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anotacoes_select" ON public.anotacoes_projeto;
DROP POLICY IF EXISTS "anotacoes_insert" ON public.anotacoes_projeto;
DROP POLICY IF EXISTS "anotacoes_update" ON public.anotacoes_projeto;
DROP POLICY IF EXISTS "anotacoes_delete" ON public.anotacoes_projeto;

CREATE POLICY "anotacoes_select" ON public.anotacoes_projeto
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = anotacoes_projeto.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

CREATE POLICY "anotacoes_insert" ON public.anotacoes_projeto
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = anotacoes_projeto.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

CREATE POLICY "anotacoes_update" ON public.anotacoes_projeto
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = anotacoes_projeto.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

CREATE POLICY "anotacoes_delete" ON public.anotacoes_projeto
  FOR DELETE TO authenticated
  USING (
    criado_por = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = anotacoes_projeto.projeto_id
        AND p.proprietario_id = auth.uid()
    )
  );

-- Trigger atualiza atualizado_em
CREATE OR REPLACE FUNCTION public.set_anotacao_atualizado_em()
RETURNS TRIGGER AS $$
BEGIN
  NEW.atualizado_em = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS anotacoes_projeto_atualizado_em ON public.anotacoes_projeto;
CREATE TRIGGER anotacoes_projeto_atualizado_em
  BEFORE UPDATE ON public.anotacoes_projeto
  FOR EACH ROW EXECUTE FUNCTION public.set_anotacao_atualizado_em();

NOTIFY pgrst, 'reload schema';
