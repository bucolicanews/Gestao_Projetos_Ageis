-- 0036_webhook_teste_producao.sql
-- Separa URL de teste e produção do n8n

INSERT INTO public.configuracoes_sistema (chave, valor) VALUES
  ('n8n_webhook_url_teste',    ''),
  ('n8n_webhook_url_producao', ''),
  ('n8n_modo',                 'teste')
ON CONFLICT (chave) DO NOTHING;

-- Remove chave genérica antiga (migrada para as duas específicas)
DELETE FROM public.configuracoes_sistema WHERE chave = 'n8n_webhook_url';
