-- 0035_config_notificacoes.sql
-- Substitui múltiplos webhooks por URL única + prefixo
-- Adiciona configurações de timing de notificações

-- Remove chaves antigas de webhook múltiplo
DELETE FROM public.configuracoes_sistema
  WHERE chave IN (
    'n8n_webhook_mensagem',
    'n8n_webhook_vencimento_iminente',
    'n8n_webhook_dia_vencimento',
    'n8n_webhook_apos_vencimento',
    'n8n_webhook_confirmacao'
  );

-- Insere novas chaves
INSERT INTO public.configuracoes_sistema (chave, valor) VALUES
  -- Webhook único + prefixo
  ('n8n_webhook_url',           ''),
  ('n8n_prefixo_evento',        'PROJETO_'),

  -- Timing antes do vencimento
  ('notif_dias_antes',          '7'),

  -- No dia do vencimento
  ('notif_no_vencimento',       'true'),

  -- Após vencimento
  ('notif_apos_dias',           '3'),

  -- Repetição após vencimento
  ('notif_repetir_vezes',       '3'),
  ('notif_repetir_intervalo',   '7')
ON CONFLICT (chave) DO NOTHING;
