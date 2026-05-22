-- Primeiro: corrige valores inválidos que podem ter ficado na tabela
-- Como 'dev' não existe no enum, precisamos converter para texto primeiro
DO $$
BEGIN
    -- Atualiza via texto para evitar erro de enum
    UPDATE public.usuarios SET perfil = 'desenvolvedor'::public.papel_app 
    WHERE perfil::text = 'dev';
    
    UPDATE public.membros_projeto SET papel = 'desenvolvedor'::public.papel_app 
    WHERE papel::text = 'dev';
END $$;

-- 1) Adiciona a coluna perfil na tabela de usuários
-- 1) Garante que a coluna perfil exista com o tipo correto e valor padrão
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS perfil public.papel_app DEFAULT 'desenvolvedor'::public.papel_app;

-- 2) Atualiza os perfis globais na tabela de usuários
UPDATE public.usuarios 
SET perfil = 'desenvolvedor'::public.papel_app
WHERE LOWER(email) = 'jmokatavares@gmail.com';

UPDATE public.usuarios 
SET perfil = 'gerente_projeto'::public.papel_app
WHERE LOWER(email) LIKE 'jotaconsultoria@outlook%';

-- 3) Sincroniza a tabela de membros do projeto com os novos perfis
UPDATE public.membros_projeto 
SET papel = 'desenvolvedor'::public.papel_app
WHERE usuario_id IN (
    SELECT id FROM public.usuarios WHERE LOWER(email) = 'jmokatavares@gmail.com'
);

UPDATE public.membros_projeto 
SET papel = 'gerente_projeto'::public.papel_app
WHERE usuario_id IN (
    SELECT id FROM public.usuarios WHERE LOWER(email) LIKE 'jotaconsultoria@outlook%'
);

COMMENT ON COLUMN public.usuarios.perfil IS 'Cargo principal/global do usuário no sistema.';

-- 4) Atualiza a função de criação de usuário para incluir o perfil
CREATE OR REPLACE FUNCTION public.handle_novo_usuario()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.usuarios (id, nome, email, perfil)
  VALUES (
    new.id,
    coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)),
    new.email,
    'desenvolvedor'::public.papel_app
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN new;
END;
$$;