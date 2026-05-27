-- 0045_planos_leitura_publica.sql
-- Permite visitantes não autenticados lerem planos ativos (página pública /planos).
DROP POLICY IF EXISTS "planos_anon_leem_ativos" ON public.planos;

CREATE POLICY "planos_anon_leem_ativos" ON public.planos
  FOR SELECT TO anon
  USING (ativo = true);
