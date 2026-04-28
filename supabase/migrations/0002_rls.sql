-- 1) Primeiro adiciona o valor 'dev' temporariamente ao enum
ALTER TYPE public.papel_app ADD VALUE IF NOT EXISTS 'dev';

-- 2) Agora converte para 'desenvolvedor'
UPDATE public.usuarios SET perfil = 'desenvolvedor'::public.papel_app WHERE perfil::text = 'dev';
UPDATE public.membros_projeto SET papel = 'desenvolvedor'::public.papel_app WHERE papel::text = 'dev';

-- 3) Remove o valor inválido do enum
ALTER TYPE public.papel_app RENAME TO papel_app_old;
CREATE TYPE public.papel_app AS ENUM ('desenvolvedor', 'admin', 'engenheiro_software', 'gerente_projeto', 'lider_equipe', 'analista_qualidade', 'designer');
ALTER TABLE public.usuarios ALTER COLUMN perfil TYPE public.papel_app USING perfil::public.papel_app;
ALTER TABLE public.membros_projeto ALTER COLUMN papel TYPE public.papel_app USING papel::public.papel_app;
DROP TYPE public.papel_app_old;