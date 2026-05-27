-- 0047_fix_usuarios_select_proprio.sql
-- PROBLEMA: "usuarios_select_proprio" com USING (true) permite qualquer
-- usuário autenticado ver todos os outros, anulando o isolamento por org.
-- A policy "usuarios_select" já cobre o caso "ver a si mesmo" via (id = auth.uid()).
DROP POLICY IF EXISTS "usuarios_select_proprio" ON public.usuarios;
