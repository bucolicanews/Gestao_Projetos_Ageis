-- 0042_permissoes_v2.sql
-- 1. usuarios_select: admin/gerente veem org completa; demais só sua equipe (projetos em comum)
-- 2. handle_novo_usuario: org criada com status='trial' para forçar seleção de plano
-- 3. usuarios_update: impede auto-promoção a develop_admin também

-- ============================================================
-- 1. usuarios_select
-- ============================================================
DROP POLICY IF EXISTS "usuarios_select" ON public.usuarios;

CREATE POLICY "usuarios_select" ON public.usuarios
  FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    OR (
      organizacao_id = minha_organizacao_id()
      AND (
        meu_perfil() IN ('admin', 'gerente_projeto')
        OR EXISTS (
          SELECT 1
          FROM public.membros_projeto mp1
          JOIN public.membros_projeto mp2 ON mp1.projeto_id = mp2.projeto_id
          WHERE mp1.usuario_id = auth.uid()
            AND mp2.usuario_id = usuarios.id
        )
      )
    )
  );

-- ============================================================
-- 2. usuarios_update: bloqueia auto-promoção a qualquer papel privilegiado
-- ============================================================
DROP POLICY IF EXISTS "usuarios_update" ON public.usuarios;

CREATE POLICY "usuarios_update" ON public.usuarios
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND perfil::text NOT IN ('admin', 'develop_admin')
  );

-- ============================================================
-- 3. handle_novo_usuario: cria org com status='trial'
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_novo_usuario()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    -- Auto-cadastro — cria org com status='trial' (exige seleção de plano)
    INSERT INTO public.organizacoes (nome, dono_id, status)
    VALUES (
      coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)) || ' - Workspace',
      new.id,
      'trial'
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
$function$;
