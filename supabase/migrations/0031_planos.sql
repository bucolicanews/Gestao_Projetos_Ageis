-- 0031_planos.sql
-- APENAS adiciona o valor develop_admin ao enum papel_app.
-- Deve ficar em migration separada: PostgreSQL não permite usar
-- um novo valor de enum na mesma transação em que ele foi criado.
ALTER TYPE public.papel_app ADD VALUE 'develop_admin';


