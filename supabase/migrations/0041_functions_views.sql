-- 0041_functions_views.sql
-- Captura funções e views criadas via Dashboard que faltavam nas migrations.

create extension if not exists "pgjwt" with schema "extensions";

set check_function_bodies = off;

create or replace view "public"."config_gateways_publico" as  SELECT configuracoes_pagamentos.pagbank_enabled,
    configuracoes_pagamentos.pagbank_env,
    configuracoes_pagamentos.pagbank_pass_fees_to_customer,
    configuracoes_pagamentos.pagbank_pix_fee_fixed,
    configuracoes_pagamentos.pagbank_pix_fee_percentage,
    configuracoes_pagamentos.pagbank_card_fee_fixed,
    configuracoes_pagamentos.pagbank_card_fee_percentage,
    configuracoes_pagamentos.stripe_enabled,
    configuracoes_pagamentos.stripe_env,
    configuracoes_pagamentos.stripe_pass_fees_to_customer,
    configuracoes_pagamentos.stripe_fee_fixed,
    configuracoes_pagamentos.stripe_fee_percentage,
    configuracoes_pagamentos.pix_key,
    configuracoes_pagamentos.pix_name,
    configuracoes_pagamentos.pix_city
   FROM public.configuracoes_pagamentos;

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
$function$;

CREATE OR REPLACE FUNCTION public.is_develop_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT meu_perfil() = 'develop_admin'
$function$;

CREATE OR REPLACE FUNCTION public.planos_set_atualizado_em()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.atualizado_em = now();
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_org_convite()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.organizacao_id IS NULL THEN
    SELECT organizacao_id INTO NEW.organizacao_id
    FROM public.projetos WHERE id = NEW.projeto_id;
  END IF;
  RETURN NEW;
END;
$function$;

create or replace view "public"."v_metricas_tarefa" as  SELECT t.id,
    t.projeto_id,
    t.titulo,
    t.coluna,
    t.prioridade,
    t.responsavel_id,
    t.pontos,
    t.criado_em,
    t.concluido_em,
    t.entrou_coluna_em,
        CASE
            WHEN (t.concluido_em IS NOT NULL) THEN (EXTRACT(epoch FROM (t.concluido_em - t.criado_em)) / 3600.0)
            ELSE NULL::numeric
        END AS lead_time_horas,
        CASE
            WHEN (t.concluido_em IS NOT NULL) THEN ( SELECT (EXTRACT(epoch FROM (t.concluido_em - min(h.movido_em))) / 3600.0)
               FROM public.historico_movimentacao h
              WHERE ((h.tarefa_id = t.id) AND (h.coluna_destino = 'em_progresso'::public.coluna_kanban)))
            ELSE NULL::numeric
        END AS cycle_time_horas,
    (EXTRACT(epoch FROM (now() - t.entrou_coluna_em)) / 3600.0) AS idade_coluna_horas,
    ((t.prazo IS NOT NULL) AND (t.prazo < CURRENT_DATE) AND (t.coluna <> 'concluido'::public.coluna_kanban)) AS atrasada
   FROM public.tarefas t;

create or replace view "public"."v_velocity_projeto" as  SELECT vh.projeto_id,
    count(*) AS num_sprints,
    round(avg(vh.sp_concluidos), 1) AS velocity_media,
    round(avg(vh.sp_planejados), 1) AS planejados_media,
    max(vh.sp_concluidos) AS velocity_max,
    min(vh.sp_concluidos) AS velocity_min,
    sum(vh.sp_concluidos) AS sp_total,
    round(
        CASE
            WHEN (avg(vh.sp_planejados) > (0)::numeric) THEN ((100.0 * avg(vh.sp_concluidos)) / avg(vh.sp_planejados))
            ELSE NULL::numeric
        END, 1) AS taxa_conclusao_pct
   FROM public.velocity_historico vh
  WHERE (vh.sprint_id IN ( SELECT sprints.id
           FROM public.sprints
          ORDER BY sprints.criado_em DESC
         LIMIT 10))
  GROUP BY vh.projeto_id;
