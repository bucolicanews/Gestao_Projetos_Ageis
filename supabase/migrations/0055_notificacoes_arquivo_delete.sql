-- 0055_notificacoes_arquivo_delete.sql
-- 1) Coluna arquivada para soft-hide de notificações
-- 2) Policy DELETE para o usuário excluir as próprias

ALTER TABLE public.notificacoes
  ADD COLUMN IF NOT EXISTS arquivada boolean NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_notificacoes_arquivada
  ON public.notificacoes(usuario_id, arquivada);

DROP POLICY IF EXISTS "notificacoes_delete" ON public.notificacoes;
CREATE POLICY "notificacoes_delete"
  ON public.notificacoes
  FOR DELETE
  TO authenticated
  USING (usuario_id = auth.uid());
