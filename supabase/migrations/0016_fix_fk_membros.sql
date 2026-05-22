-- Fix FK on membros_projeto.usuario_id: auth.users → public.usuarios
-- Mirrors what 0012 did for tarefas.responsavel_id

BEGIN;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'membros_projeto_usuario_id_fkey'
    AND table_name = 'membros_projeto'
  ) THEN
    ALTER TABLE public.membros_projeto DROP CONSTRAINT membros_projeto_usuario_id_fkey;
  END IF;
END $$;

ALTER TABLE public.membros_projeto
ADD CONSTRAINT membros_projeto_usuario_id_fkey
FOREIGN KEY (usuario_id)
REFERENCES public.usuarios(id)
ON DELETE CASCADE;

COMMIT;
