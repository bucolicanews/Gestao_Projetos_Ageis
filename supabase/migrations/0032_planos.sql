-- 0032_planos.sql
-- Módulo develop_admin — Fase 1: Planos SaaS
-- Depende de 0031_planos.sql (enum develop_admin já commitado)

-- ============================================================
-- 1. Atribuir develop_admin ao dono do sistema
-- ============================================================
UPDATE public.usuarios
  SET perfil = 'develop_admin'::public.papel_app
  WHERE email = 'bacudigital@gmail.com';

-- ============================================================
-- 2. Função auxiliar is_develop_admin()
-- ============================================================
CREATE OR REPLACE FUNCTION public.is_develop_admin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT meu_perfil() = 'develop_admin'
$$;

-- ============================================================
-- 3. Tabela planos
-- ============================================================
CREATE TABLE IF NOT EXISTS public.planos (
  id            uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo        text          NOT NULL,
  descricao     text,
  imagem_url    text,
  preco         numeric(10,2) NOT NULL DEFAULT 0,
  recursos      jsonb         NOT NULL DEFAULT '[]'::jsonb,
  ativo         boolean       NOT NULL DEFAULT true,
  criado_em     timestamptz   NOT NULL DEFAULT now(),
  atualizado_em timestamptz   NOT NULL DEFAULT now()
);

-- Trigger atualiza atualizado_em
CREATE OR REPLACE FUNCTION public.planos_set_atualizado_em()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.atualizado_em = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_planos_atualizado_em ON public.planos;
CREATE TRIGGER trg_planos_atualizado_em
  BEFORE UPDATE ON public.planos
  FOR EACH ROW EXECUTE FUNCTION public.planos_set_atualizado_em();

-- ============================================================
-- 4. RLS — planos
-- ============================================================
ALTER TABLE public.planos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "planos_develop_admin_all"    ON public.planos;
DROP POLICY IF EXISTS "planos_usuarios_leem_ativos" ON public.planos;

CREATE POLICY "planos_develop_admin_all" ON public.planos
  FOR ALL TO authenticated
  USING (is_develop_admin())
  WITH CHECK (is_develop_admin());

CREATE POLICY "planos_usuarios_leem_ativos" ON public.planos
  FOR SELECT TO authenticated
  USING (ativo = true);

-- ============================================================
-- 5. FK plano_id em organizacoes
-- ============================================================
ALTER TABLE public.organizacoes
  ADD COLUMN IF NOT EXISTS plano_id uuid REFERENCES public.planos(id) ON DELETE SET NULL;

-- ============================================================
-- 6. RLS organizacoes — develop_admin vê e edita todas
-- ============================================================
DROP POLICY IF EXISTS "org_develop_admin_all" ON public.organizacoes;

CREATE POLICY "org_develop_admin_all" ON public.organizacoes
  FOR ALL TO authenticated
  USING (is_develop_admin())
  WITH CHECK (is_develop_admin());

-- ============================================================
-- 7. RLS usuarios — develop_admin vê todos
-- ============================================================
DROP POLICY IF EXISTS "usuarios_develop_admin_select" ON public.usuarios;

CREATE POLICY "usuarios_develop_admin_select" ON public.usuarios
  FOR SELECT TO authenticated
  USING (is_develop_admin());

-- ============================================================
-- 8. Dados iniciais — planos
-- ============================================================
INSERT INTO public.planos (titulo, descricao, preco, recursos) VALUES
  (
    'Starter',
    'Ideal para times pequenos',
    49.90,
    '["Até 3 projetos", "5 usuários", "Kanban e Backlog", "Suporte por email"]'::jsonb
  ),
  (
    'Pro',
    'Para times em crescimento',
    99.90,
    '["Projetos ilimitados", "20 usuários", "Sprints e métricas", "Suporte prioritário", "Relatórios avançados"]'::jsonb
  ),
  (
    'Enterprise',
    'Para grandes organizações',
    249.90,
    '["Projetos ilimitados", "Usuários ilimitados", "SLA dedicado", "Onboarding personalizado", "API access", "Relatórios customizados"]'::jsonb
  )
ON CONFLICT DO NOTHING;
