-- 0025_trigger_proprietario_projeto.sql
-- Garante proprietario_id é preenchido com auth.uid() automaticamente.
-- Evita dependência de o client enviar o ID correto e mata classe inteira
-- de erros "new row violates row-level security policy" causados por
-- proprietario_id ausente/divergente no payload.

CREATE OR REPLACE FUNCTION public.set_proprietario_projeto()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.proprietario_id IS NULL THEN
    NEW.proprietario_id := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_proprietario ON public.projetos;
CREATE TRIGGER trg_set_proprietario
  BEFORE INSERT ON public.projetos
  FOR EACH ROW EXECUTE FUNCTION public.set_proprietario_projeto();
