-- 0028_fix_rls_gaps.sql
-- Corrige quatro lacunas de RLS identificadas:
-- 1. perfis: RLS habilitado (remote_schema) mas sem policies → tudo bloqueado
-- 2. papeis_usuario: RLS habilitado (remote_schema) mas sem SELECT/UPDATE/DELETE
-- 3. sub_tarefas: policies referenciam usuarios.perfil_id (removido em 0012) + falta INSERT/UPDATE/DELETE
-- 4. papeis_projeto: writes abertos para qualquer autenticado (tabela de catálogo global)
-- 5. handle_novo_usuario: suporte a proj_convite (movido do diff em 0020)

-- ============================================================
-- 1. perfis — tabela de catálogo; qualquer autenticado lê; só admin escreve
-- ============================================================
ALTER TABLE public.perfis ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "perfis_select"       ON public.perfis;
DROP POLICY IF EXISTS "perfis_admin_write"  ON public.perfis;

CREATE POLICY "perfis_select" ON public.perfis
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "perfis_admin_write" ON public.perfis
  FOR ALL TO authenticated
  USING     (meu_perfil() = 'admin')
  WITH CHECK (meu_perfil() = 'admin');

-- ============================================================
-- 2. papeis_usuario — usuário vê os próprios papéis + da mesma org
-- ============================================================
ALTER TABLE public.papeis_usuario ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "papeis_select"        ON public.papeis_usuario;
DROP POLICY IF EXISTS "papeis_update"        ON public.papeis_usuario;
DROP POLICY IF EXISTS "papeis_delete"        ON public.papeis_usuario;
-- INSERT policy "papeis_insert_proprio" (do 0004) mantida — self-only
DROP POLICY IF EXISTS "papeis_insert_proprio" ON public.papeis_usuario;

CREATE POLICY "papeis_select" ON public.papeis_usuario
  FOR SELECT TO authenticated
  USING (
    usuario_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = papeis_usuario.usuario_id
        AND u.organizacao_id = minha_organizacao_id()
    )
  );

CREATE POLICY "papeis_insert_proprio" ON public.papeis_usuario
  FOR INSERT TO authenticated
  WITH CHECK (usuario_id = auth.uid());

CREATE POLICY "papeis_update" ON public.papeis_usuario
  FOR UPDATE TO authenticated
  USING (usuario_id = auth.uid() OR meu_perfil() = 'admin');

CREATE POLICY "papeis_delete" ON public.papeis_usuario
  FOR DELETE TO authenticated
  USING (usuario_id = auth.uid() OR meu_perfil() = 'admin');

-- ============================================================
-- 3. sub_tarefas — substituir policies quebradas por tem_acesso_projeto()
-- ============================================================
ALTER TABLE public.sub_tarefas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Acesso total por perfil elevado"          ON public.sub_tarefas;
DROP POLICY IF EXISTS "Acesso restrito ao responsavel ou criador" ON public.sub_tarefas;
DROP POLICY IF EXISTS "sub_tarefas_select"                        ON public.sub_tarefas;
DROP POLICY IF EXISTS "sub_tarefas_insert"                        ON public.sub_tarefas;
DROP POLICY IF EXISTS "sub_tarefas_update"                        ON public.sub_tarefas;
DROP POLICY IF EXISTS "sub_tarefas_delete"                        ON public.sub_tarefas;

CREATE POLICY "sub_tarefas_select" ON public.sub_tarefas
  FOR SELECT TO authenticated
  USING (tem_acesso_projeto(projeto_id));

CREATE POLICY "sub_tarefas_insert" ON public.sub_tarefas
  FOR INSERT TO authenticated
  WITH CHECK (tem_acesso_projeto(projeto_id));

CREATE POLICY "sub_tarefas_update" ON public.sub_tarefas
  FOR UPDATE TO authenticated
  USING (tem_acesso_projeto(projeto_id));

CREATE POLICY "sub_tarefas_delete" ON public.sub_tarefas
  FOR DELETE TO authenticated
  USING (tem_acesso_projeto(projeto_id));

-- ============================================================
-- 4. papeis_projeto — catálogo de cargos; SELECT aberto; escrita só admin
-- ============================================================
DROP POLICY IF EXISTS "papeis_insert" ON public.papeis_projeto;
DROP POLICY IF EXISTS "papeis_update" ON public.papeis_projeto;
DROP POLICY IF EXISTS "papeis_delete" ON public.papeis_projeto;

CREATE POLICY "papeis_insert" ON public.papeis_projeto
  FOR INSERT TO authenticated
  WITH CHECK (meu_perfil() = 'admin');

CREATE POLICY "papeis_update" ON public.papeis_projeto
  FOR UPDATE TO authenticated
  USING     (meu_perfil() = 'admin')
  WITH CHECK (meu_perfil() = 'admin');

CREATE POLICY "papeis_delete" ON public.papeis_projeto
  FOR DELETE TO authenticated
  USING (meu_perfil() = 'admin');

-- ============================================================
-- 5. handle_novo_usuario — suporte a proj_convite e perfil_convite
--    (funcionalidade estava no diff de 0020; movida aqui via CREATE OR REPLACE)
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
    -- Usuário convidado — entra na org do admin
    INSERT INTO public.usuarios (id, nome, email, perfil, organizacao_id)
    VALUES (
      new.id,
      coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)),
      new.email,
      coalesce(perfil_convite, 'desenvolvedor')::public.papel_app,
      org_convite
    )
    ON CONFLICT (id) DO NOTHING;

    -- Se convite for para projeto específico, adiciona como membro
    IF proj_convite IS NOT NULL THEN
      INSERT INTO public.membros_projeto (projeto_id, usuario_id, papel)
      VALUES (proj_convite, new.id, coalesce(perfil_convite, 'desenvolvedor')::public.papel_app)
      ON CONFLICT (projeto_id, usuario_id) DO NOTHING;
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
