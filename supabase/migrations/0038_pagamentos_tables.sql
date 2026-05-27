-- 0038_pagamentos_tables.sql
-- Tabelas de rastreamento de pagamentos PagBank e Stripe

CREATE TABLE IF NOT EXISTS public.pagbank_payments (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id           uuid REFERENCES public.organizacoes(id) ON DELETE CASCADE,
  plano_id         uuid REFERENCES public.planos(id),
  pagbank_order_id text UNIQUE,
  reference_id     text,
  status           text    DEFAULT 'PENDING',
  amount           numeric NOT NULL,
  payment_method   text,           -- 'pix' | 'CREDIT_CARD'
  qr_code          text,
  qr_code_text     text,
  checkout_link    text,
  criado_em        timestamptz DEFAULT now(),
  atualizado_em    timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.stripe_payments (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id            uuid REFERENCES public.organizacoes(id) ON DELETE CASCADE,
  plano_id          uuid REFERENCES public.planos(id),
  stripe_session_id text UNIQUE,
  status            text    DEFAULT 'pending',
  amount            numeric NOT NULL,
  checkout_url      text,
  criado_em         timestamptz DEFAULT now()
);

-- RLS
ALTER TABLE public.pagbank_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stripe_payments  ENABLE ROW LEVEL SECURITY;

-- develop_admin — acesso total
CREATE POLICY "pagbank_admin_all" ON public.pagbank_payments
  FOR ALL USING (public.is_develop_admin());

CREATE POLICY "stripe_admin_all" ON public.stripe_payments
  FOR ALL USING (public.is_develop_admin());

-- Org vê apenas seus próprios pagamentos
CREATE POLICY "pagbank_org_select" ON public.pagbank_payments
  FOR SELECT USING (
    org_id IN (
      SELECT id FROM public.organizacoes WHERE dono_id = auth.uid()
    )
  );

CREATE POLICY "stripe_org_select" ON public.stripe_payments
  FOR SELECT USING (
    org_id IN (
      SELECT id FROM public.organizacoes WHERE dono_id = auth.uid()
    )
  );
