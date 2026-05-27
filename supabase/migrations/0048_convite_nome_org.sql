-- 0048_convite_nome_org.sql
-- Adiciona nome do convidado e nome da organização ao convite
-- para exibir no cadastro sem precisar de acesso autenticado.
ALTER TABLE public.convites_projeto
  ADD COLUMN IF NOT EXISTS nome_convidado text,
  ADD COLUMN IF NOT EXISTS nome_org       text;
