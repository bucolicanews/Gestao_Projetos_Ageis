-- 0026_debug_auth.sql
-- RPC pública pra inspecionar auth.uid() na request atual.
-- Diagnóstico apenas. Remover quando bug isolado.

CREATE OR REPLACE FUNCTION public.debug_auth_uid()
RETURNS jsonb LANGUAGE sql STABLE AS $$
  SELECT jsonb_build_object(
    'uid', auth.uid(),
    'role', auth.role(),
    'jwt_claims', current_setting('request.jwt.claims', true)::jsonb
  )
$$;

GRANT EXECUTE ON FUNCTION public.debug_auth_uid() TO anon, authenticated;
