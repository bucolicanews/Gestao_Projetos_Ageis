-- Tabela de convites para o projeto
CREATE TABLE IF NOT EXISTS public.convites_projeto (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  projeto_id uuid NOT NULL REFERENCES public.projetos(id) ON DELETE CASCADE,
  email text NOT NULL,
  token text NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
  papel papel_app DEFAULT 'desenvolvedor',
  convidado_por uuid REFERENCES auth.users(id),
  criado_em timestamptz DEFAULT now(),
  expira_em timestamptz DEFAULT (now() + interval '7 days'),
  usado_em timestamptz
);

-- Habilitar RLS
ALTER TABLE public.convites_projeto ENABLE ROW LEVEL SECURITY;

-- Apenas administradores do projeto podem criar/ver convites
DROP POLICY IF EXISTS "admin_gerencia_convites" ON public.convites_projeto;
CREATE POLICY "admin_gerencia_convites" ON public.convites_projeto
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.membros_projeto
      WHERE projeto_id = convites_projeto.projeto_id 
      AND usuario_id = auth.uid() 
      AND papel::text IN ('admin', 'desenvolvedor')
    )
  );

-- Permitir que qualquer pessoa verifique um convite pelo token (para a tela de aceite)
CREATE POLICY "publico_ve_convite_por_token" ON public.convites_projeto
  FOR SELECT TO anon, authenticated
  USING (usado_em IS NULL AND expira_em > now());

-- Índice para busca rápida de tokens
CREATE INDEX idx_convites_token ON public.convites_projeto(token);