-- Migration: adicionar coluna dias_trial na tabela planos

ALTER TABLE public.planos
ADD COLUMN IF NOT EXISTS dias_trial INTEGER DEFAULT 0;

COMMENT ON COLUMN public.planos.dias_trial IS 'Quantidade de dias de trial do plano';

NOTIFY pgrst, 'reload schema';