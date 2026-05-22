-- =========================================
-- Corrigir FK de tarefas.responsavel_id
-- auth.users  → public.usuarios
-- =========================================

BEGIN;

-- 🔹 Remove a constraint antiga (se existir)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_name = 'tarefas_responsavel_id_fkey'
      AND table_name = 'tarefas'
  ) THEN
    ALTER TABLE tarefas
    DROP CONSTRAINT tarefas_responsavel_id_fkey;
  END IF;
END $$;

-- 🔹 Cria a nova constraint apontando para public.usuarios
ALTER TABLE tarefas
ADD CONSTRAINT tarefas_responsavel_id_fkey
FOREIGN KEY (responsavel_id)
REFERENCES usuarios(id)
ON DELETE SET NULL;

COMMIT;