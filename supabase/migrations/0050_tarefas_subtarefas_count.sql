-- 0050_tarefas_subtarefas_count.sql
-- Adiciona coluna persistida subtarefas_count em tarefas.
-- Substitui cálculo dinâmico via JOIN por valor mantido por trigger.

-- 1. Adiciona coluna
ALTER TABLE public.tarefas
  ADD COLUMN IF NOT EXISTS subtarefas_count integer NOT NULL DEFAULT 0;

-- 2. Backfill: conta filhos existentes para cada tarefa
UPDATE public.tarefas t
SET subtarefas_count = (
  SELECT COUNT(*)
  FROM public.tarefas filho
  WHERE filho.tarefa_pai_id = t.id
);

-- 3. Função de trigger: incrementa/decrementa o pai ao inserir, deletar ou mover subtarefa
CREATE OR REPLACE FUNCTION public.sincronizar_subtarefas_count()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.tarefa_pai_id IS NOT NULL THEN
      UPDATE public.tarefas
      SET subtarefas_count = subtarefas_count + 1
      WHERE id = NEW.tarefa_pai_id;
    END IF;
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.tarefa_pai_id IS NOT NULL THEN
      UPDATE public.tarefas
      SET subtarefas_count = GREATEST(0, subtarefas_count - 1)
      WHERE id = OLD.tarefa_pai_id;
    END IF;
    RETURN OLD;

  ELSIF TG_OP = 'UPDATE' THEN
    -- tarefa_pai_id mudou: decrementa pai antigo, incrementa pai novo
    IF OLD.tarefa_pai_id IS DISTINCT FROM NEW.tarefa_pai_id THEN
      IF OLD.tarefa_pai_id IS NOT NULL THEN
        UPDATE public.tarefas
        SET subtarefas_count = GREATEST(0, subtarefas_count - 1)
        WHERE id = OLD.tarefa_pai_id;
      END IF;
      IF NEW.tarefa_pai_id IS NOT NULL THEN
        UPDATE public.tarefas
        SET subtarefas_count = subtarefas_count + 1
        WHERE id = NEW.tarefa_pai_id;
      END IF;
    END IF;
    RETURN NEW;
  END IF;
END;
$$;

-- 4. Trigger na tabela tarefas
DROP TRIGGER IF EXISTS tarefas_sync_subtarefas_count ON public.tarefas;
CREATE TRIGGER tarefas_sync_subtarefas_count
  AFTER INSERT OR UPDATE OF tarefa_pai_id OR DELETE
  ON public.tarefas
  FOR EACH ROW EXECUTE FUNCTION public.sincronizar_subtarefas_count();
