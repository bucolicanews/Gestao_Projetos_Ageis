-- 1) Adicionar os novos papéis ao tipo existente (papel_app)
-- 1) Limpeza total e redefinição do ENUM papel_app
-- Para limpar as opções, precisamos remover as dependências temporariamente

-- Garante que a coluna perfil exista como texto antes da redefinição do tipo
ALTER TABLE public.usuarios ADD COLUMN IF NOT EXISTS perfil text;

-- REMOVE POLÍTICAS QUE DEPENDEM DA COLUNA PAPEL OU PERFIL
DROP POLICY IF EXISTS "admin_gerencia_convites" ON public.convites_projeto;

DROP FUNCTION IF EXISTS public.tem_papel(uuid, public.papel_app);

ALTER TABLE public.usuarios ALTER COLUMN perfil TYPE TEXT;
ALTER TABLE public.membros_projeto ALTER COLUMN papel TYPE TEXT;
ALTER TABLE public.convites_projeto ALTER COLUMN papel TYPE TEXT;
ALTER TABLE public.papeis_usuario ALTER COLUMN papel TYPE TEXT;

-- Remove o tipo antigo (colunas já são TEXT, CASCADE não derruba nenhuma coluna)
DROP TYPE IF EXISTS public.papel_app CASCADE;

-- Cria o tipo exatamente com as opções solicitadas
CREATE TYPE public.papel_app AS ENUM (
  'desenvolvedor',
  'admin',
  'engenheiro_software',
  'gerente_projeto',
  'lider_equipe',
  'analista_qualidade',
  'designer'
);

-- Converte as colunas de volta para o novo ENUM
ALTER TABLE public.usuarios ALTER COLUMN perfil TYPE public.papel_app USING perfil::public.papel_app;
ALTER TABLE public.usuarios ALTER COLUMN perfil SET DEFAULT 'desenvolvedor';
ALTER TABLE public.membros_projeto ALTER COLUMN papel TYPE public.papel_app USING papel::public.papel_app;
ALTER TABLE public.membros_projeto ALTER COLUMN papel SET DEFAULT 'desenvolvedor';
ALTER TABLE public.papeis_usuario ALTER COLUMN papel TYPE public.papel_app USING papel::public.papel_app;
ALTER TABLE public.convites_projeto ALTER COLUMN papel TYPE public.papel_app USING papel::public.papel_app;

-- 2) RECRIAR POLÍTICAS REMOVIDAS
-- Agora com o novo tipo ENUM devidamente registrado
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

-- 3) Comentário para documentação
COMMENT ON TYPE public.papel_app IS 'Hierarquia oficial: desenvolvedor, admin, engenheiro_software, gerente_projeto, lider_equipe, analista_qualidade e designer.';

-- 4) Recriar tem_papel (DROP TYPE CASCADE a derrubou)
CREATE OR REPLACE FUNCTION public.tem_papel(_usuario_id uuid, _papel papel_app)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.papeis_usuario
    WHERE usuario_id = _usuario_id AND papel = _papel
  )
$$;