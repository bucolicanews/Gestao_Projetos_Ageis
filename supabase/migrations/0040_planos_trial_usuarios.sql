-- 0040_planos_trial_usuarios.sql
ALTER TABLE public.planos
  ADD COLUMN IF NOT EXISTS dias_trial   integer DEFAULT 14,
  ADD COLUMN IF NOT EXISTS max_usuarios integer DEFAULT 0;  -- 0 = ilimitado

-- Atualiza seed com valores padrão para planos existentes
UPDATE public.planos SET dias_trial = 14, max_usuarios = 5   WHERE titulo = 'Starter';
UPDATE public.planos SET dias_trial = 14, max_usuarios = 20  WHERE titulo = 'Pro';
UPDATE public.planos SET dias_trial = 14, max_usuarios = 0   WHERE titulo = 'Enterprise';
