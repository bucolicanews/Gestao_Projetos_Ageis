-- 0049_simplify_perfil.sql
-- Simplify role system:
--   usuarios.perfil  → text CHECK IN ('admin','develop_admin','membro')
--   membros_projeto.papel → text (stores papeis_projeto.id UUID)
--   Drop orphan perfil_id column
--   Drop papel_app enum

-- 1. Drop unused column
ALTER TABLE public.usuarios DROP COLUMN IF EXISTS perfil_id;

-- 2. Unlock enum on both columns → cast to text
ALTER TABLE public.membros_projeto
  ALTER COLUMN papel TYPE text USING papel::text;

ALTER TABLE public.usuarios
  ALTER COLUMN perfil TYPE text USING perfil::text;

-- 3. Normalize old job-title values → 'membro'
UPDATE public.usuarios
  SET perfil = 'membro'
  WHERE perfil NOT IN ('admin', 'develop_admin');

-- 4. Constraint + default
ALTER TABLE public.usuarios
  ALTER COLUMN perfil SET DEFAULT 'membro',
  ADD CONSTRAINT usuarios_perfil_check
    CHECK (perfil IN ('admin', 'develop_admin', 'membro'));

-- 5. Drop old enum (CASCADE removes any remaining dependencies)
DROP TYPE IF EXISTS public.papel_app CASCADE;

-- 6. Rewrite trigger: clean separation of concerns
--    usuarios.perfil  → system access ('admin' | 'membro')
--    membros_projeto.papel → UUID from papeis_projeto (passed via invite metadata)
CREATE OR REPLACE FUNCTION public.handle_novo_usuario()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  nova_org_id    uuid;
  org_convite    uuid;
  proj_convite   uuid;
  papel_convite  text;   -- UUID from papeis_projeto
BEGIN
  org_convite   := (new.raw_user_meta_data->>'organizacao_id')::uuid;
  proj_convite  := (new.raw_user_meta_data->>'projeto_id')::uuid;
  papel_convite := new.raw_user_meta_data->>'perfil';  -- papeis_projeto UUID

  IF org_convite IS NOT NULL THEN
    -- Invited user — joins existing org, role is 'membro' at system level
    INSERT INTO public.usuarios (id, nome, email, perfil, organizacao_id)
    VALUES (
      new.id,
      coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)),
      new.email,
      'membro',
      org_convite
    )
    ON CONFLICT (id) DO NOTHING;

    IF proj_convite IS NOT NULL THEN
      INSERT INTO public.membros_projeto (projeto_id, usuario_id, papel)
      VALUES (proj_convite, new.id, papel_convite)
      ON CONFLICT (projeto_id, usuario_id) DO NOTHING;

      UPDATE public.convites_projeto
      SET usado_em = now()
      WHERE projeto_id = proj_convite
        AND email      = new.email
        AND usado_em   IS NULL;
    END IF;

  ELSE
    -- Self-signup — creates trial org, user becomes admin
    INSERT INTO public.organizacoes (nome, dono_id, status, vencimento)
    VALUES (
      coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)) || ' - Workspace',
      new.id,
      'trial',
      (now() + interval '14 days')::date
    )
    RETURNING id INTO nova_org_id;

    INSERT INTO public.usuarios (id, nome, email, perfil, organizacao_id)
    VALUES (
      new.id,
      coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)),
      new.email,
      'admin',
      nova_org_id
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;

  RETURN new;
END;
$$;
