-- 0030_permissoes_papel.sql
-- Adiciona coluna permissoes (text[]) em papeis_projeto para armazenar
-- as permissões funcionais de cada papel. UI de edição usa esta coluna.

ALTER TABLE public.papeis_projeto
  ADD COLUMN IF NOT EXISTS permissoes text[] NOT NULL DEFAULT '{}';

-- Seed: permissões padrão para cada papel pré-cadastrado
UPDATE public.papeis_projeto SET permissoes = ARRAY[
  'criar_projeto','editar_projeto','excluir_projeto',
  'criar_tarefa','editar_tarefa','excluir_tarefa','comentar',
  'convidar_usuario','gerenciar_usuarios','promover_admin',
  'gerenciar_sprint','aprovar_demanda',
  'ver_relatorios','ver_logs',
  'configuracoes_globais','acessar_faturamento','excluir_organizacao'
] WHERE nome = 'Administrador';

UPDATE public.papeis_projeto SET permissoes = ARRAY[
  'criar_projeto','editar_projeto',
  'criar_tarefa','editar_tarefa','comentar',
  'convidar_usuario','gerenciar_usuarios',
  'gerenciar_sprint','aprovar_demanda',
  'ver_relatorios'
] WHERE nome = 'Gerente de Projeto';

UPDATE public.papeis_projeto SET permissoes = ARRAY[
  'criar_tarefa','editar_tarefa','comentar',
  'gerenciar_sprint','aprovar_demanda',
  'ver_relatorios'
] WHERE nome = 'Product Owner';

UPDATE public.papeis_projeto SET permissoes = ARRAY[
  'criar_tarefa','editar_tarefa','comentar',
  'gerenciar_sprint',
  'ver_relatorios'
] WHERE nome = 'Scrum Master';

UPDATE public.papeis_projeto SET permissoes = ARRAY[
  'criar_tarefa','comentar',
  'ver_relatorios'
] WHERE nome = 'Analista';

UPDATE public.papeis_projeto SET permissoes = ARRAY[
  'criar_tarefa','editar_tarefa','comentar',
  'ver_relatorios'
] WHERE nome IN ('Desenvolvedor','Dev Backend','Dev Frontend','Dev Mobile');

UPDATE public.papeis_projeto SET permissoes = ARRAY[
  'criar_tarefa','editar_tarefa','comentar',
  'ver_relatorios','ver_logs',
  'configuracoes_globais'
] WHERE nome = 'DevOps';

UPDATE public.papeis_projeto SET permissoes = ARRAY[
  'criar_tarefa','editar_tarefa','comentar'
] WHERE nome = 'Designer UX/UI';

UPDATE public.papeis_projeto SET permissoes = ARRAY[
  'criar_tarefa','editar_tarefa','comentar',
  'aprovar_demanda','ver_relatorios'
] WHERE nome = 'QA / Testes';

UPDATE public.papeis_projeto SET permissoes = ARRAY[]::text[]
  WHERE nome = 'Visualizador';
