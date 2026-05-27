-- 0046_trial_vencimento.sql
-- Define vencimento (criado_em + 14 dias) para orgs trial sem vencimento.
UPDATE public.organizacoes
  SET vencimento = (criado_em + interval '14 days')::date
  WHERE status = 'trial' AND vencimento IS NULL;

-- Atualiza trigger para setar vencimento em novos cadastros trial.
CREATE OR REPLACE FUNCTION public.handle_novo_usuario()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
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

    IF proj_convite IS NOT NULL THEN
      INSERT INTO public.membros_projeto (projeto_id, usuario_id, papel)
      VALUES (
        proj_convite,
        new.id,
        coalesce(perfil_convite, 'desenvolvedor')::public.papel_app
      )
      ON CONFLICT (projeto_id, usuario_id) DO NOTHING;

      UPDATE public.convites_projeto
      SET usado_em = now()
      WHERE projeto_id = proj_convite
        AND email      = new.email
        AND usado_em   IS NULL;
    END IF;

  ELSE
    -- Auto-cadastro — cria org trial com 14 dias de período gratuito
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
      'admin'::public.papel_app,
      nova_org_id
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;

  RETURN new;
END;
$$;
