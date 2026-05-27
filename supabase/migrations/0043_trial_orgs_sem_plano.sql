-- 0043_trial_orgs_sem_plano.sql
-- Orgs existentes sem plano_id ficam como trial (criadas antes do sistema de planos).
UPDATE public.organizacoes
  SET status = 'trial'
  WHERE plano_id IS NULL
    AND status = 'ativo';
