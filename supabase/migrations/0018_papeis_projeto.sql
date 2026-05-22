-- 0018_papeis_projeto.sql
-- Flexibiliza papel em membros_projeto (de enum para text)
-- Cria tabela de papéis/cargos gerenciáveis

-- 1. Dropar política dependente da coluna papel antes de alterar
DROP POLICY IF EXISTS "admin_gerencia_convites" ON public.convites_projeto;

-- 2. Alterar coluna papel em membros_projeto para text
ALTER TABLE public.membros_projeto
  ALTER COLUMN papel TYPE text;

-- 3. Recriar política sem cast (papel já é text agora)
CREATE POLICY "admin_gerencia_convites" ON public.convites_projeto
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.membros_projeto
      WHERE projeto_id = convites_projeto.projeto_id
        AND usuario_id = auth.uid()
        AND papel IN ('admin', 'desenvolvedor')
    )
  );

-- 4. Criar tabela de papéis disponíveis
CREATE TABLE IF NOT EXISTS public.papeis_projeto (
  id        uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  nome      text        NOT NULL,
  descricao text,
  cor       text        NOT NULL DEFAULT '#6366f1',
  criado_em timestamptz NOT NULL DEFAULT now()
);

-- 5. RLS
ALTER TABLE public.papeis_projeto ENABLE ROW LEVEL SECURITY;

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

-- 6. Seed: papéis padrão
INSERT INTO public.papeis_projeto (nome, descricao, cor) VALUES
  ('Desenvolvedor',      'Desenvolvimento geral',               '#6366f1'),
  ('Dev Frontend',       'Desenvolvimento de interface',        '#3b82f6'),
  ('Dev Backend',        'Desenvolvimento servidor e APIs',     '#8b5cf6'),
  ('Dev Mobile',         'Desenvolvimento mobile',              '#06b6d4'),
  ('DevOps',             'Infraestrutura e CI/CD',              '#f59e0b'),
  ('Designer UX/UI',     'Design de interface e experiência',   '#ec4899'),
  ('QA / Testes',        'Qualidade e testes',                  '#10b981'),
  ('Product Owner',      'Responsável pelo produto',            '#f97316'),
  ('Scrum Master',       'Facilitador ágil',                    '#14b8a6'),
  ('Gerente de Projeto', 'Gestão e coordenação',                '#ef4444'),
  ('Analista',           'Análise de requisitos',               '#84cc16'),
  ('Administrador',      'Acesso total ao projeto',             '#1e293b'),
  ('Visualizador',       'Apenas leitura',                      '#94a3b8');
