-- ============================================================
-- 0010_corrigir_rls_usuarios.sql — Corrige política RLS da tabela usuarios
-- ============================================================

-- Primeiro verifica se a política existe, se não cria, se sim altera
DO $$
BEGIN
    -- Se a política já existe com a condição antiga, altera
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE policyname = 'usuarios_select_proprio' 
        AND tablename = 'usuarios'
    ) THEN
        alter policy "usuarios_select_proprio" on public.usuarios
          to authenticated
          using (true);
    ELSE
        -- Cria a política se não existir
        create policy "usuarios_select_proprio" on public.usuarios
          for select to authenticated
          using (true);
    END IF;
END $$;