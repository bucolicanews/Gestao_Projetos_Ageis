-- 0039_pagamentos_public_read.sql
-- View SECURITY DEFINER expõe apenas campos não-sensíveis da config de pagamentos
-- Tokens PagBank/Stripe NUNCA chegam ao frontend

CREATE OR REPLACE VIEW public.config_gateways_publico
WITH (security_invoker = false)  -- SECURITY DEFINER: lê com privilégio do definer
AS
SELECT
  pagbank_enabled,
  pagbank_env,
  pagbank_pass_fees_to_customer,
  pagbank_pix_fee_fixed,
  pagbank_pix_fee_percentage,
  pagbank_card_fee_fixed,
  pagbank_card_fee_percentage,
  stripe_enabled,
  stripe_env,
  stripe_pass_fees_to_customer,
  stripe_fee_fixed,
  stripe_fee_percentage,
  pix_key,
  pix_name,
  pix_city
FROM public.configuracoes_pagamentos;

-- Usuários autenticados podem ler SOMENTE a view (sem acesso à tabela base)
GRANT SELECT ON public.config_gateways_publico TO authenticated;
GRANT SELECT ON public.config_gateways_publico TO anon;
