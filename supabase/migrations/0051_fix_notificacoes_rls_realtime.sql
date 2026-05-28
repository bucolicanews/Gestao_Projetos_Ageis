-- 0051_fix_notificacoes_rls_realtime.sql
-- Recria policies da tabela notificacoes com sintaxe correta
-- e habilita broadcasting Realtime

-- Remove policies antigas (podem estar com sintaxe quebrada)
DROP POLICY IF EXISTS "usuario_ve_proprias_notificacoes"   ON public.notificacoes;
DROP POLICY IF EXISTS "usuario_atualiza_proprias_notificacoes" ON public.notificacoes;
DROP POLICY IF EXISTS "autenticado_cria_notificacao"       ON public.notificacoes;
DROP POLICY IF EXISTS "notificacoes_select"                ON public.notificacoes;
DROP POLICY IF EXISTS "notificacoes_insert"                ON public.notificacoes;
DROP POLICY IF EXISTS "notificacoes_update"                ON public.notificacoes;

-- Garante RLS ativo
ALTER TABLE public.notificacoes ENABLE ROW LEVEL SECURITY;

-- SELECT: usuário lê apenas as próprias notificações
CREATE POLICY "notificacoes_select"
  ON public.notificacoes
  FOR SELECT
  TO authenticated
  USING (usuario_id = auth.uid());

-- INSERT: qualquer autenticado pode criar notificações
--         (necessário para notificar outros usuários, ex: tarefa atribuída)
CREATE POLICY "notificacoes_insert"
  ON public.notificacoes
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

-- UPDATE: usuário atualiza apenas as próprias (marcar como lida)
CREATE POLICY "notificacoes_update"
  ON public.notificacoes
  FOR UPDATE
  TO authenticated
  USING  (usuario_id = auth.uid())
  WITH CHECK (usuario_id = auth.uid());

-- Habilita Realtime broadcasting na tabela
ALTER PUBLICATION supabase_realtime ADD TABLE public.notificacoes;
