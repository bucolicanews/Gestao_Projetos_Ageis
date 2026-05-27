-- 0034_fix_org_fk_usuarios.sql
-- Adiciona FK de organizacoes.dono_id → public.usuarios(id)
-- Necessário para PostgREST conseguir fazer o join via API.
-- A FK original era para auth.users (schema diferente, não acessível pelo PostgREST).

ALTER TABLE public.organizacoes
  ADD CONSTRAINT organizacoes_dono_usuarios_fkey
  FOREIGN KEY (dono_id) REFERENCES public.usuarios(id)
  ON DELETE RESTRICT
  DEFERRABLE INITIALLY DEFERRED;
