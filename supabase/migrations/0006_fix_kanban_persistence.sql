-- Garante que membros do projeto podem atualizar suas tarefas (mover colunas)
-- 1. Função de log de movimento corrigida
CREATE OR REPLACE FUNCTION public.tocar_movimento_kanban()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.historico_movimentacao (
    tarefa_id,
    projeto_id,
    coluna_origem,
    coluna_destino,
    movido_por
  )
  VALUES (
    NEW.id,
    NEW.projeto_id,
    CASE WHEN TG_OP = 'UPDATE' THEN OLD.coluna ELSE NULL END,
    NEW.coluna,
    auth.uid()
  );
  RETURN NEW;
END;
$$;

-- 2. Trigger ajustado para AFTER (resolve a violação de FK)
DROP TRIGGER IF EXISTS trg_tarefas_movimento ON public.tarefas;
CREATE TRIGGER trg_tarefas_movimento
  AFTER INSERT OR UPDATE OF coluna ON public.tarefas
  FOR EACH ROW
  EXECUTE FUNCTION public.tocar_movimento_kanban();

-- 3. Políticas de RLS
DROP POLICY IF EXISTS "Membros podem atualizar tarefas do projeto" ON public.tarefas;
CREATE POLICY "Membros podem atualizar tarefas do projeto" 
ON public.tarefas
FOR UPDATE 
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.membros_projeto
    WHERE projeto_id = tarefas.projeto_id 
    AND usuario_id = auth.uid()
  )
);

-- Permissão para o histórico
ALTER TABLE public.historico_movimentacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Membros veem historico" ON public.historico_movimentacao
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Sistema insere historico" ON public.historico_movimentacao
  FOR INSERT TO authenticated WITH CHECK (true);

ALTER TABLE public.tarefas REPLICA IDENTITY FULL;
COMMIT;