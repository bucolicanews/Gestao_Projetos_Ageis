-- 0059_anotacoes_projeto.sql
-- Nova tabela para anotações por projeto (notas, decisões, contexto)
-- Necessária para import/export completo de projetos em JSON

CREATE TABLE IF NOT EXISTS public.anotacoes_projeto (
    id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    projeto_id  uuid        NOT NULL REFERENCES public.projetos(id) ON DELETE CASCADE,
    titulo      text        NOT NULL,
    conteudo    text,
    criado_por  uuid        REFERENCES public.usuarios(id) ON DELETE SET NULL,
    criado_em   timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_anotacoes_projeto_id
    ON public.anotacoes_projeto(projeto_id);

CREATE INDEX IF NOT EXISTS idx_anotacoes_criado_por
    ON public.anotacoes_projeto(criado_por);

ALTER TABLE public.anotacoes_projeto ENABLE ROW LEVEL SECURITY;

-- Membros da org veem anotações dos projetos da org
CREATE POLICY "anotacoes_select" ON public.anotacoes_projeto
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = anotacoes_projeto.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

-- Membros da org podem criar anotações
CREATE POLICY "anotacoes_insert" ON public.anotacoes_projeto
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = anotacoes_projeto.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

-- Membros da org podem editar qualquer anotação do projeto
CREATE POLICY "anotacoes_update" ON public.anotacoes_projeto
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projetos p
      WHERE p.id = anotacoes_projeto.projeto_id
        AND (p.organizacao_id = minha_organizacao_id() OR p.proprietario_id = auth.uid())
    )
  );

-- Apenas criador ou dono do projeto pode deletar
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

-- Trigger atualiza atualizado_em automaticamente
CREATE OR REPLACE FUNCTION public.set_anotacao_atualizado_em()
RETURNS TRIGGER AS $$
BEGIN
  NEW.atualizado_em = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER anotacoes_projeto_atualizado_em
  BEFORE UPDATE ON public.anotacoes_projeto
  FOR EACH ROW EXECUTE FUNCTION public.set_anotacao_atualizado_em();

NOTIFY pgrst, 'reload schema';
