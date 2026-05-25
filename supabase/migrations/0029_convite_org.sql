-- 0029_convite_org.sql
-- Problema: cadastro.vue consulta projetos (RLS exige auth) para obter organizacao_id
--           do convite, mas o usuário ainda não está autenticado → retorna null →
--           trigger cria nova org em vez de entrar na org do admin.
-- Solução:  armazenar organizacao_id direto em convites_projeto; trigger preenche
--           automaticamente; frontend lê em uma query só (sem join em projetos).
-- Bônus:    handle_novo_usuario marca convite como usado_em = now().

-- ============================================================
-- 1. Coluna organizacao_id em convites_projeto
-- ============================================================
ALTER TABLE public.convites_projeto
  ADD COLUMN IF NOT EXISTS organizacao_id uuid
    REFERENCES public.organizacoes(id) ON DELETE CASCADE;

-- ============================================================
-- 2. Trigger: auto-preenche organizacao_id ao inserir convite
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_org_convite()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.organizacao_id IS NULL THEN
    SELECT organizacao_id INTO NEW.organizacao_id
    FROM public.projetos WHERE id = NEW.projeto_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_convites_set_org ON public.convites_projeto;
CREATE TRIGGER trg_convites_set_org
  BEFORE INSERT ON public.convites_projeto
  FOR EACH ROW EXECUTE FUNCTION public.set_org_convite();

-- Backfill convites existentes
UPDATE public.convites_projeto c
SET organizacao_id = (
  SELECT p.organizacao_id FROM public.projetos p WHERE p.id = c.projeto_id
)
WHERE c.organizacao_id IS NULL;

-- ============================================================
-- 3. handle_novo_usuario — marca convite como usado + usa papel do convite
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_novo_usuario()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  nova_org_id    uuid;
  org_convite    uuid;
  proj_convite   uuid;
  perfil_convite text;
BEGIN
  org_convite    := (new.raw_user_meta_data->>'organizacao_id')::uuid;
  proj_convite   := (new.raw_user_meta_data->>'projeto_id')::uuid;
  perfil_convite := new.raw_user_meta_data->>'perfil';

  IF org_convite IS NOT NULL THEN
    -- Usuário convidado — entra na org do admin, NÃO cria org nova
    INSERT INTO public.usuarios (id, nome, email, perfil, organizacao_id)
    VALUES (
      new.id,
      coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)),
      new.email,
      coalesce(perfil_convite, 'desenvolvedor')::public.papel_app,
      org_convite
    )
    ON CONFLICT (id) DO NOTHING;

    -- Adiciona como membro do projeto específico (se informado)
    IF proj_convite IS NOT NULL THEN
      INSERT INTO public.membros_projeto (projeto_id, usuario_id, papel)
      VALUES (
        proj_convite,
        new.id,
        coalesce(perfil_convite, 'desenvolvedor')::public.papel_app
      )
      ON CONFLICT (projeto_id, usuario_id) DO NOTHING;

      -- Marca convite como usado
      UPDATE public.convites_projeto
      SET usado_em = now()
      WHERE projeto_id = proj_convite
        AND email      = new.email
        AND usado_em   IS NULL;
    END IF;

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
