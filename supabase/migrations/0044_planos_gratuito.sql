-- 0044_planos_gratuito.sql
-- Plano gratuito: nenhum método de pagamento exigido na assinatura.
ALTER TABLE public.planos
  ADD COLUMN IF NOT EXISTS gratuito boolean NOT NULL DEFAULT false;
