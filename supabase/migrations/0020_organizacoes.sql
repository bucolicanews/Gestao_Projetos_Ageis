-- 0020_organizacoes.sql
-- Multi-tenant: cada administrador tem sua própria organização isolada.
-- Quem se cadastra vira admin da própria org.
-- Admins NÃO podem criar outros admins.

-- ============================================================
-- 1. Tabela organizacoes
-- ============================================================
CREATE TABLE IF NOT EXISTS public.organizacoes (
  id        uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  nome      text        NOT NULL,
  plano     text        NOT NULL DEFAULT 'gratuito', -- gratuito | basico | pro
  ativo     boolean     NOT NULL DEFAULT true,
  dono_id   uuid        NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  criado_em timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.organizacoes ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 2. Colunas organizacao_id
-- ============================================================
ALTER TABLE public.usuarios
  ADD COLUMN IF NOT EXISTS organizacao_id uuid REFERENCES public.organizacoes(id) ON DELETE SET NULL;

ALTER TABLE public.projetos
  ADD COLUMN IF NOT EXISTS organizacao_id uuid REFERENCES public.organizacoes(id) ON DELETE CASCADE;

-- ============================================================
-- 3. Função auxiliar — evita RLS recursivo em usuarios
-- ============================================================
CREATE OR REPLACE FUNCTION public.minha_organizacao_id()
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT organizacao_id FROM public.usuarios WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.meu_perfil()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT perfil::text FROM public.usuarios WHERE id = auth.uid()
$$;

-- ============================================================
-- 4. RLS organizacoes
-- ============================================================
DROP POLICY IF EXISTS "org_select"  ON public.organizacoes;
DROP POLICY IF EXISTS "org_update"  ON public.organizacoes;

-- Usuário vê apenas a própria org
CREATE POLICY "org_select" ON public.organizacoes
  FOR SELECT TO authenticated
  USING (id = minha_organizacao_id());

-- Apenas o dono atualiza nome/plano
CREATE POLICY "org_update" ON public.organizacoes
  FOR UPDATE TO authenticated
  USING  (dono_id = auth.uid())
  WITH CHECK (dono_id = auth.uid());

-- ============================================================
-- 5. Migrar dados existentes: criar org para cada usuário sem org
-- ============================================================
DO $$
DECLARE
  u      RECORD;
  org_id uuid;
BEGIN
  FOR u IN SELECT id, nome FROM public.usuarios WHERE organizacao_id IS NULL LOOP
    INSERT INTO public.organizacoes (nome, dono_id)
    VALUES (u.nome || ' - Workspace', u.id)
    RETURNING id INTO org_id;

    UPDATE public.usuarios
      SET organizacao_id = org_id,
          perfil = 'admin'::public.papel_app
      WHERE id = u.id;

    -- Projetos onde esse usuário é proprietário
    UPDATE public.projetos
      SET organizacao_id = org_id
      WHERE proprietario_id = u.id AND organizacao_id IS NULL;
  END LOOP;
END $$;

-- ============================================================
-- 6. Trigger: projetos herdam org do criador automaticamente
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_org_projeto()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.organizacao_id IS NULL THEN
    SELECT organizacao_id INTO NEW.organizacao_id
    FROM public.usuarios WHERE id = auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_projetos_set_org ON public.projetos;
CREATE TRIGGER trg_projetos_set_org
  BEFORE INSERT ON public.projetos
  FOR EACH ROW EXECUTE FUNCTION public.set_org_projeto();

-- ============================================================
-- 7. Atualizar trigger de novo usuário (multi-tenant)
--    - Auto-cadastro  → nova org + perfil = 'admin'
--    - Via convite    → entra na org existente + perfil = 'desenvolvedor'
--      (convite passa organizacao_id em raw_user_meta_data)
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_novo_usuario()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  nova_org_id uuid;
  org_convite  uuid;
BEGIN
  org_convite := (new.raw_user_meta_data->>'organizacao_id')::uuid;

  IF org_convite IS NOT NULL THEN
    -- Usuário convidado — entra na org do admin que convidou
    INSERT INTO public.usuarios (id, nome, email, perfil, organizacao_id)
    VALUES (
      new.id,
      coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)),
      new.email,
      'desenvolvedor'::public.papel_app,
      org_convite
    )
    ON CONFLICT (id) DO NOTHING;

  ELSE
    -- Auto-cadastro — cria nova org, usuário vira admin
    INSERT INTO public.organizacoes (nome, dono_id)
    VALUES (
      coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)) || ' - Workspace',
      new.id
    )
    RETURNING id INTO nova_org_id;

    INSERT INTO public.usuarios (id, nome, email, perfil, organizacao_id)
    VALUES (
      new.id,
      coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)),
      new.email,
      'admin'::public.papel_app,
      nova_org_id
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;

  RETURN new;
END;
$$;

-- ============================================================
-- 8. RLS projetos — isolamento por org
-- ============================================================
ALTER TABLE public.projetos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "proj_select" ON public.projetos;
DROP POLICY IF EXISTS "proj_insert" ON public.projetos;
DROP POLICY IF EXISTS "proj_update" ON public.projetos;
DROP POLICY IF EXISTS "proj_delete" ON public.projetos;
-- nomes antigos que possam existir:
DROP POLICY IF EXISTS "projetos_select"              ON public.projetos;
DROP POLICY IF EXISTS "projetos_insert"              ON public.projetos;
DROP POLICY IF EXISTS "projetos_update"              ON public.projetos;
DROP POLICY IF EXISTS "projetos_delete"              ON public.projetos;
DROP POLICY IF EXISTS "projetos_leitura_membro"      ON public.projetos;
DROP POLICY IF EXISTS "projetos_escrita_proprietario" ON public.projetos;

CREATE POLICY "proj_select" ON public.projetos
  FOR SELECT TO authenticated
  USING (
    organizacao_id = minha_organizacao_id()
    OR proprietario_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.membros_projeto
      WHERE projeto_id = projetos.id AND usuario_id = auth.uid()
    )
  );

CREATE POLICY "proj_insert" ON public.projetos
  FOR INSERT TO authenticated
  WITH CHECK (proprietario_id = auth.uid());

CREATE POLICY "proj_update" ON public.projetos
  FOR UPDATE TO authenticated
  USING (
    proprietario_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.membros_projeto
      WHERE projeto_id = projetos.id
        AND usuario_id = auth.uid()
        AND papel IN ('admin', 'desenvolvedor')
    )
  );

CREATE POLICY "proj_delete" ON public.projetos
  FOR DELETE TO authenticated
  USING (proprietario_id = auth.uid());

-- ============================================================
-- 9. RLS usuarios — só vê usuários da mesma org
-- ============================================================
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "usuarios_select"          ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_update"          ON public.usuarios;
DROP POLICY IF EXISTS "autenticados_veem_usuarios" ON public.usuarios;

CREATE POLICY "usuarios_select" ON public.usuarios
  FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    OR organizacao_id = minha_organizacao_id()
  );

CREATE POLICY "usuarios_update" ON public.usuarios
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    -- impede auto-promoção a admin
    AND perfil::text <> 'admin'
  );
