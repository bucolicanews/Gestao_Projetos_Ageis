-- seed.sql — dados de exemplo (rodar após criar usuário no Auth)
-- Substitua os UUIDs pelos IDs reais dos seus usuários do Auth.

-- insert into public.projetos (id, nome, descricao, proprietario_id)
-- values ('11111111-1111-1111-1111-111111111111', 'Projeto Demo', 'Projeto de exemplo', '<UUID_USUARIO>');

-- insert into public.tarefas (projeto_id, titulo, descricao, prioridade, coluna, criado_por)
-- values
--  ('11111111-1111-1111-1111-111111111111', 'Configurar ambiente', 'Subir Supabase local', 'alta', 'a_fazer', '<UUID_USUARIO>'),
--  ('11111111-1111-1111-1111-111111111111', 'Implementar login', 'Tela de autenticação', 'alta', 'em_progresso', '<UUID_USUARIO>');
