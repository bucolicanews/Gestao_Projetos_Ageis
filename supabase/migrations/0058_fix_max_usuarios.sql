-- 0058_fix_max_usuarios.sql
-- max_usuarios não foi aplicado em 0040 no remoto; 0057 corrigiu dias_trial mas esqueceu esta coluna
ALTER TABLE public.planos
  ADD COLUMN IF NOT EXISTS max_usuarios integer DEFAULT 0;  -- 0 = ilimitado

-- Atualiza planos existentes com valores padrão
UPDATE public.planos SET max_usuarios = 5   WHERE titulo = 'Starter'   AND max_usuarios IS NULL;
UPDATE public.planos SET max_usuarios = 20  WHERE titulo = 'Pro'       AND max_usuarios IS NULL;
UPDATE public.planos SET max_usuarios = 0   WHERE titulo = 'Enterprise' AND max_usuarios IS NULL;

NOTIFY pgrst, 'reload schema';
