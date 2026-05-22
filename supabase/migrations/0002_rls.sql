-- Redefine papel_app: remove 'visualizador', adiciona papéis de TI.
-- Estratégia: converter colunas para TEXT → DROP TYPE CASCADE → recriar.
-- CASCADE remove defaults tipados e quaisquer outros objetos menores restantes.

-- 1) Dropar função que usa papel_app na assinatura
DROP FUNCTION IF EXISTS public.tem_papel(uuid, public.papel_app);

-- 2) Converter todas as colunas que usam papel_app para TEXT
ALTER TABLE public.usuarios ALTER COLUMN perfil TYPE TEXT;
ALTER TABLE public.membros_projeto ALTER COLUMN papel TYPE TEXT;
ALTER TABLE public.papeis_usuario ALTER COLUMN papel TYPE TEXT;

-- 3) DROP com CASCADE — remove defaults tipados e qualquer dependência residual
--    (colunas já são TEXT, então não serão dropadas)
DROP TYPE IF EXISTS public.papel_app CASCADE;

-- 4) Recriar com os papéis corretos
CREATE TYPE public.papel_app AS ENUM (
  'desenvolvedor',
  'admin',
  'engenheiro_software',
  'gerente_projeto',
  'lider_equipe',
  'analista_qualidade',
  'designer'
);

-- 5) Converter colunas de volta (TEXT → ENUM é cast válido) e restaurar defaults
ALTER TABLE public.usuarios ALTER COLUMN perfil TYPE public.papel_app USING perfil::public.papel_app;
ALTER TABLE public.usuarios ALTER COLUMN perfil SET DEFAULT 'desenvolvedor';

ALTER TABLE public.membros_projeto ALTER COLUMN papel TYPE public.papel_app USING papel::public.papel_app;
ALTER TABLE public.membros_projeto ALTER COLUMN papel SET DEFAULT 'desenvolvedor';

ALTER TABLE public.papeis_usuario ALTER COLUMN papel TYPE public.papel_app USING papel::public.papel_app;

-- 6) Recriar tem_papel com o tipo atualizado
CREATE OR REPLACE FUNCTION public.tem_papel(_usuario_id uuid, _papel papel_app)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.papeis_usuario
    WHERE usuario_id = _usuario_id AND papel = _papel
  )
$$;
