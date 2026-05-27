-- Migration 001 — Tabela planos
-- Executar no Supabase SQL Editor

CREATE TABLE IF NOT EXISTS planos (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo       text        NOT NULL,
  descricao    text,
  imagem_url   text,
  preco        numeric(10,2) NOT NULL DEFAULT 0,
  recursos     jsonb       NOT NULL DEFAULT '[]',  -- array de strings ["Feature A", "Feature B"]
  ativo        boolean     NOT NULL DEFAULT true,
  criado_em    timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);

-- Trigger para atualizar atualizado_em automaticamente
CREATE OR REPLACE FUNCTION atualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.atualizado_em = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER planos_atualizado_em
  BEFORE UPDATE ON planos
  FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- RLS
ALTER TABLE planos ENABLE ROW LEVEL SECURITY;

-- develop_admin: acesso total (usando campo perfil da tabela usuarios)
CREATE POLICY "develop_admin lê tudo" ON planos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid() AND perfil = 'develop_admin'
    )
  );

CREATE POLICY "develop_admin escreve tudo" ON planos
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid() AND perfil = 'develop_admin'
    )
  );

-- Qualquer usuário autenticado pode ler planos ativos (para pricing page)
CREATE POLICY "usuarios leem planos ativos" ON planos
  FOR SELECT USING (ativo = true);

-- Dados iniciais de exemplo
INSERT INTO planos (titulo, descricao, preco, recursos) VALUES
  ('Starter', 'Ideal para times pequenos', 49.90, '["Até 3 projetos", "5 usuários", "Suporte por email"]'),
  ('Pro', 'Para times em crescimento', 99.90, '["Projetos ilimitados", "20 usuários", "Suporte prioritário", "Relatórios avançados"]'),
  ('Enterprise', 'Para grandes organizações', 249.90, '["Projetos ilimitados", "Usuários ilimitados", "SLA dedicado", "Onboarding personalizado", "API access"]');
