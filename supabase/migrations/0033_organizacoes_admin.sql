-- 0033_organizacoes_admin.sql
-- Expande organizacoes para controle admin + tabela configuracoes_sistema (n8n, etc)

-- ============================================================
-- 1. Novas colunas em organizacoes
-- ============================================================
ALTER TABLE public.organizacoes
  ADD COLUMN IF NOT EXISTS status         text        NOT NULL DEFAULT 'ativo',
  ADD COLUMN IF NOT EXISTS vencimento     date,
  ADD COLUMN IF NOT EXISTS telefone       text,
  ADD COLUMN IF NOT EXISTS email_contato  text,
  ADD COLUMN IF NOT EXISTS bloqueado_em   timestamptz,
  ADD COLUMN IF NOT EXISTS bloqueado_motivo text;

-- status: 'ativo' | 'bloqueado' | 'trial' | 'cancelado' | 'vencido'
COMMENT ON COLUMN public.organizacoes.status IS 'ativo | bloqueado | trial | cancelado | vencido';

-- ============================================================
-- 2. Tabela configuracoes_sistema (develop_admin only)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.configuracoes_sistema (
  id        uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  chave     text        UNIQUE NOT NULL,
  valor     text,
  criado_em timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.configuracoes_sistema ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "config_sistema_develop_admin" ON public.configuracoes_sistema;
CREATE POLICY "config_sistema_develop_admin" ON public.configuracoes_sistema
  FOR ALL TO authenticated
  USING (is_develop_admin())
  WITH CHECK (is_develop_admin());

-- Chaves iniciais
INSERT INTO public.configuracoes_sistema (chave, valor) VALUES
  ('n8n_webhook_mensagem',             ''),
  ('n8n_webhook_vencimento_iminente',  ''),
  ('n8n_webhook_dia_vencimento',       ''),
  ('n8n_webhook_apos_vencimento',      ''),
  ('n8n_webhook_confirmacao',          ''),
  ('msg_vencimento_iminente',          'Olá {nome}! Seu plano {plano} vence em {dias} dias. Acesse para renovar.'),
  ('msg_dia_vencimento',               'Olá {nome}! Hoje é o último dia do seu plano {plano}. Renove agora para não perder o acesso.'),
  ('msg_apos_vencimento',              'Olá {nome}! Seu plano {plano} venceu. Entre em contato para reativar.')
ON CONFLICT (chave) DO NOTHING;

-- ============================================================
-- 3. Tabela log_mensagens_org (histórico de mensagens enviadas)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.log_mensagens_org (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id     uuid        NOT NULL REFERENCES public.organizacoes(id) ON DELETE CASCADE,
  tipo       text        NOT NULL DEFAULT 'manual', -- manual | vencimento_iminente | dia_vencimento | apos_vencimento
  mensagem   text        NOT NULL,
  enviado_por uuid       REFERENCES auth.users(id),
  status     text        NOT NULL DEFAULT 'enviado', -- enviado | falhou | confirmado
  enviado_em timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.log_mensagens_org ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "log_mensagens_develop_admin" ON public.log_mensagens_org;
CREATE POLICY "log_mensagens_develop_admin" ON public.log_mensagens_org
  FOR ALL TO authenticated
  USING (is_develop_admin())
  WITH CHECK (is_develop_admin());
