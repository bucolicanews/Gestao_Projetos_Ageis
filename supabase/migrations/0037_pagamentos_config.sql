-- 0037_pagamentos_config.sql
-- Tabela singleton de configurações de métodos de pagamento (develop_admin only)

CREATE TABLE IF NOT EXISTS public.configuracoes_pagamentos (
  id                              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  -- PagBank
  pagbank_enabled                 boolean   DEFAULT false,
  pagbank_env                     text      DEFAULT 'sandbox',
  pagbank_token_sandbox           text      DEFAULT '',
  pagbank_token_producao          text      DEFAULT '',
  pagbank_pass_fees_to_customer   boolean   DEFAULT false,
  pagbank_pix_fee_fixed           numeric   DEFAULT 0.99,
  pagbank_pix_fee_percentage      numeric   DEFAULT 0,
  pagbank_card_fee_fixed          numeric   DEFAULT 0.39,
  pagbank_card_fee_percentage     numeric   DEFAULT 4.99,
  -- Stripe
  stripe_enabled                  boolean   DEFAULT false,
  stripe_env                      text      DEFAULT 'test',
  stripe_secret_key               text      DEFAULT '',
  stripe_secret_key_test          text      DEFAULT '',
  stripe_webhook_secret           text      DEFAULT '',
  stripe_webhook_secret_test      text      DEFAULT '',
  stripe_pass_fees_to_customer    boolean   DEFAULT false,
  stripe_fee_percentage           numeric   DEFAULT 3.99,
  stripe_fee_fixed                numeric   DEFAULT 0.39,
  -- PIX Manual
  pix_key                         text      DEFAULT '',
  pix_name                        text      DEFAULT '',
  pix_city                        text      DEFAULT '',
  atualizado_em                   timestamptz DEFAULT now()
);

-- Insere o registro singleton
INSERT INTO public.configuracoes_pagamentos DEFAULT VALUES;

-- RLS
ALTER TABLE public.configuracoes_pagamentos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pagcfg_select" ON public.configuracoes_pagamentos
  FOR SELECT USING (public.is_develop_admin());

CREATE POLICY "pagcfg_update" ON public.configuracoes_pagamentos
  FOR UPDATE USING (public.is_develop_admin());

-- Edge Functions precisam ler via service_role — sem RLS
-- (service_role bypassa RLS por padrão)
