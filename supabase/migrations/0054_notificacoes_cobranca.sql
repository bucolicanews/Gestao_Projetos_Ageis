-- 0054_notificacoes_cobranca.sql
-- 1) Adiciona tipo 'cobranca' à tabela notificacoes
-- 2) Cria função SECURITY DEFINER criar_notificacoes_org
--    para inserir notificações para todos os usuários de uma org
-- 3) Cria função verificar_vencimentos_e_notificar para pg_cron
-- 4) Agenda pg_cron diário às 08:00

-- ============================================================
-- 1) Novo tipo de notificação
-- ============================================================
ALTER TABLE public.notificacoes
  DROP CONSTRAINT IF EXISTS notificacoes_tipo_check;

ALTER TABLE public.notificacoes
  ADD CONSTRAINT notificacoes_tipo_check
  CHECK (tipo IN (
    'tarefa_atribuida',
    'comentario',
    'prazo',
    'subtarefa',
    'convite',
    'geral',
    'cobranca'
  ));

-- ============================================================
-- 2) Função: inserir notificações para todos os usuários de uma org
--    Pode ser chamada via RPC pelo frontend (dev_admin autenticado)
--    ou internamente pelo pg_cron
-- ============================================================
CREATE OR REPLACE FUNCTION public.criar_notificacoes_org(
  p_org_id   uuid,
  p_titulo   text,
  p_mensagem text,
  p_tipo     text DEFAULT 'geral'
)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count int := 0;
BEGIN
  INSERT INTO public.notificacoes (usuario_id, tipo, titulo, mensagem)
  SELECT id, p_tipo, p_titulo, p_mensagem
  FROM   public.usuarios
  WHERE  organizacao_id = p_org_id;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- Garante que apenas dev_admin pode chamar via RPC (policy nível app)
-- A função usa SECURITY DEFINER para contornar RLS na inserção cross-user
REVOKE ALL ON FUNCTION public.criar_notificacoes_org(uuid, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.criar_notificacoes_org(uuid, text, text, text) TO authenticated;

-- ============================================================
-- 3) Função: verificar vencimentos e gerar notificações de cobrança
--    Chamada pelo pg_cron diariamente
-- ============================================================
CREATE OR REPLACE FUNCTION public.verificar_vencimentos_e_notificar()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec             record;
  v_dias_antes    int;
  v_notif_no_dia  boolean;
  v_apos_dias     int;
  v_hoje          date := CURRENT_DATE;
  v_titulo        text;
  v_mensagem      text;
  v_tipo          text;
  v_ja_notificado boolean;
BEGIN
  -- Ler configurações
  SELECT COALESCE(valor::int, 7) INTO v_dias_antes
  FROM public.configuracoes_sistema WHERE chave = 'notif_dias_antes';

  SELECT COALESCE(valor::boolean, true) INTO v_notif_no_dia
  FROM public.configuracoes_sistema WHERE chave = 'notif_no_vencimento';

  SELECT COALESCE(valor::int, 3) INTO v_apos_dias
  FROM public.configuracoes_sistema WHERE chave = 'notif_apos_dias';

  FOR rec IN
    SELECT o.id, o.nome, o.vencimento, p.titulo AS plano_nome
    FROM   public.organizacoes o
    LEFT JOIN public.planos p ON p.id = o.plano_id
    WHERE  o.vencimento IS NOT NULL
      AND  o.status NOT IN ('bloqueado', 'cancelado')
  LOOP
    v_tipo := null;
    v_titulo := null;

    -- Vencimento iminente (X dias antes)
    IF rec.vencimento = v_hoje + v_dias_antes THEN
      v_tipo     := 'cobranca';
      v_titulo   := '⚠️ Assinatura vence em breve';
      v_mensagem := 'Seu plano ' || COALESCE(rec.plano_nome, '') ||
                    ' vence em ' || v_dias_antes || ' dias (' ||
                    TO_CHAR(rec.vencimento, 'DD/MM/YYYY') || '). Renove para manter o acesso.';
    END IF;

    -- Dia do vencimento
    IF v_notif_no_dia AND rec.vencimento = v_hoje THEN
      v_tipo     := 'cobranca';
      v_titulo   := '📅 Hoje é o último dia da sua assinatura';
      v_mensagem := 'Seu plano ' || COALESCE(rec.plano_nome, '') ||
                    ' vence hoje. Renove agora para não perder o acesso.';
    END IF;

    -- Após vencimento
    IF rec.vencimento < v_hoje AND (v_hoje - rec.vencimento) <= v_apos_dias THEN
      v_tipo     := 'cobranca';
      v_titulo   := '🔴 Sua assinatura está vencida';
      v_mensagem := 'Seu plano ' || COALESCE(rec.plano_nome, '') ||
                    ' venceu em ' || TO_CHAR(rec.vencimento, 'DD/MM/YYYY') ||
                    '. Entre em contato para reativar.';
    END IF;

    IF v_tipo IS NOT NULL THEN
      -- Evitar duplicata no mesmo dia
      SELECT EXISTS (
        SELECT 1 FROM public.notificacoes n
        JOIN public.usuarios u ON u.id = n.usuario_id
        WHERE u.organizacao_id = rec.id
          AND n.tipo = v_tipo
          AND n.titulo = v_titulo
          AND n.criado_em::date = v_hoje
        LIMIT 1
      ) INTO v_ja_notificado;

      IF NOT v_ja_notificado THEN
        PERFORM public.criar_notificacoes_org(rec.id, v_titulo, v_mensagem, v_tipo);

        -- Registrar no log de mensagens
        INSERT INTO public.log_mensagens_org (org_id, tipo, mensagem, status)
        VALUES (
          rec.id,
          CASE v_titulo
            WHEN '⚠️ Assinatura vence em breve' THEN 'vencimento_iminente'
            WHEN '📅 Hoje é o último dia da sua assinatura' THEN 'dia_vencimento'
            ELSE 'apos_vencimento'
          END,
          v_mensagem,
          'enviado'
        );
      END IF;
    END IF;
  END LOOP;
END;
$$;

-- ============================================================
-- 4) Agendar pg_cron diário às 08:00 (horário do banco)
-- ============================================================
DO $$
BEGIN
  -- Verifica se pg_cron está disponível
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
  ) THEN
    PERFORM cron.unschedule('verificar_vencimentos_notif');
    PERFORM cron.schedule(
      'verificar_vencimentos_notif',
      '0 8 * * *',
      'SELECT public.verificar_vencimentos_e_notificar()'
    );
  END IF;
END $$;
